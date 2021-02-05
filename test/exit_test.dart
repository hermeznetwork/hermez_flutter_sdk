import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/api.dart';
import 'package:hermez_plugin/hermez_wallet.dart';
import 'package:hermez_plugin/tx.dart';
import 'package:hermez_plugin/utils.dart';

import 'setup_util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('exit', () async {
    final privKey1 = EXAMPLES_PRIVATE_KEY1;

    // load token to deposit information
    final tokenToDeposit = 0;
    final token = await getTokens();
    final tokenERC20 = token.tokens[tokenToDeposit];

    // load first account
    final wallet = await HermezWallet.createWalletFromPrivateKey(privKey1);
    final HermezWallet hermezWallet = wallet[0]; // hermezWallet
    final String hermezEthereumAddress = wallet[1]; // hermezEthereumAddress

    // get sender account information
    final infoAccountSender =
        (await getAccounts(hermezEthereumAddress, [tokenERC20.id])).accounts[0];

    // set amount to transfer
    final amountExit = getTokenAmountBigInt(0.0001, 18);

    // set fee in transaction
    final userFee = 0;

    // generate L2 transaction
    final l2TxExit = {
      'type': 'Exit',
      'from': infoAccountSender.accountIndex,
      'amount': amountExit,
      'fee': userFee
    };

    final exitResponse = await generateAndSendL2Tx(
        l2TxExit, hermezWallet, infoAccountSender.token);
    print('exitResponse: $exitResponse');
    //expect(nativeGreeting("John Smith"), 'Hello John Smith');
  });
}
