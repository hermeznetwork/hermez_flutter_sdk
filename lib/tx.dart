import 'dart:typed_data';

import 'package:hermez_plugin/environment.dart';
import 'package:hermez_plugin/hermez_wallet.dart';
import 'package:hermez_plugin/model/token.dart';
import 'package:hermez_plugin/tokens.dart';
import 'package:hermez_plugin/utils/contract_parser.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'addresses.dart' show getEthereumAddress, getAccountIndex;
import 'api.dart' show getAccounts, postPoolTransaction;
import 'constants.dart'
    show
        BASE_WEB3_RDP_URL,
        BASE_WEB3_URL,
        GAS_LIMIT,
        GAS_MULTIPLIER,
        contractAddresses;
import 'hermez_compressed_amount.dart';
import 'model/account.dart';
import 'tx_pool.dart' show addPoolTransaction;
import 'tx_utils.dart' show generateL2Transaction;

ContractFunction _addL1Transaction(DeployedContract contract) =>
    contract.function('addL1Transaction');
ContractFunction _withdrawMerkleProof(DeployedContract contract) =>
    contract.function('withdrawMerkleProof');
ContractFunction _withdrawal(DeployedContract contract) =>
    contract.function('withdrawal');

ContractEvent _addTokenEvent(DeployedContract contract) =>
    contract.event('AddToken');
ContractEvent _l1UserTxEvent(DeployedContract contract) =>
    contract.event('L1UserTxEvent');

/// Get current average gas price from the last ethereum blocks and multiply it
/// @param {Number} multiplier - multiply the average gas price by this parameter
/// @param {Web3Client} web3Client - Network url (i.e, http://localhost:8545). Optional
/// @returns {Future<int>} - will return the gas price obtained.
Future<int> getGasPrice(num multiplier, Web3Client web3client) async {
  EtherAmount strAvgGas = await web3client.getGasPrice();
  BigInt avgGas = strAvgGas.getInWei;
  BigInt res = avgGas * BigInt.from(multiplier);
  int retValue = res.toInt(); //toString();
  return retValue;
}

/// Makes a deposit.
/// It detects if it's a 'createAccountDeposit' or a 'deposit' and prepares the parameters accordingly.
/// Detects if it's an Ether, ERC 20 token and sends the transaction accordingly.
///
/// @param {BigInt} amount - The amount to be deposited
/// @param {String} hezEthereumAddress - The Hermez address of the transaction sender
/// @param {Object} token - The token information object as returned from the API
/// @param {String} babyJubJub - The compressed BabyJubJub in hexadecimal format of the transaction sender.
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Number} gasMultiplier - Optional gas multiplier
///
/// @returns {Promise} transaction
Future<bool> deposit(HermezCompressedAmount amount, String hezEthereumAddress,
    Token token, String babyJubJub, Web3Client web3client, String privateKey,
    {gasLimit = GAS_LIMIT, gasMultiplier = GAS_MULTIPLIER}) async {
  final ethereumAddress = getEthereumAddress(hezEthereumAddress);

  final accounts = await getAccounts(hezEthereumAddress, [token.id]);

  final Account account = accounts != null && accounts.accounts.isNotEmpty
      ? accounts.accounts[0]
      : null;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  final credentials = await web3client.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  final gasPrice = EtherAmount.fromUnitAndValue(
      EtherUnit.wei, await getGasPrice(gasMultiplier, web3client));

  final transactionParameters = [
    account != null ? BigInt.zero : hexToInt(babyJubJub),
    account != null
        ? BigInt.from(getAccountIndex(account.accountIndex))
        : BigInt.zero,
    BigInt.from(amount.value),
    BigInt.zero,
    BigInt.from(token.id),
    BigInt.zero,
    hexToBytes('0x')
  ];

  final decompressedAmount = HermezCompressedAmount.decompressAmount(amount);

  if (token.id == 0) {
    Transaction transaction = Transaction.callContract(
        contract: hermezContract,
        function: _addL1Transaction(hermezContract),
        from: from,
        parameters: transactionParameters,
        maxGas: gasLimit,
        gasPrice: gasPrice,
        value: EtherAmount.fromUnitAndValue(EtherUnit.wei, decompressedAmount));

    print(
        'deposit ETH --> privateKey: $privateKey, sender: $from, receiver: ${hermezContract.address}, amountInWei: $decompressedAmount');

    String txHash = await web3client.sendTransaction(credentials, transaction,
        chainId: getCurrentEnvironment().chainId);

    print(txHash);

    return txHash != null;
  }

  int nonceBefore = await web3client.getTransactionCount(from);

  await approve(decompressedAmount, ethereumAddress, token.ethereumAddress,
      token.name, web3client, credentials);

  int nonceAfter = await web3client.getTransactionCount(from);

  int correctNonce = nonceAfter;

  if (nonceBefore == nonceAfter) {
    correctNonce = nonceAfter + 1;
  }

  // Keep in mind that web3.eth.getTransactionCount(walletAddress)
  // will only give you the last CONFIRMED nonce.
  // So it won't take the unmined ones into account.

  Transaction transaction = Transaction.callContract(
      contract: hermezContract,
      function: _addL1Transaction(hermezContract),
      parameters: transactionParameters,
      maxGas: gasLimit,
      gasPrice: gasPrice,
      nonce: correctNonce);

  print('sendTransaction');
  print(
      'deposit ERC20 --> privateKey: $privateKey, sender: $from, receiver: ${hermezContract.address}, amountInWei: $amount');

  String txHash = await web3client.sendTransaction(credentials, transaction,
      chainId: getCurrentEnvironment().chainId);

  print(txHash);

  return txHash != null;
}

