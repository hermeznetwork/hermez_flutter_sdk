import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hermez_sdk/api.dart' as coordinatorApi;
import 'package:hermez_sdk/hermez_compressed_amount.dart';
import 'package:hermez_sdk/hermez_sdk.dart';
import 'package:hermez_sdk/hermez_wallet.dart';
import 'package:hermez_sdk/model/token.dart';
import 'package:hermez_sdk/model/tokens_response.dart';
import 'package:hermez_sdk/tx.dart' as tx;
import 'package:hermez_sdk/utils.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _response = '(please, wait)';

  /*static const EXAMPLES_WEB3_CHAIN_ID = 4;
  static const EXAMPLES_WEB3_URL = 'https://rinkeby.infura.io/v3/';
  static const EXAMPLES_WEB3_RDP_URL = 'wss://rinkeby.infura.io/v3/';*/
  static const EXAMPLES_WEB3_API_KEY = 'e2d8687b60b944d58adc96485cbab18c';
  /*static const EXAMPLES_HERMEZ_API_URL = 'https://api.testnet.hermez.io';
  static const EXAMPLES_HERMEZ_EXPLORER_URL =
      'https://explorer.testnet.hermez.io';
  static const EXAMPLES_HERMEZ_CONTRACT_ADDRESS =
      '0x679b11E0229959C1D3D27C9d20529E4C5DF7997c';
  static const EXAMPLES_HERMEZ_WDELAYER_ADDRESS =
      '0xeFD96CFBaF1B0Dd24d3882B0D6b8D95F85634724';*/
  static const EXAMPLES_PRIVATE_KEY1 =
      '0x21a5e7321d0e2f3ca1cc6504396e6594a2211544b08c206847cdee96f832421a';
  static const EXAMPLES_PRIVATE_KEY2 =
      '0x3a9270c05ac169097808da4b02e8f9146be0f8a38cfad3dcfc0b398076381fdd';
  static const EXAMPLES_PRIVATE_KEY3 =
      '0x3d228fed4dc371f56b8f82f66ff17cd6bf1da7806d7eabb21810313dee819a53';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    //getHermezSupportedTokens();
    //createHermezWallets();
    //moveTokensFromEthereumToHermez();
    //getTokenBalance();
    //moveTokensFromHermezToEthereumStep1Exit();
    //moveTokensFromHermezToEthereumStep1ForceExit();
    //moveTokensFromHermezToEthereumStep2Withdraw();
    //createAccountAuthorization();
    //createInternalAccount();
  }

  void initPlatformState() {
    HermezSDK.init("rinkeby", web3ApiKey: EXAMPLES_WEB3_API_KEY);

    /*
    // customized init
    HermezSDK.init(
      'custom',
      envParams: EnvParams(
          EXAMPLES_WEB3_CHAIN_ID,
          {
            ContractName.hermez: EXAMPLES_HERMEZ_ROLLUP_ADDRESS, // Hermez
            ContractName.withdrawalDelayer:
                EXAMPLES_HERMEZ_WDELAYER_ADDRESS, // WithdrawalDeFlayer
          },
          EXAMPLES_HERMEZ_API_URL,
          EXAMPLES_HERMEZ_EXPLORER_URL,
          EXAMPLES_WEB3_URL + EXAMPLES_WEB3_API_KEY,
          EXAMPLES_WEB3_RDP_URL + EXAMPLES_WEB3_API_KEY),
    );*/
  }

  void getHermezSupportedTokens() async {
    TokensResponse tokenResponse = await coordinatorApi.getTokens();
    Token tokenERC20 = tokenResponse.tokens[0];
    setState(() {
      _response = tokenERC20.toJson().toString();
    });
  }

  void createHermezWallets() async {
    // load first account
    final wallet =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY1);
    //final HermezWallet hermezWallet = wallet[0];
    final String hermezEthereumAddress = wallet[1];

    // load second account
    final wallet2 =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY2);
    //final HermezWallet hermezWallet2 = wallet2[0];
    final String hermezEthereumAddress2 = wallet2[1];

    setState(() {
      _response = 'hermez ethereum address 1: ' +
          hermezEthereumAddress +
          '\n'
              'Hermez ethereum address 2: ' +
          hermezEthereumAddress2;
    });
  }

  void moveTokensFromEthereumToHermez() async {
    await Future.delayed(Duration(seconds: 2));
    // load ethereum token
    TokensResponse tokenResponse = await coordinatorApi.getTokens();
    Token tokenERC20 = tokenResponse.tokens[0];

    // load first account
    final wallet =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY1);
    final HermezWallet hermezWallet = wallet[0];
    final String hermezEthereumAddress = wallet[1];

    // set amount to transfer
    final amount = 0.0001;
    final amountDeposit = getTokenAmountBigInt(amount, tokenERC20.decimals);
    final compressedDepositAmount =
        HermezCompressedAmount.compressAmount(amountDeposit.toDouble());

    // perform deposit account 1
    String txHash = await tx.deposit(
        compressedDepositAmount,
        hermezEthereumAddress,
        tokenERC20,
        hermezWallet.publicKeyCompressedHex,
        EXAMPLES_PRIVATE_KEY1);

    setState(() {
      _response = txHash;
    });
  }

  void getTokenBalance() async {
    // load ethereum token
    TokensResponse tokenResponse = await coordinatorApi.getTokens();
    Token tokenERC20 = tokenResponse.tokens[0];

    // load first account
    final wallet =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY1);
    //final HermezWallet hermezWallet = wallet[0];
    final String hermezEthereumAddress = wallet[1];

    // load second account
    final wallet2 =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY2);
    //final HermezWallet hermezWallet2 = wallet2[0];
    final String hermezEthereumAddress2 = wallet2[1];

    // get sender account information
    final accountSenderResponse = await coordinatorApi
        .getAccounts(hermezEthereumAddress, [tokenERC20.id]);
    final infoAccountSender = accountSenderResponse.accounts.length > 0
        ? accountSenderResponse.accounts[0]
        : null;

    // get receiver account information
    final accountReceiverResponse = await coordinatorApi
        .getAccounts(hermezEthereumAddress2, [tokenERC20.id]);
    final infoAccountReceiver = accountReceiverResponse.accounts.length > 0
        ? accountReceiverResponse.accounts[0]
        : null;

    if (infoAccountSender != null) {
      //final account1ByIdx =
      //    coordinatorApi.getAccount(infoAccountSender.accountIndex);
    }

    if (infoAccountReceiver != null) {
      //final account2ByIdx =
      //    coordinatorApi.getAccount(infoAccountReceiver.accountIndex);
    }

    setState(() {
      _response = 'account 1 balance: ' +
          (infoAccountSender != null ? infoAccountSender.balance : '0') +
          '\n'
              'account 2 balance: ' +
          (infoAccountReceiver != null ? infoAccountReceiver.balance : '0');
    });
  }

  void moveTokensFromHermezToEthereumStep1Exit() async {
    // load ethereum token
    TokensResponse tokenResponse = await coordinatorApi.getTokens();
    Token tokenERC20 = tokenResponse.tokens[0];

    // load first account
    final wallet =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY1);
    final HermezWallet hermezWallet = wallet[0];
    final String hermezEthereumAddress = wallet[1];

    // get sender account information
    final accountSenderResponse = await coordinatorApi
        .getAccounts(hermezEthereumAddress, [tokenERC20.id]);
    final infoAccountSender = accountSenderResponse.accounts.length > 0
        ? accountSenderResponse.accounts[0]
        : null;

    // set amount to exit
    final amount = 0.0001;
    final amountExit = getTokenAmountBigInt(amount, tokenERC20.decimals);
    final compressedExitAmount =
        HermezCompressedAmount.compressAmount(amountExit.toDouble());

    // set fee in transaction
    final state = await coordinatorApi.getState();
    final userFee = state.recommendedFee.existingAccount;

    // generate L2 transaction
    final l2ExitTx = {
      'type': 'Exit',
      'from': infoAccountSender.accountIndex,
      'amount': compressedExitAmount,
      'fee': userFee
    };

    final exitResponse = await tx.generateAndSendL2Tx(
        l2ExitTx, hermezWallet, infoAccountSender.token);

    //final txExitPool =
    //    await coordinatorApi.getPoolTransaction(exitResponse['id']);

    //final txExitConf =
    //    await coordinatorApi.getHistoryTransaction(txExitPool.id);

    setState(() {
      _response = exitResponse.toString();
    });
  }

  void moveTokensFromHermezToEthereumStep1ForceExit() async {
    // load ethereum token
    TokensResponse tokenResponse = await coordinatorApi.getTokens();
    Token tokenERC20 = tokenResponse.tokens[0];

    // load first account
    final wallet =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY1);
    //final HermezWallet hermezWallet = wallet[0];
    final String hermezEthereumAddress = wallet[1];

    // get sender account information
    final accountSenderResponse = await coordinatorApi
        .getAccounts(hermezEthereumAddress, [tokenERC20.id]);
    final infoAccountSender = accountSenderResponse.accounts.length > 0
        ? accountSenderResponse.accounts[0]
        : null;

    // set amount to force exit
    final amount = 0.0001;
    final amountForceExit = getTokenAmountBigInt(amount, tokenERC20.decimals);
    final compressedForceExitAmount =
        HermezCompressedAmount.compressAmount(amountForceExit.toDouble());

    String txHash = await tx.forceExit(compressedForceExitAmount,
        infoAccountSender.accountIndex, tokenERC20, EXAMPLES_PRIVATE_KEY1);

    setState(() {
      _response = txHash;
    });
  }

  void moveTokensFromHermezToEthereumStep2Withdraw() async {
    // load ethereum token
    TokensResponse tokenResponse = await coordinatorApi.getTokens();
    Token tokenERC20 = tokenResponse.tokens[0];

    // load first account
    final wallet =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY1);
    final HermezWallet hermezWallet = wallet[0];
    final String hermezEthereumAddress = wallet[1];

    final exitInfoN = (await coordinatorApi.getExits(
            hermezEthereumAddress, true, tokenERC20.id))
        .exits;

    if (exitInfoN != null && exitInfoN.length > 0) {
      final exitInfo = exitInfoN.last;
      // set to perform instant withdraw
      final isInstant = true;

      String txHash = await tx.withdraw(
          double.parse(exitInfo.balance),
          exitInfo.accountIndex,
          exitInfo.token,
          hermezWallet.publicKeyCompressedHex,
          exitInfo.batchNum,
          exitInfo.merkleProof.siblings,
          EXAMPLES_PRIVATE_KEY1,
          isInstant: isInstant);

      setState(() {
        _response = txHash;
      });
    }
  }

  void createAccountAuthorization() async {
    // load ethereum token
    TokensResponse tokenResponse = await coordinatorApi.getTokens();
    Token tokenERC20 = tokenResponse.tokens[0];

    // load first account
    final wallet =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY1);
    final HermezWallet hermezWallet = wallet[0];
    final String hermezEthereumAddress = wallet[1];

    // get sender account information
    final accountSenderResponse = await coordinatorApi
        .getAccounts(hermezEthereumAddress, [tokenERC20.id]);
    final infoAccountSender = accountSenderResponse.accounts.length > 0
        ? accountSenderResponse.accounts[0]
        : null;

    // load third account
    final wallet3 =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY3);
    final HermezWallet hermezWallet3 = wallet3[0];
    //final String hermezEthereumAddress3 = wallet3[1];

    final signature = await hermezWallet3
        .signCreateAccountAuthorization(EXAMPLES_PRIVATE_KEY3);
    await coordinatorApi.postCreateAccountAuthorization(
        hermezWallet3.hermezEthereumAddress,
        hermezWallet3.publicKeyBase64,
        signature);

    await coordinatorApi
        .getCreateAccountAuthorization(hermezWallet3.hermezEthereumAddress);

    // set amount to transfer
    final amount = 0.0001;
    final amountTransfer = getTokenAmountBigInt(amount, tokenERC20.decimals);
    final compressedTransferAmount =
        HermezCompressedAmount.compressAmount(amountTransfer.toDouble());

    // fee computation
    final state = await coordinatorApi.getState();
    final fees = state.recommendedFee;
    final usdTokenExchangeRate = tokenERC20.USD;
    final fee = fees.createAccount / usdTokenExchangeRate;

    // generate L2 transaction
    final l2TransferTx = {
      "from": infoAccountSender.accountIndex,
      "to": hermezWallet3.hermezEthereumAddress,
      "amount": compressedTransferAmount,
      "fee": fee
    };

    final transferResponse = await tx.generateAndSendL2Tx(
        l2TransferTx, hermezWallet, infoAccountSender.token);

    setState(() {
      _response = transferResponse.toString();
    });
  }

  void createInternalAccount() async {
    // load ethereum token
    TokensResponse tokenResponse = await coordinatorApi.getTokens();
    Token tokenERC20 = tokenResponse.tokens[0];

    // load first account
    final wallet =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY1);
    //final HermezWallet hermezWallet = wallet[0];
    final String hermezEthereumAddress = wallet[1];

    // get sender account information
    final accountSenderResponse = await coordinatorApi
        .getAccounts(hermezEthereumAddress, [tokenERC20.id]);
    final infoAccountSender = accountSenderResponse.accounts.length > 0
        ? accountSenderResponse.accounts[0]
        : null;

    // Create Internal Account
    // create new bjj private key to receive user transactions
    final Uint8List pvtBjjKey = Uint8List(32);
    pvtBjjKey.fillRange(0, 32, 1);

    // create rollup internal account from bjj private key
    final wallet4 = await HermezWallet.createWalletFromBjjPvtKey(pvtBjjKey);
    final hermezWallet4 = wallet4[0];

    // fee computation
    final state = await coordinatorApi.getState();
    final fees = state.recommendedFee;
    final usdTokenExchangeRate = tokenERC20.USD;
    final fee = fees.createAccountInternal / usdTokenExchangeRate;

    // set amount to transfer
    final amount = 0.0001;
    final amountTransferInternal =
        getTokenAmountBigInt(amount, tokenERC20.decimals);
    final compressedTransferInternalAmount =
        HermezCompressedAmount.compressAmount(
            amountTransferInternal.toDouble());

    // generate L2 transaction
    final transferToInternal = {
      'from': infoAccountSender.accountIndex,
      'to': hermezWallet4.publicKeyBase64,
      'amount': compressedTransferInternalAmount,
      'fee': fee
    };

    final internalAccountResponse = await tx.generateAndSendL2Tx(
        transferToInternal, hermezWallet4, tokenERC20);

    setState(() {
      _response = internalAccountResponse.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Hermez SDK Example'),
        ),
        body: Center(
          child: Text(
            'Response:\n$_response\n',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
