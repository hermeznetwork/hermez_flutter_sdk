import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/api.dart';
import 'package:hermez_plugin/hermez_compressed_amount.dart';
import 'package:hermez_plugin/hermez_wallet.dart';
import 'package:hermez_plugin/tx.dart';
import 'package:hermez_plugin/utils.dart';

import 'setup_util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('force_exit', () async {
    // getProvider(EXAMPLES_WEB3_URL, EXAMPLES_WEB3_RDP_URL)
    final privKey1 = EXAMPLES_PRIVATE_KEY1;

    // load token to deposit information
    final tokenToDeposit = 0;
    final token = await getTokens();
    final tokenERC20 = token.tokens[tokenToDeposit];

    // load first account
    final wallet = await HermezWallet.createWalletFromPrivateKey(privKey1);
    final String hermezEthereumAddress = wallet[1]; // hermezEthereumAddress

    // get account information
    final infoAccount =
        (await getAccounts(hermezEthereumAddress, [tokenERC20.id])).accounts[0];

    // set amount to force-exit
    final amountExit = getTokenAmountBigInt(0.0001, 18);

    final compressedAmount =
        HermezCompressedAmount.compressAmount(amountExit.toDouble());

    forceExit(compressedAmount, infoAccount.accountIndex, tokenERC20, privKey1);
    //expect(nativeGreeting("John Smith"), 'Hello John Smith');
  });
}
