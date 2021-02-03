import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/api.dart';
import 'package:hermez_plugin/hermez_plugin.dart';
import 'package:hermez_plugin/hermez_wallet.dart';
import 'package:hermez_plugin/tx.dart';
import 'package:hermez_plugin/utils.dart';

import 'setup_util.dart';

void main() {
  const MethodChannel channel = MethodChannel('hermez_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await HermezPlugin.platformVersion, '42');
  });

  test('transfer', () async {
    final privKey1 = EXAMPLES_PRIVATE_KEY1;
    final privKey2 = EXAMPLES_PRIVATE_KEY2;

    // load token to deposit information
    final tokenToDeposit = 0;
    final token = await getTokens(tokenIds: [3, 87, 91]);
    final tokenERC20 = token.tokens[tokenToDeposit];

    // load first account
    final List wallet = await HermezWallet.createWalletFromEtherAccount(
        EXAMPLES_WEB3_URL, privKey1);
    final HermezWallet hermezWallet = wallet[0]; // hermezWallet
    final String hermezEthereumAddress = wallet[1]; // hermezEthereumAddress

    // load second account
    final List wallet2 = await HermezWallet.createWalletFromEtherAccount(
        EXAMPLES_WEB3_URL, privKey2);
    final HermezWallet hermezWallet2 = wallet2[0]; // hermezWallet
    final String hermezEthereumAddress2 = wallet2[1]; // hermezEthereumAddress

    // get sender account information
    final infoAccountSender =
        (await getAccounts(hermezEthereumAddress, [tokenERC20.id])).accounts[0];

    // get receiver account information
    final infoAccountReceiver =
        (await getAccounts(hermezEthereumAddress2, [tokenERC20.id]))
            .accounts[0];

    // set amount to transfer
    final amountTransfer = getTokenAmountBigInt(0.0001, 18);
    // set fee in transaction
    final userFee = 0;

    // generate L2 transaction
    final Map l2TxTransfer = {
      'type': 'Transfer',
      'from': infoAccountSender.accountIndex,
      'to': infoAccountReceiver.accountIndex,
      'amount': amountTransfer,
      'fee': userFee
    };

    final transferResponse = await generateAndSendL2Tx(
        l2TxTransfer, hermezWallet, infoAccountSender.token);
    print(transferResponse);
    //expect(nativeGreeting("John Smith"), 'Hello John Smith');
  });
}