Future<String> _sendTransaction(String privateKey,
    EthereumAddress receiverAddress, EtherAmount amount) async {}

/*class HermezWeb3Client extends Web3Client {
  final _jsonRpc;
  HermezWeb3Client(String url, Client httpClient,
      {bool enableBackgroundIsolate = false})
      : _jsonRpc = JsonRPC(url, httpClient);

  Future<List> call(
      {EthereumAddress sender,
      DeployedContract contract,
      ContractFunction function,
      List params,
      BlockNum atBlock}) async {
    final encodedResult = await callRaw(
      sender: sender,
      contract: contract.address,
      data: function.encodeCall(params),
    );

    return function.decodeReturnValues(encodedResult);
  }

  Future<T> _makeRPCCall<T>(String function, [List<dynamic> params]) async {
    try {
      final data = await _jsonRpc.call(function, params);
      // ignore: only_throw_errors
      if (data is Error || data is Exception) throw data;

      return data.result as T;
    } catch (e) {
      if (printErrors) print(e);

      rethrow;
    }
  }

  @override
  Future<String> callRaw(
      {EthereumAddress sender,
      EthereumAddress contract,
      Uint8List data,
      BlockNum atBlock}) {
    // TODO: implement callRaw
    final call = {
      'to': contract.hex,
      'data': bytesToHex(data, include0x: true, padToEvenLength: true),
    };

    if (sender != null) {
      call['from'] = sender.hex;
    }

    /*if (gasLimit != null) {
      call['gasLimit'] = '0x${amountOfGas.toRadixString(16)}';
    }
    if (gasPrice != null) {
      call['gasPrice'] = '0x${amountOfGas.toRadixString(16)}';
    }

    if (value != null) {
      call['value'] = 0;
    }*/

    return _makeRPCCall<String>('eth_call', [call, _getBlockParam(atBlock)]);
  }

  /// Estimate the amount of gas that would be necessary if the transaction was
  /// sent via [sendTransaction]. Note that the estimate may be significantly
  /// higher than the amount of gas actually used by the transaction.
  Future<BigInt> estimateGas({
    EthereumAddress sender,
    EthereumAddress to,
    EtherAmount value,
    BigInt amountOfGas,
    EtherAmount gasPrice,
    Uint8List data,
    @Deprecated('Parameter is ignored') BlockNum atBlock,
  }) async {
    final amountHex = await _makeRPCCall<String>(
      'eth_estimateGas',
      [
        {
          if (sender != null) 'from': sender.hex,
          if (to != null) 'to': to.hex,
          if (amountOfGas != null) 'gas': '0x${amountOfGas.toRadixString(16)}',
          if (gasPrice != null)
            'gasPrice': '0x${amountOfGas.toRadixString(16)}',
          if (data != null) 'data': bytesToHex(data, include0x: true),
        },
      ],
    );
    return hexToInt(amountHex);
  }

 /*Map<String, dynamic> overrides = Map();
  overrides.putIfAbsent('gasLimit', () => gasLimit);
  overrides.putIfAbsent(
      'gasPrice', () async => );

  ContractFunction addL1Transaction = _addL1Transaction(hermezContract);*/

  //print([...transactionParameters, overrides]);

  /*final call = {
    'gasLimit': '0x${5000000.toRadixString(16)}',
    'gasPrice': '0x${20000000000.toRadixString(16)}',
    'value': bytesToHex(, include0x: true, padToEvenLength: true),
  };*/

  /*if (gasLimit != null) {
    call['gasLimit'] = '0x${5000000.toRadixString(16)}';
  }
  if (gasPrice != null) {
    call['gasPrice'] = '0x${20000000000.toRadixString(16)}';
  }

  if (value != null) {
    call['value'] = '0x${100000000000000000.toRadixString(16)}';
  }*/

 /*final data = Transaction(
      gasPrice: EtherAmount.fromUnitAndValue(
          EtherUnit.wei, await getGasPrice(gasMultiplier, web3client)),
      maxGas: gasLimit,
      value: EtherAmount.fromUnitAndValue(EtherUnit.wei, amount),
    ).data;*/
    //overrides.putIfAbsent('value', () => amount);
    //overrides = amount; //Uint8List.fromList([amount.toInt()]);
    //print([...transactionParameters, overrides]);

    /*var credentials = await web3client.credentialsFromPrivateKey(privateKey);

    final from = await credentials.extractAddress();
    final networkId = await web3client.getNetworkId();

    final gasPrice = await web3client.getGasPrice();
    final maxGas = await web3client.estimateGas(
        sender: from,
        to: hermezContract.address,
        value: EtherAmount.fromUnitAndValue(EtherUnit.wei, amount));

    try {
      final transactionId = await web3client.sendTransaction(
          credentials,
          Transaction.callContract(
              contract: hermezContract,
              function: _addL1Transaction(hermezContract),
              parameters: transactionParameters,
              maxGas: 5000000,
              gasPrice: gasPrice,
              from: from),
          chainId: networkId);
      print('transact started $transactionId');
      return transactionId != null;
    } catch (ex) {
      return false;
    }*/

    /* await web3client.sendTransaction(
      credentials,
      Transaction.callContract(
          contract: hermezContract,
          function: _addL1Transaction(hermezContract),
          parameters: transactionParameters,
          maxGas: 5000000,
          gasPrice: EtherAmount.fromUnitAndValue(
              EtherUnit.wei, await getGasPrice(gasMultiplier, web3client)),
          value: EtherAmount.fromUnitAndValue(EtherUnit.wei, amount)),
    );*/

    /*final addL1TransactionCall = await web3client.call(
        contract: hermezContract,
        function: _addL1Transaction(hermezContract),
        params: /*[...transactionParameters, data]*/ transactionParameters);*/
    //overrides
    //[...transactionParameters, data]);


 /*final maxGas = await web3client.estimateGas(
        sender: from,
        to: hermezContract.address,
        value: EtherAmount.fromUnitAndValue(EtherUnit.wei, amount),
        data: transaction.data);*/

  /*Transaction transaction = Transaction(
      from: from,
      to: receiverAddress,
      maxGas: maxGas.toInt(),
      gasPrice: gasPrice,
      value: amount);*/


 // listen for the Transfer event when it's emitted by the contract above
    /*final subscription = web3client
        .events(FilterOptions.events(
            contract: hermezContract, event: _l1UserTxEvent(hermezContract)))
        .take(1)
        .listen((event) {
      final decoded = _l1UserTxEvent(hermezContract)
          .decodeResults(event.topics, event.data);

      final from = decoded[0] as EthereumAddress;
      final to = decoded[1] as EthereumAddress;
      final value = decoded[2] as BigInt;

      print('$from sent $value MetaCoins to $to');
    });*/


     await subscription.asFuture();
    await subscription.cancel();

    /*/*final subscription =*/ web3client
        .events(FilterOptions.events(
            contract: hermezContract, event: _addTokenEvent(hermezContract)))
        .take(1)
        .listen((event) {
      final decoded = _addTokenEvent(hermezContract)
          .decodeResults(event.topics, event.data);

      final from = decoded[0] as EthereumAddress;
      final to = decoded[1] as EthereumAddress;
      final value = decoded[2] as BigInt;

      print('$from sent $value MetaCoins to $to');
    });*/

}*/

