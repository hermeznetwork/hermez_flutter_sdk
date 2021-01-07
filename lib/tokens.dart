import 'dart:convert';
import 'dart:io';

import 'package:hermez_plugin/contracts.dart' show getContract;

import 'constants.dart' show contractAddresses;

/// Sends an approve transaction to an ERC 20 contract for a certain amount of tokens
///
/// @param {BigInt} amount - Amount of tokens to be approved by the ERC 20 contract
/// @param {String} accountAddress - The Ethereum address of the transaction sender
/// @param {String} contractAddress - The token smart contract address
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
///
/// @returns {Promise} transaction
Future<String> approve(BigInt amount, String accountAddress,
    String contractAddress, String providerUrl, dynamic signerData) async {
  //final txSignerData =
  //    signerData || {type: SignerType.JSON_RPC, addressOrIndex: accountAddress};
  Map erc20ABI =
      json.decode(await new File('abis/ERC20ABI.json').readAsString());

  dynamic erc20Contract =
      getContract(contractAddress, erc20ABI, providerUrl, signerData);
  final allowance = await erc20Contract.allowance(
      accountAddress, contractAddresses['Hermez']);

  if (allowance < amount) {
    return erc20Contract.appove(contractAddresses['Hermez'], amount);
  }

  if (!allowance.isZero(amount)) {
    final tx = await erc20Contract.approve(contractAddresses['Hermez'], '0');
    await tx.wait(1);
  }

  return erc20Contract.approve(contractAddresses['Hermez'], amount);
}
