import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:hermez_sdk/api.dart' as api;
import 'package:hermez_sdk/utils.dart';
import 'package:web3dart/crypto.dart';

import 'addresses.dart'
    show
        getAccountIndex,
        getEthereumAddress,
        isHermezAccountIndex,
        isHermezEthereumAddress,
        isHermezBjjAddress;
import 'environment.dart';
import 'fee_factors.dart' show feeFactors, feeFactorsAsBigInts;
import 'hermez_compressed_amount.dart';
import 'libs/circomlib.dart';
import 'model/token.dart';
import 'tx_pool.dart' show getPoolTransactions;

const String hermezPrefix = "hez:";

const Map<String, String> txType = {
  "Deposit": "Deposit",
  "CreateAccountDeposit": "CreateAccountDeposit",
  "Transfer": "Transfer",
  "Withdraw": "Withdrawn",
  "Exit": "Exit"
};

enum TxType { Deposit, CreateAccountDeposit, Transfer, Withdraw, Exit }

const Map<String, String> txState = {
  "Forged": "fged",
  "Forging": "fing",
  "Pending": "pend",
  "Invalid": "invl"
};

final DynamicLibrary nativeExampleLib = Platform.isAndroid
    ? DynamicLibrary.open("libbabyjubjub.so")
    : DynamicLibrary.process();

// 60 bits is the minimum bits to achieve enough precision among fee factor values < 192
// no shift value is applied for fee factor values >= 192
const bitsShiftPrecision = 60;

//final circomlib = CircomLib(lib: await SetupUtil.getDylibAsync());

/// Encodes the transaction object to be in a format supported by the Smart Contracts and Circuits.
/// Used, for example, to sign the transaction
///
/// @param {Object} transaction - Transaction object returned by generateL2Transaction
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
///
/// @returns {Object} encodedTransaction
Map<String, dynamic> encodeTransaction(Map<String, dynamic> transaction,
    {String providerUrl}) {
  final Map<String, dynamic> encodedTransaction = Map.from(transaction);

  encodedTransaction["chainId"] = getCurrentEnvironment().chainId;

  encodedTransaction["fromAccountIndex"] =
      getAccountIndex(transaction["fromAccountIndex"]);
  if (transaction["toAccountIndex"] != null) {
    encodedTransaction["toAccountIndex"] =
        getAccountIndex(transaction["toAccountIndex"]);
  } else if (transaction["type"] == 'Exit') {
    encodedTransaction["toAccountIndex"] = 1;
  }

  if (transaction["toHezEthereumAddress"] != null) {
    encodedTransaction["toEthereumAddress"] =
        getEthereumAddress(transaction["toHezEthereumAddress"]);
  }

  return encodedTransaction;
}

/// Generates the L1 Transaction Id based on the spec
/// TxID (32 bytes) for L1Tx is the Keccak256 (ethereum) hash of:
/// bytes:   | 1 byte |             32 bytes                |
///                     SHA256(    8 bytes      |  2 bytes )
/// content: |  type  | SHA256([ToForgeL1TxsNum | Position ])
/// where type for L1UserTx is 0
/// @param {Number} toForgeL1TxsNum
/// @param {Number} currentPosition
///
/// @returns {String}
String getL1UserTxId(BigInt toForgeL1TxsNum, BigInt currentPosition) {
  final toForgeL1TxsNumBytes = Uint8List(8);
  final toForgeL1TxsNumView = ByteData.view(toForgeL1TxsNumBytes.buffer);
  toForgeL1TxsNumView.setUint64(0, toForgeL1TxsNum.toInt());

  final positionBytes = Uint8List(8);
  final positionView = ByteData.view(positionBytes.buffer);
  positionView.setUint64(0, currentPosition.toInt());

  final toForgeL1TxsNumHex =
      bytesToHex(toForgeL1TxsNumView.buffer.asUint8List());
  final positionHex =
      bytesToHex(positionView.buffer.asUint8List().sublist(6, 8));

  final v = toForgeL1TxsNumHex + positionHex;
  final h = bytesToHex(keccak256(hexToBytes(v)));

  return '0x00' + h;
}

