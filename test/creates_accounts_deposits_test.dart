import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_sdk/api.dart';
import 'package:hermez_sdk/hermez_wallet.dart';
import 'package:hermez_sdk/utils.dart';

import 'setup_util.dart';

void main() {
  test('creates accounts deposits', () async {
    final privKey1 = EXAMPLES_PRIVATE_KEY1;
    final privKey2 = EXAMPLES_PRIVATE_KEY2;

    // initialize transaction pool
    //initializeTransactionPool();

    // setProvider(EXAMPLES_WEB3_URL, EXAMPLES_WEB3_RDP_URL);

    // load token to deposit information
    final tokenToDeposit = 0;
    final token = await getTokens();
    final tokenERC20 = token.tokens[tokenToDeposit];

    // load first account
    final wallet = await HermezWallet.createWalletFromPrivateKey(privKey1);
    final HermezWallet hermezWallet = wallet[0]; // hermezWallet
    final String hermezEthereumAddress = wallet[1]; // hermezEthereumAddress

    // load second account
    final List wallet2 =
        await HermezWallet.createWalletFromPrivateKey(privKey2);
    final HermezWallet hermezWallet2 = wallet2[0]; // hermezWallet
    final String hermezEthereumAddress2 = wallet2[1]; // hermezEthereumAddress

    // set amount to transfer
    final amountDeposit = getTokenAmountBigInt(0.1, 18);

    // perform deposit account 1
    /*await deposit(
        amountDeposit,
        hermezEthereumAddress,
        tokenERC20,
        hermezWallet.publicKeyCompressedHex,
        getProvider(EXAMPLES_WEB3_URL, EXAMPLES_WEB3_RDP_URL));*/

    // perform deposit account 2
    /*await deposit(
        amountDeposit,
        hermezEthereumAddress2,
        tokenERC20,
        hermezWallet2.publicKeyCompressedHex,
        getProvider(EXAMPLES_WEB3_URL, EXAMPLES_WEB3_RDP_URL));*/
    //expect(nativeGreeting("John Smith"), 'Hello John Smith');
  });
}
