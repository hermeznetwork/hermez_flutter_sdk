import 'dart:math';

import 'fee_factors.dart' show feeFactors;

const String hermezPrefix = "hez:";

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

  static Future<dynamic> generateL2Transaction(
      dynamic transaction, dynamic bjj, dynamic token) async {
    /*dynamic transaction = {
      tokenId: token.id,
    };*/
    dynamic encodedTransaction = await encodeTransaction(transaction);
  }
}
