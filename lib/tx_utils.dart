import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hex/hex.dart';

import 'fee_factors.dart' show feeFactors;
import 'eddsa_babyjub.dart' show hashPoseidon;
import 'tx_pool.dart' show getPoolTransactions;

import 'libs/circomlib.dart';

const String hermezPrefix = "hez:";

final DynamicLibrary nativeExampleLib = Platform.isAndroid
    ? DynamicLibrary.open("libbabyjubjub.so")
    : DynamicLibrary.process();

final circomlib = CircomLib(lib: await SetupUtil.getDylibAsync());

class TxUtils {
  /// Encodes the transaction object to be in a format supported by the Smart Contracts and Circuits.
  /// Used, for example, to sign the transaction
  ///
  /// @param {Object} transaction - Transaction object returned by generateL2Transaction
  ///
  /// @returns {Object} encodedTransaction
  static Future<dynamic> encodeTransaction(dynamic transaction) async {
    //return hermezPrefix + ethereumAddress;
    //const provider = getProvider()
    //encodedTransaction.chainId = await provider.getNetwork().chainId
  }

  /*async function encodeTransaction (transaction) {
    const encodedTransaction = Object.assign({}, transaction)

    const provider = getProvider()
    encodedTransaction.chainId = await provider.getNetwork().chainId

    encodedTransaction.fromAccountIndex = getAccountIndex(transaction.fromAccountIndex)
    if (transaction.toAccountIndex) {
      encodedTransaction.toAccountIndex = getAccountIndex(transaction.toAccountIndex)
    } else if (transaction.type === 'Exit') {
      encodedTransaction.toAccountIndex = 1
    }

    return encodedTransaction
  }*/

  /// TxID (12 bytes) for L2Tx is:
  /// bytes:  |  1   |    6    |   5   |
  /// values: | type | FromIdx | Nonce |
  /// where type for L2Tx is '2'
  ///
  /// @param {Number} fromIdx
  /// @param {Number} nonce
  ///
  /// @returns {String}
  String getTxId (int fromIdx, int nonce) {
    BigInt.from(fromIdx)
    Uint8List.fromList(elements)
    ByteBuffer
    const fromIdxBytes = new ArrayBuffer(8)
    const fromIdxView = new DataView(fromIdxBytes)
    fromIdxView.setBigUint64(0, BigInt(fromIdx).value, false)

    final nonceBytes = Uint8List(8);
    nonceBytes.add(nonce);
    HEX.encode(nonceBytes.buffer.asUint8List(2, 8).toList());

    //const nonceBytes = new ArrayBuffer(8)
    const nonceView = new DataView(nonceBytes)
    nonceView.setBigUint64(0, BigInt(nonce).value, false)

    const fromIdxHex = HEX.encode(input) bufToHex(fromIdxView.buffer.slice(2, 8))
    const nonceHex = HEX.encode() bufToHex(nonceView.buffer.slice(3, 8))
    return '0x02' + fromIdxHex + nonceHex;
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
    if (transaction.to && transaction.to.includes('hez:')) {
      return 'Transfer';
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
  Future<num> getNonce(num currentNonce, num accountIndex, String bjj, num tokenId) async {
    final List<dynamic> poolTxs = await getPoolTransactions(accountIndex.toString(), bjj);
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
    res = res + BigInt.from((tx.chainId ? tx.chainId : 0) << 32); // chainId --> 16 bits
    res = res + BigInt.from((tx.fromAccountIndex ? tx.fromAccountIndex : 0) << 48); // fromIdx --> 48 bits
    res = res + BigInt.from((tx.toAccountIndex ? tx.toAccountIndex : 0) << 96); // toIdx --> 48 bits
    res = res + BigInt.from((tx.amount.toDouble() ? tx.amount.toDouble() : 0) << 144); // amounf16 --> 16 bits
    res = res + BigInt.from((tx.tokenId ? tx.tokenId : 0) << 160);  // tokenID --> 32 bits
    res = res + BigInt.from((tx.nonce ? tx.nonce : 0) << 192); // nonce --> 40 bits
    res = res + BigInt.from((tx.fee ? tx.fee : 0) << 232); // userFee --> 8 bits
    res = res + BigInt.from((tx.toBjjSign ? 1 : 0) << 240); // toBjjSign --> 1 bit

    return res;
  }

  /// Builds the message to hash
  ///
  /// @param {Object} encodedTransaction - Transaction object
  ///
  /// @returns {Scalar} message to sign
  BigInt buildTransactionHashMessage(dynamic encodedTransaction) {
    final txCompressedData = buildTxCompressedData(encodedTransaction);

    final h = hashPoseidon(
      txCompressedData,
      encodedTransaction.to_eth_addr,
      encodedTransaction.toBjjAy,
      encodedTransaction.rqTxCompressedDataV2,
      encodedTransaction.rqToEthAddr,
      encodedTransaction.rqToBjjAy
    );
    BigInt.from(HEX.decode(encoded));
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

  Future<dynamic> generateL2Transaction(
      dynamic tx, dynamic bjj, dynamic token) async {
    Map<String, dynamic> transaction = {};
    transaction.putIfAbsent('type', () => getTransactionType(tx));
    transaction.putIfAbsent('tokenId', () => token.id);
    transaction.putIfAbsent('fromAccountIndex', () => tx.from);
    transaction.putIfAbsent('toAccountIndex', () => tx.to || null);
    transaction.putIfAbsent('toHezEthereumAddress', () => null);
    transaction.putIfAbsent('toBjj', () => null);
    transaction.putIfAbsent('amount', () => tx.amount.toString());
    transaction.putIfAbsent('fee', () => getFee(tx.fee, tx.amount, token.decimals));
    transaction.putIfAbsent('nonce', () async => await getNonce(tx.nonce, tx.from, bjj, token.id));
    transaction.putIfAbsent('requestFromAccountIndex', () => null);
    transaction.putIfAbsent('requestToAccountIndex', () => null);
    transaction.putIfAbsent('requestToHezEthereumAddress', () => null);
    transaction.putIfAbsent('requestToBJJ', () => null);
    transaction.putIfAbsent('requestTokenId', () => null);
    transaction.putIfAbsent('requestAmount', () => null);
    transaction.putIfAbsent('requestFee', () => null);
    transaction.putIfAbsent('requestNonce', () => null);
    dynamic encodedTransaction = await encodeTransaction(transaction);
    transaction.putIfAbsent('id', () => getTxId(encodedTransaction.fromAccountIndex, encodedTransaction.nonce));
    return {
      transaction, encodedTransaction
    };
  }
}
