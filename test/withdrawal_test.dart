import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_sdk/api.dart';
import 'package:hermez_sdk/hermez_wallet.dart';
import 'package:hermez_sdk/tx.dart';

import 'setup_util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('withdrawal', () async {
    final privKey1 = EXAMPLES_PRIVATE_KEY1;

    // load token to deposit information
    final tokenToDeposit = 0;
    final token = await getTokens();
    final tokenERC20 = token.tokens![tokenToDeposit];

    // load first account
    final wallet = await HermezWallet.createWalletFromPrivateKey(privKey1);
    final HermezWallet hermezWallet = wallet[0]; // hermezWallet
    final String hermezEthereumAddress = wallet[1]; // hermezEthereumAddress

    // get account information
    final infoAccount =
        (await getAccounts(hermezEthereumAddress, [tokenERC20.id]))
            .accounts![0];

    final exitInfoN =
        (await getExits(infoAccount.hezEthereumAddress!, true, tokenERC20.id!))
            .exits!;
    if (exitInfoN.length > 0) {
      final exitInfo = exitInfoN[exitInfoN.length - 1];
      // set to perform instant withdraw
      final isInstant = true;

      // perform withdraw
      final txHash = withdraw(
          double.parse(exitInfo.balance!),
          exitInfo.accountIndex,
          exitInfo.token!,
          hermezWallet.publicKeyCompressedHex!,
          exitInfo.batchNum!,
          exitInfo.merkleProof!.siblings!,
          privKey1,
          isInstant: isInstant);
      expect(txHash, '0x');
    }
    //expect(nativeGreeting("John Smith"), 'Hello John Smith');
  });
}
