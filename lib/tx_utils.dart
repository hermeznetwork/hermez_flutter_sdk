import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:hermez_plugin/utils/uint8_list_utils.dart';
import 'package:web3dart/crypto.dart';

import 'addresses.dart'
    show getAccountIndex, isHermezAccountIndex, isHermezEthereumAddress;
import 'fee_factors.dart' show feeFactors;
import 'hermez_compressed_amount.dart';
import 'model/token.dart';
import 'providers.dart' show getProvider;
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

//final circomlib = CircomLib(lib: await SetupUtil.getDylibAsync());

/// Encodes the transaction object to be in a format supported by the Smart Contracts and Circuits.
/// Used, for example, to sign the transaction
///
/// @param {Object} transaction - Transaction object returned by generateL2Transaction
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
///
/// @returns {Object} encodedTransaction
Future<dynamic> encodeTransaction(dynamic transaction,
    {String providerUrl}) async {
  final encodedTransaction = transaction.clone();

  final provider = getProvider(providerUrl, providerUrl);
  //encodedTransaction.chainId = await provider.getNetwork().chainId

  encodedTransaction.fromAccountIndex =
      getAccountIndex(transaction.fromAccountIndex);
  if (transaction.toAccountIndex) {
    encodedTransaction.toAccountIndex =
        getAccountIndex(transaction.toAccountIndex);
  } else if (transaction.runtimeType.toString() == 'Exit') {
    encodedTransaction.toAccountIndex = 1;
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
String getL1UserTxId(int toForgeL1TxsNum, int currentPosition) {
  final toForgeL1TxsNumBytes = Uint8List(8);
  final toForgeL1TxsNumView = ByteData.view(toForgeL1TxsNumBytes.buffer);
  toForgeL1TxsNumView.setUint64(0, toForgeL1TxsNum);

  final positionBytes = Uint8List(8);
  final positionView = ByteData.view(positionBytes.buffer);
  positionView.setUint64(0, currentPosition);

  /*toForgeL1TxsNumBytes.add(toForgeL1TxsNum);
  toForgeL1TxsNumBytes.buffer.asByteData().setUint64(byteOffset, value)
  final fromIdxHex = HEX.encode(fromIdxBytes.buffer.asUint8List(2, 8).toList());

  final nonceBytes = Uint8List(8);
  nonceBytes.add(nonce);
  final nonceHex = HEX.encode(nonceBytes.buffer.asUint8List(3, 8).toList());*/

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
/// @param {BigInt} amount - The amount being transacted
/// @param {Number} nonce - Nonce of the transaction
/// @param {Number} fee - The fee of the transaction
/// @returns {String} Transaction Id
String getL2TxId(int fromIdx, int tokenId, BigInt amount, int nonce, int fee) {
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
/// @param {String} amount - The amount as a BigInt string
/// @param {Number} decimals - The decimals
///
/// @return {Number} feeFactor
int getFee(int fee, String amount, int decimals) {
  int amountFloat = BigInt.parse(amount).toInt() ~/ pow(10, decimals);
  num percentage = fee / amountFloat;
  num low = 0;
  int mid;
  int high = feeFactors.length - 1;
  while (high - low > 1) {
    mid = ((low + high) / 2).floor();
    if (feeFactors[mid] < percentage) {
      low = mid;
    } else {
      high = mid;
    }
  }

  return high;
}

/// Gets the transaction type depending on the information in the transaction object
/// If an account index is used, it will be 'Transfer'
/// If a Hermez address is used, it will be 'TransferToEthAddr'
/// If a BabyJubJub is used, it will be 'TransferToBjj'
///
/// @param {Object} transaction - Transaction object sent to generateL2Transaction
///
/// @return {String} transactionType
String getTransactionType(dynamic transaction) {
  if (transaction.to) {
    if (isHermezAccountIndex(transaction.to)) {
      return 'Transfer';
    } else if (isHermezEthereumAddress(transaction.to)) {
      return 'TransferToEthAddr';
    }
  } else {
    return 'Exit';
  }
}

/// Calculates the appropriate nonce based on the current token account nonce and existing transactions in the Pool.
/// It needs to find the lowest nonce available as transactions in the pool may fail and the Coordinator only forges
/// transactions in the order set by nonces.
///
/// @param {Number} currentNonce - The current token account nonce
/// @param {String} bjj - The account's BabyJubJub
/// @param {Number} tokenId - The token id of the token in the transaction
///
/// @return {Number} nonce
Future<num> getNonce(
    num currentNonce, num accountIndex, String bjj, num tokenId) async {
  final List<dynamic> poolTxs =
      await getPoolTransactions(accountIndex.toString(), bjj);
  poolTxs.removeWhere((tx) => tx.token.id == tokenId);
  final List<int> poolTxsNonces = poolTxs.map((tx) => tx.nonce);
  poolTxs.sort();

  int nonce = currentNonce + 1;
  while (poolTxsNonces.indexOf(nonce) != -1) {
    nonce++;
  }

  return nonce;
}

/// Encode tx compressed data
/// @param {Object} tx - Transaction object
/// @returns {BigInt} Encoded tx compressed data
BigInt buildTxCompressedData(dynamic tx) {
  final signatureConstant = BigInt.parse('3322668559');
  BigInt res = BigInt.zero;

  res = res + signatureConstant; // SignConst --> 32 bits
  res = res +
      BigInt.from((tx.chainId ? tx.chainId : 0) << 32); // chainId --> 16 bits
  res = res +
      BigInt.from((tx.fromAccountIndex ? tx.fromAccountIndex : 0) <<
          48); // fromIdx --> 48 bits
  res = res +
      BigInt.from((tx.toAccountIndex ? tx.toAccountIndex : 0) <<
          96); // toIdx --> 48 bits
  res = res +
      BigInt.from((tx.amount.toDouble() ? tx.amount.toDouble() : 0) <<
          144); // amounf16 --> 16 bits
  res = res +
      BigInt.from((tx.tokenId ? tx.tokenId : 0) << 160); // tokenID --> 32 bits
  res =
      res + BigInt.from((tx.nonce ? tx.nonce : 0) << 192); // nonce --> 40 bits
  res = res + BigInt.from((tx.fee ? tx.fee : 0) << 232); // userFee --> 8 bits
  res = res + BigInt.from((tx.toBjjSign ? 1 : 0) << 240); // toBjjSign --> 1 bit

  return res;
}

/// Build element_1 for L2HashSignature
/// @param {Object} tx - Transaction object returned by `encodeTransaction`
/// @returns {BigInt} element_1 L2 signature
BigInt buildElement1(tx) {
  BigInt res = BigInt.zero;

  /*res = res + Scalar.add(res, Scalar.fromString(tx.toEthereumAddress || '0', 16)) // ethAddr --> 160 bits
  res = Scalar.add(res, Scalar.shl(HermezCompressedAmount.compressAmount(tx.amount || 0).value, 160)) // amountF --> 40 bits
  res = Scalar.add(res, Scalar.shl(tx.maxNumBatch || 0, 200)) // maxNumBatch --> 32 bits*/

  return res;
}

/// Builds the message to hash
///
/// @param {Object} encodedTransaction - Transaction object
///
/// @returns {Scalar} message to sign
dynamic buildTransactionHashMessage(dynamic encodedTransaction) {
  final BigInt txCompressedData = buildTxCompressedData(encodedTransaction);

  final List<BigInt> params = [
    txCompressedData,
    BigInt.parse(
        encodedTransaction.toEthAddr.isNotEmpty
            ? (encodedTransaction.toEthAddr.startsWith('0x')
                ? encodedTransaction.toEthAddr.substring(2)
                : encodedTransaction.toEthAddr)
            : '0',
        radix: 16),
    BigInt.parse(
        encodedTransaction.toBjjAy.isNotEmpty
            ? (encodedTransaction.toBjjAy.startsWith('0x')
                ? encodedTransaction.toBjjAy.substring(2)
                : encodedTransaction.toBjjAy)
            : '0',
        radix: 16),
    BigInt.parse(
        encodedTransaction.rqTxCompressedDataV2.isNotEmpty
            ? (encodedTransaction.rqTxCompressedDataV2.startsWith('0x')
                ? encodedTransaction.rqTxCompressedDataV2.substring(2)
                : encodedTransaction.rqTxCompressedDataV2)
            : '0',
        radix: 16),
    BigInt.parse(
        encodedTransaction.rqToEthAddr.isNotEmpty
            ? (encodedTransaction.rqToEthAddr.startsWith('0x')
                ? encodedTransaction.rqToEthAddr.substring(2)
                : encodedTransaction.rqToEthAddr)
            : '0',
        radix: 16),
    BigInt.parse(
        encodedTransaction.rqToBjjAy.isNotEmpty
            ? (encodedTransaction.rqToBjjAy.startsWith('0x')
                ? encodedTransaction.rqToBjjAy.substring(2)
                : encodedTransaction.rqToBjjAy)
            : '0',
        radix: 16),
  ];

  final List<int> lint = params.map((bigint) => bigint.toInt());

  final uint8list = Uint8List.fromList(lint);
  Pointer<Uint8> ptr = Uint8ArrayUtils.toPointer(uint8list);
  //final h = hashPoseidon(ptr);
  //final point = h.ref;
  //return h;
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

Future<dynamic> generateL2Transaction(Map tx, String bjj, Token token) async {
  final toAccountIndex = isHermezAccountIndex(tx['to']) ? tx['to'] : null;
  final decompressedAmount =
      HermezCompressedAmount.decompressAmount(tx['amount']);
  Map<String, dynamic> transaction = {};
  transaction.putIfAbsent('type', () => getTransactionType(tx));
  transaction.putIfAbsent('tokenId', () => token.id);
  transaction.putIfAbsent('fromAccountIndex', () => tx['from']);
  transaction.putIfAbsent('toAccountIndex',
      () => tx['type'] == 'Exit' ? 'hez:${token.symbol}:1' : toAccountIndex);
  transaction.putIfAbsent('toHezEthereumAddress',
      () => isHermezEthereumAddress(tx['to']) ? tx['to'] : null);
  transaction.putIfAbsent('toBjj', () => null);
  // Corrects precision errors using the same system used in the Coordinator
  transaction.putIfAbsent('amount', () => decompressedAmount.toString());
  transaction.putIfAbsent('fee',
      () => getFee(tx['fee'], decompressedAmount.toString(), token.decimals));
  transaction.putIfAbsent('nonce',
      () async => await getNonce(tx['nonce'], tx['from'], bjj, token.id));
  transaction.putIfAbsent('requestFromAccountIndex', () => null);
  transaction.putIfAbsent('requestToAccountIndex', () => null);
  transaction.putIfAbsent('requestToHezEthereumAddress', () => null);
  transaction.putIfAbsent('requestToBJJ', () => null);
  transaction.putIfAbsent('requestTokenId', () => null);
  transaction.putIfAbsent('requestAmount', () => null);
  transaction.putIfAbsent('requestFee', () => null);
  transaction.putIfAbsent('requestNonce', () => null);
  dynamic encodedTransaction = await encodeTransaction(transaction);
  transaction.putIfAbsent(
      'id',
      () => getL2TxId(
          encodedTransaction.fromAccountIndex,
          encodedTransaction.tokenId,
          encodedTransaction.amount,
          encodedTransaction.nonce,
          encodedTransaction.fee));
  return {transaction, encodedTransaction};
}