/// Makes a force Exit. This is the L1 transaction equivalent of Exit.
///
/// @param {BigInt} amount - The amount to be withdrawn
/// @param {String} accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param {Object} token - The token information object as returned from the API
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Number} gasMultiplier - Optional gas multiplier
void forceExit(
    BigInt amount, String accountIndex, dynamic token, Web3Client web3client,
    {gasLimit = GAS_LIMIT, gasMultiplier = GAS_MULTIPLIER}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  dynamic overrides = Uint8List.fromList(
      [gasLimit, await getGasPrice(gasMultiplier, web3client)]);

  final transactionParameters = [
    BigInt.zero,
    getAccountIndex(accountIndex),
    BigInt.zero,
    amount,
    token.id,
    1,
    '0x'
  ];

  final addL1TransactionCall = await web3client.call(
      contract: hermezContract,
      function: _addL1Transaction(hermezContract),
      params: [...transactionParameters, overrides]);
}

/// Finalise the withdraw. This a L1 transaction.
///
/// @param {BigInt} amount - The amount to be withdrawn
/// @param {String} accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param {Object} token - The token information object as returned from the API
/// @param {String} babyJubJub - The compressed BabyJubJub in hexadecimal format of the transaction sender.
/// @param {BigInt} merkleRoot - The merkle root of the exit being withdrawn.
/// @param {Array} merkleSiblings - An array of BigInts representing the siblings of the exit being withdrawn.
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Boolean} isInstant - Whether it should be an Instant Withdrawal
/// @param {Boolean} filterSiblings - Whether siblings should be filtered
/// @param {Number} gasLimit - Optional gas limit
/// @param {Bumber} gasMultiplier - Optional gas multiplier
Future withdraw(
    BigInt amount,
    String accountIndex,
    dynamic token,
    String babyJubJub,
    BigInt batchNumber,
    List<BigInt> merkleSiblings,
    Web3Client web3client,
    {bool isInstant = true,
    gasLimit = GAS_LIMIT,
    gasMultiplier = GAS_MULTIPLIER}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  dynamic overrides = Uint8List.fromList(
      [gasLimit, await getGasPrice(gasMultiplier, web3client)]);

  final transactionParameters = [
    token.id,
    amount,
    '0x$babyJubJub',
    batchNumber,
    merkleSiblings,
    getAccountIndex(accountIndex),
    isInstant,
  ];

  print([...transactionParameters, overrides]);

  //final l1Transaction = new List()..addAll(transactionParameters);
  //l1Transaction.add(overrides);

  final withdrawMerkleProofCall = await web3client.call(
      contract: hermezContract,
      function: _withdrawMerkleProof(hermezContract),
      params: [...transactionParameters, overrides]);
}

