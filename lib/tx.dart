import 'dart:convert' show json;
import 'dart:io';

import 'package:hermez_plugin/contracts.dart';
import 'package:web3dart/web3dart.dart';

import 'addresses.dart' show getEthereumAddress, getAccountIndex;
import 'constants.dart' show GAS_LIMIT, GAS_MULTIPLIER, contractAddresses;
import 'providers.dart' show getProvider;
import 'tokens.dart' show approve;

class Tx {
  static const Map<String, String> txType = {
    "Deposit": "Deposit",
    "Transfer": "Transfer",
    "Withdraw": "Withdrawn",
    "Exit": "Exit"
  };

  static const Map<String, String> txState = {
    "Forged": "fged",
    "Forging": "fing",
    "Pending": "pend",
    "Invalid": "invl"
  };

  /// Get current average gas price from the last ethereum blocks and multiply it
  /// @param {Number} multiplier - multiply the average gas price by this parameter
  /// @returns {Future<String>} - will return the gas price obtained.
  static Future<String> getGasPrice(int multiplier) async {
    Web3Client provider = getProvider();
    EtherAmount strAvgGas = await provider.getGasPrice();
    BigInt avgGas = strAvgGas.getInEther;
    BigInt res = avgGas * BigInt.from(multiplier);
    String retValue = res.toString();
    return retValue;
  }

  /// Makes a deposit.
  /// It detects if it's a 'createAccountDeposit' or a 'deposit' and prepares the parameters accodingly.
  /// Detects if it's an Ether, ERC 20 token and sends the transaction accordingly.
  ///
  /// @param {BigInt} amount - The amount to be deposited
  /// @param {String} hezEthereumAddress - The Hermez address of the transaction sender
  /// @param {Object} token - The token information object as returned from the API
  /// @param {String} babyJubJub - The compressed BabyJubJub in hexadecimal format of the transaction sender.
  /// @param {Number} gasLimit - Optional gas limit
  /// @param {Number} gasMultiplier - Optional gas multiplier
  ///
  /// @returns {Promise} transaction
  static void deposit(BigInt amount, String hezEthereumAddress, dynamic token,
      String babyJubJub,
      {gasLimit = GAS_LIMIT, gasMultiplier = GAS_MULTIPLIER}) async {
    Map hermezABI =
        json.decode(await new File('abis/HermezABI.json').readAsString());

    dynamic hermezContract =
        getContract(contractAddresses["Hermez"], hermezABI);

    dynamic ethereumAddress = getEthereumAddress(hezEthereumAddress);
    //dynamic account = (await getAccounts(ethereumAddress, token.id)).accounts[0]

    String gasPrice = await getGasPrice(gasMultiplier);

    await approve(amount, ethereumAddress, token.ethereumAddress);
  }

  /// Sends a L2 transaction to the Coordinator
  ///
  /// @param {Object} transaction - Transaction object prepared by TxUtils.generateL2Transaction
  /// @param {String} bJJ - The compressed BabyJubJub in hexadecimal format of the transaction sender.
  ///
  /// @return {Object} - Object with the response status, transaction id and the transaction nonce
  static void send(dynamic transaction, String babyJubJub) async {
    //dynamic result = await postPoolTransaction(transaction);
  }

  /*async function send (transaction, bJJ) {
    const result = await postPoolTransaction(transaction)

    if (result.status === 200) {
      addPoolTransaction(transaction, bJJ)
    }
    return {
      status: result.status,
      id: result.data,
      nonce: transaction.nonce
    }
  }*/
}