/// Generates the Transaction Id based on the spec
/// TxID (33 bytes) for L2Tx is:
/// bytes:   | 1 byte |                    32 bytes                           |
///                     SHA256( 6 bytes | 4 bytes | 2 bytes| 5 bytes | 1 byte )
/// content: |  type  | SHA256([FromIdx | TokenID | Amount |  Nonce  | Fee    ])
/// where type for L2Tx is '2'
/// @param {Number} fromIdx - The account index that sends the transaction
/// @param {Number} tokenId - The tokenId being transacted
/// @param {Number} amount - The amount being transacted
/// @param {Number} nonce - Nonce of the transaction
/// @param {Number} fee - The fee of the transaction
/// @returns {String} Transaction Id
String getL2TxId(int fromIdx, int tokenId, double amount, int nonce, int fee) {
  final fromIdxBytes = Uint8List(8);
  final fromIdxView = ByteData.view(fromIdxBytes.buffer);
  fromIdxView.setUint64(0, fromIdx);

  final tokenIdBytes = Uint8List(8);
  final tokenIdView = ByteData.view(tokenIdBytes.buffer);
  tokenIdView.setUint64(0, tokenId);

  final amountF40 = HermezCompressedAmount.compressAmount(amount).value;
  final amountBytes = Uint8List(8);
  final amountView = ByteData.view(amountBytes.buffer);
  amountView.setUint64(0, BigInt.from(amountF40).toInt());

  final nonceBytes = Uint8List(8);
  final nonceView = ByteData.view(nonceBytes.buffer);
  nonceView.setUint64(0, nonce);

  final fromIdxHex = bytesToHex(fromIdxView.buffer.asUint8List().sublist(2, 8));
  final tokenIdHex = bytesToHex(tokenIdView.buffer.asUint8List().sublist(4, 8));
  final amountHex = bytesToHex(
      amountView.buffer.asUint8List().sublist(3, 8)); // float40: 5 bytes
  final nonceHex = bytesToHex(nonceView.buffer.asUint8List().sublist(3, 8));

  String feeHex = fee.toRadixString(16);
  if (feeHex.length == 1) {
    feeHex = '0' + feeHex;
  }

  final v = fromIdxHex + tokenIdHex + amountHex + nonceHex + feeHex;
  final h = bytesToHex(keccak256(hexToBytes(v)));

  return '0x02' + h;
}

/// Calculates the appropriate fee factor depending on what's the fee as a percentage of the amount
///
/// @param {Number} fee - The fee in token value
/// @param {BigInt} amount - The amount as a BigInt string
///
/// @return {Number} feeFactor
int getFeeIndex(num fee, num amount) {
  num low = 0;
  int mid;
  int high = feeFactors.length - 1;
  while (high - low > 1) {
    mid = ((low + high) / 2).floor();
    if (getFeeValue(mid, amount).toDouble() < fee) {
      low = mid;
    } else {
      high = mid;
    }
  }

  return high;
}

/// Compute fee in token value with an amount and a fee index
/// @param {Number} feeIndex - Fee selected among 0 - 255
/// @param {Number} amount - The amount of the transaction as a Scalar
/// @returns {BigInt} Resulting fee in token value
BigInt getFeeValue(num feeIndex, num amount) {
  if (feeIndex < 192) {
    final fee = BigInt.from(amount * feeFactorsAsBigInts[feeIndex]);
    return fee >> bitsShiftPrecision;
  } else {
    return BigInt.from(amount * feeFactorsAsBigInts[feeIndex]);
  }
}

/// Gets the transaction type depending on the information in the transaction object
/// If an account index is used, it will be 'Transfer'
/// If a Hermez address is used, it will be 'TransferToEthAddr'
/// If a BabyJubJub is used, it will be 'TransferToBjj'
///
/// @param {Object} transaction - Transaction object sent to generateL2Transaction
///
/// @return {String} transactionType
String getTransactionType(Map transaction) {
  if (transaction["to"] != null) {
    if (isHermezAccountIndex(transaction['to'])) {
      return 'Transfer';
    } else if (isHermezEthereumAddress(transaction['to'])) {
      return 'TransferToEthAddr';
    } else if (isHermezBjjAddress(transaction['to'])) {
      return 'TransferToBJJ';
    }
  } else {
    return 'Exit';
  }
}