/// Makes the final withdrawal from the WithdrawalDelayer smart contract after enough time has passed.
///
/// @param {String} hezEthereumAddress - The Hermez address of the transaction sender
/// @param {Object} token - The token information object as returned from the API
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Bumber} gasMultiplier - Optional gas multiplier
Future delayedWithdraw(
    String hezEthereumAddress, dynamic token, Web3Client web3client,
    {gasLimit = GAS_LIMIT, gasMultiplier = GAS_MULTIPLIER}) async {
  final withdrawalDelayerContract = await ContractParser.fromAssets(
      'WithdrawalDelayerABI.json',
      contractAddresses['WithdrawalDelayer'],
      "WithdrawalDelayer");

  dynamic overrides = Uint8List.fromList(
      [gasLimit, await getGasPrice(gasMultiplier, web3client)]);

  final String ethereumAddress = getEthereumAddress(hezEthereumAddress);

  final transactionParameters = [
    ethereumAddress,
    token.id == 0 ? 0x0 : token.ethereumAddress
  ];

  final delayedWithdrawalCall = await web3client.call(
      contract: withdrawalDelayerContract,
      function: _withdrawal(withdrawalDelayerContract),
      params: [...transactionParameters, overrides]);
}

/// Sends a L2 transaction to the Coordinator
///
/// @param {Object} transaction - Transaction object prepared by TxUtils.generateL2Transaction
/// @param {String} bJJ - The compressed BabyJubJub in hexadecimal format of the transaction sender.
///
/// @return {Object} - Object with the response status, transaction id and the transaction nonce
dynamic sendL2Transaction(dynamic transaction, String bJJ) async {
  dynamic result = await postPoolTransaction(transaction);

  if (result.status == 200) {
    addPoolTransaction(transaction, bJJ);
  }

  return {
    "status": result.status,
    "id": result.data,
    "nonce": transaction.nonce,
  };
}

/// Compact L2 transaction generated and sent to a Coordinator.
/// @param {Object} transaction - ethAddress and babyPubKey together
/// @param {String} transaction.from - The account index that's sending the transaction e.g hez:DAI:4444
/// @param {String} transaction.to - The account index of the receiver e.g hez:DAI:2156. If it's an Exit, set to a falseable value
/// @param {BigInt} transaction.amount - The amount being sent as a BigInt
/// @param {Number} transaction.fee - The amount of tokens to be sent as a fee to the Coordinator
/// @param {Number} transaction.nonce - The current nonce of the sender's token account
/// @param {Object} wallet - Transaction sender Hermez Wallet
/// @param {Object} token - The token information object as returned from the Coordinator.
dynamic generateAndSendL2Tx(
    dynamic transaction, HermezWallet wallet, dynamic token) async {
  final Set<Map<String, dynamic>> l2TxParams = await generateL2Transaction(
      transaction, wallet.publicKeyCompressedHex, token);

  Map<String, dynamic> l2Transaction = l2TxParams.first;
  Map<String, dynamic> l2EncodedTransaction = l2TxParams.last;

  wallet.signTransaction(l2Transaction, l2EncodedTransaction);

  final l2TxResult =
      await sendL2Transaction(l2Transaction, wallet.publicKeyCompressedHex);

  return l2TxResult;
}
