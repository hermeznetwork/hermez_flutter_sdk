import 'package:hermez_plugin/abis/ERC20ABI.json' as ERC20ABI;
import 'package:hermez_plugin/contracts.dart' show getContract;

import 'constants.dart' show contractAddresses;

/// Sends an approve transaction to an ERC 20 contract for a certain amount of tokens
///
/// @param {BigInt} amount - Amount of tokens to be approved by the ERC 20 contract
/// @param {String} accountAddress - The Ethereum address of the transaction sender
/// @param {String} contractAddress - The token smart contract address
///
/// @returns {Promise} transaction
Future<String> approve(
    BigInt amount, String accountAddress, String contractAddress) async {
  final erc20Contract = getContract(contractAddress, ERC20ABI);
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