/// Calculates the appropriate nonce based on the current token account nonce and existing transactions in the Pool.
/// It needs to find the lowest nonce available as transactions in the pool may fail and the Coordinator only forges
/// transactions in the order set by nonces.
///
/// @param {Number} currentNonce - The current token account nonce returned by the Coordinator (optional)
/// @param {String} accountIndex - The account index
/// @param {String} bjj - The account's BabyJubJub
/// @param {Number} tokenId - The token id of the token in the transaction
///
/// @return {Number} nonce
Future<num> getNonce(
    num currentNonce, String accountIndex, String bjj, num tokenId) async {
  if (currentNonce != null) {
    return currentNonce;
  }

  final accountData = await api.getAccount(accountIndex);
  var nonce = accountData.nonce;

  final List<dynamic> poolTxs = await getPoolTransactions(accountIndex, bjj);

  poolTxs.removeWhere((tx) => tx.token.id == tokenId);
  final List poolTxsNonces =
      poolTxs.where((tx) => tx.nonce).toList(); //map((tx) => tx.nonce);
  poolTxs.sort();

  // return current nonce if no transactions are pending
  if (poolTxsNonces.length > 0) {
    while (poolTxsNonces.indexOf(nonce) != -1) {
      nonce++;
    }
  }

  return nonce;
}

/// Encode tx compressed data
/// @param {Object} tx - Transaction object
/// @returns {BigInt} Encoded tx compressed data
BigInt buildTxCompressedData(Map<String, dynamic> tx) {
  final signatureConstant = BigInt.parse('3322668559');
  BigInt res = BigInt.zero;
  final chainId =
      BigInt.from((tx['chainId'] != null ? tx['chainId'] : 0)) << 32;
  final fromAccountIndex = BigInt.from(
          (tx['fromAccountIndex'] != null ? tx['fromAccountIndex'] : 0)) <<
      48;
  final toAccountIndex =
      BigInt.from((tx['toAccountIndex'] != null ? tx['toAccountIndex'] : 0)) <<
          96;
  final tokenId =
      BigInt.from((tx['tokenId'] != null ? tx['tokenId'] : 0)) << 144;
  final nonce = BigInt.from((tx['nonce'] != null ? tx['nonce'] : 0)) << 176;
  final fee = BigInt.from((tx['fee'] != null ? tx['fee'] : 0)) << 216;
  final toBjjSign = BigInt.from((tx['toBjjSign'] != null ? 1 : 0)) << 224;

  res = res + signatureConstant; // SignConst --> 32 bits -> 4 bytes
  res = res + chainId; // chainId --> 16 bits
  res = res + fromAccountIndex; // fromIdx --> 48 bits
  res = res + toAccountIndex; // toIdx --> 48 bits
  res = res + tokenId; // tokenID --> 32 bits
  res = res + nonce; // nonce --> 40 bits
  res = res + fee; // userFee --> 8 bits
  res = res + toBjjSign; // toBjjSign --> 1 bit

  return res;
}

/// Build element_1 for L2HashSignature
/// @param {Object} tx - Transaction object returned by `encodeTransaction`
/// @returns {BigInt} element_1 L2 signature
BigInt buildElement1(Map<String, dynamic> tx) {
  BigInt res = BigInt.zero;

  final toEthereumAddress = BigInt.parse(
      tx['toEthereumAddress'] != null
          ? tx['toEthereumAddress'].substring(2)
          : '0',
      radix: 16);
  double amount = tx['amount'] != null ? double.parse(tx['amount']) : 0;
  final amountF = BigInt.from(
          HermezCompressedAmount.compressAmount(amount).value.toInt()) <<
      160;
  final maxNumBatch =
      BigInt.from(tx['maxNumBatch'] != null ? tx['maxNumBatch'] : 0) << 200;

  res = res + toEthereumAddress; // ethAddr --> 160 bits
  res = res + amountF; // amountF --> 40 bits
  res = res + maxNumBatch; // maxNumBatch --> 32 bits

  return res;
}

/// Builds the message to hash
///
/// @param {Object} encodedTransaction - Transaction object
///
/// @returns {BigInt} message to sign
BigInt buildTransactionHashMessage(Map<String, dynamic> encodedTransaction) {
  final BigInt txCompressedData = buildTxCompressedData(encodedTransaction);
  final element1 = buildElement1(encodedTransaction);
  final toBjjAy = encodedTransaction['toBjjAy'] != null
      ? (encodedTransaction['toBjjAy'].startsWith('0x')
          ? encodedTransaction['toBjjAy'].substring(2)
          : encodedTransaction['toBjjAy'])
      : '0';
  final rqTxCompressedDataV2 =
      encodedTransaction['rqTxCompressedDataV2'] != null
          ? (encodedTransaction['rqTxCompressedDataV2'].startsWith('0x')
              ? encodedTransaction['rqTxCompressedDataV2'].substring(2)
              : encodedTransaction['rqTxCompressedDataV2'])
          : '0';
  final rqToEthAddr = encodedTransaction['rqToEthAddr'] != null
      ? (encodedTransaction['rqToEthAddr'].startsWith('0x')
          ? encodedTransaction['rqToEthAddr'].substring(2)
          : encodedTransaction['rqToEthAddr'])
      : '0';

  final rqToBjjAy = encodedTransaction['rqToBjjAy'] != null
      ? (encodedTransaction['rqToBjjAy'].startsWith('0x')
          ? encodedTransaction['rqToBjjAy'].substring(2)
          : encodedTransaction['rqToBjjAy'])
      : '0';

  CircomLib circomLib = CircomLib();
  String hashPoseidon = circomLib.hashPoseidon(
      txCompressedData.toString(),
      element1.toString(),
      toBjjAy,
      rqTxCompressedDataV2,
      rqToEthAddr,
      rqToBjjAy);
  BigInt h = hexToInt(hashPoseidon);
  return h;
}

