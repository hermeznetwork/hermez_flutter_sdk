import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/api.dart';
import 'package:hermez_plugin/hermez_wallet.dart';
import 'package:hermez_plugin/providers.dart';
import 'package:hermez_plugin/tx.dart';

import 'setup_util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('withdrawal', () async {
    final privKey1 = EXAMPLES_PRIVATE_KEY1;

    // load token to deposit information
    final tokenToDeposit = 0;
    final token = await getTokens();
    final tokenERC20 = token.tokens[tokenToDeposit];

    // load first account
    final wallet = await HermezWallet.createWalletFromPrivateKey(privKey1);
    final HermezWallet hermezWallet = wallet[0]; // hermezWallet
    final String hermezEthereumAddress = wallet[1]; // hermezEthereumAddress

    // get account information
    final infoAccount =
        (await getAccounts(hermezEthereumAddress, [tokenERC20.id])).accounts[0];

    final exitInfoN =
        (await getExits(infoAccount.hezEthereumAddress, true)).exits;
    if (exitInfoN.length > 0) {
      final exitInfo = exitInfoN[exitInfoN.length - 1];
      // set to perform instant withdraw
      final isInstant = true;

      // perform withdraw
      withdraw(
          BigInt.parse(exitInfo.balance),
          exitInfo.accountIndex,
          exitInfo.token,
          null,
          /*hermezWallet.publicKeyCompressedHex,*/
          BigInt.from(exitInfo.batchNum),
          exitInfo.merkleProof.siblings,
          getProvider(EXAMPLES_WEB3_URL, EXAMPLES_WEB3_RDP_URL),
          isInstant: isInstant);
    }
    //expect(nativeGreeting("John Smith"), 'Hello John Smith');
  });
}