/// Prepares a transaction to be ready to be sent to a Coordinator.
///
/// @param {Object} transaction - ethAddress and babyPubKey together
/// @param {String} transaction.from - The account index that's sending the transaction e.g hez:DAI:4444
/// @param {String} transaction.to - The account index of the receiver e.g hez:DAI:2156. If it's an Exit, set to a falseable value
/// @param {String} transaction.amount - The amount being sent as a BigInt string
/// @param {Number} transaction.fee - The amount of tokens to be sent as a fee to the Coordinator
/// @param {Number} transaction.nonce - The current nonce of the sender's token account
/// @param {String} bJJ - The compressed BabyJubJub in hexadecimal format of the transaction sender
/// @param {Object} token - The token information object as returned from the Coordinator.
///
/// @return {Object} - Contains `transaction` and `encodedTransaction`. `transaction` is the object almost ready to be sent to the Coordinator. `encodedTransaction` is needed to sign the `transaction`

Future<Set<Map<String, dynamic>>> generateL2Transaction(
    Map tx, String bjj, Token token) async {
  final type = tx['type'] != null ? tx['type'] : getTransactionType(tx);
  final nonce = await getNonce(tx['nonce'], tx['from'], bjj, token.id);
  final toAccountIndex = isHermezAccountIndex(tx['to']) ? tx['to'] : null;
  final decompressedAmount =
      HermezCompressedAmount.decompressAmount(tx['amount']);
  final feeBigInt = getTokenAmountBigInt(tx['fee'], token.decimals);

  String toHezEthereumAddress;
  if (type == 'TransferToEthAddr') {
    toHezEthereumAddress = tx['to'];
  }
  /* else if (type == 'TransferToBJJ') {
    toHezEthereumAddress = tx['toAuxEthAddr'] != null
        ? tx['toAuxEthAddr']
        : INTERNAL_ACCOUNT_ETH_ADDR;
  }*/

  Map<String, dynamic> transaction = {};
  transaction.putIfAbsent('type', () => type);
  transaction.putIfAbsent('tokenId', () => token.id);
  transaction.putIfAbsent('fromAccountIndex', () => tx['from']);
  transaction.putIfAbsent('toAccountIndex',
      () => type == 'Exit' ? 'hez:${token.symbol}:1' : toAccountIndex);
  transaction.putIfAbsent('toHezEthereumAddress', () => toHezEthereumAddress);
  transaction.putIfAbsent(
      'toBjj', () => type == 'TransferToBJJ' ? tx['to'] : null);
  // Corrects precision errors using the same system used in the Coordinator
  transaction.putIfAbsent(
      'amount', () => decompressedAmount.toString().replaceAll(".0", ""));
  transaction.putIfAbsent(
      'fee', () => getFeeIndex(feeBigInt.toDouble(), decompressedAmount));
  transaction.putIfAbsent('nonce', () => nonce);
  transaction.putIfAbsent('requestFromAccountIndex', () => null);
  transaction.putIfAbsent('requestToAccountIndex', () => null);
  transaction.putIfAbsent('requestToHezEthereumAddress', () => null);
  transaction.putIfAbsent('requestToBjj', () => null);
  transaction.putIfAbsent('requestTokenId', () => null);
  transaction.putIfAbsent('requestAmount', () => null);
  transaction.putIfAbsent('requestFee', () => null);
  transaction.putIfAbsent('requestNonce', () => null);
  Map<String, dynamic> encodedTransaction =
      await encodeTransaction(transaction);
  transaction.putIfAbsent(
      'id',
      () => getL2TxId(
          encodedTransaction['fromAccountIndex'],
          encodedTransaction['tokenId'],
          decompressedAmount,
          encodedTransaction['nonce'],
          encodedTransaction['fee']));
  return {transaction, encodedTransaction};
}
