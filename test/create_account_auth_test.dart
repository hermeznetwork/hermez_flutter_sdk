import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/api.dart';
import 'package:hermez_plugin/hermez_wallet.dart';
import 'package:hermez_plugin/tx.dart';
import 'package:hermez_plugin/utils.dart';
import 'package:hermez_plugin/utils/uint8_list_utils.dart';
import 'package:web3dart/crypto.dart';

import 'setup_util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('Check keccak256', () async {
    final expectedResult =
        "0x9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658";
    final messageArray = Uint8ArrayUtils.uint8ListfromString('test');
    final keccakBuf = keccak256(messageArray);
    final keccak = Uint8ArrayUtils.beBuff2int(keccakBuf).toRadixString(16);
    final keccakHex = keccak.startsWith('0x') ? keccak : '0x$keccak';
    expect(keccakHex, expectedResult);
  });

  test('create account authorization', () async {
    final privKey1 = EXAMPLES_PRIVATE_KEY1;
    final privKey2 = EXAMPLES_PRIVATE_KEY2;

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

    // performs create account authorization account 2
    /*final signature = await hermezWallet2.signCreateAccountAuthorization(
        getProvider(EXAMPLES_WEB3_URL, EXAMPLES_WEB3_RDP_URL), privKey1);*/
    final response = await postCreateAccountAuthorization(
        hermezWallet2.hermezEthereumAddress, hermezWallet2.publicKeyBase64, "");
    //signature);
    print('create account authorization response:${response.statusCode}');

    // get sender account information
    final infoAccountSender =
        (await getAccounts(hermezEthereumAddress, [tokenERC20.id])).accounts[0];

    // set amount to transfer
    final amountTransfer = getTokenAmountBigInt(0.0001, 18);
    // set fee in transaction
    final state = await getState();
    final recommendedFee = state.recommendedFee;

    // generate L2 transaction
    final l2TxTransfer = {
      'from': infoAccountSender.accountIndex,
      'to': hermezEthereumAddress2,
      'amount': amountTransfer,
      'fee': recommendedFee.createAccount
    };

    final transferResponse = await generateAndSendL2Tx(
        l2TxTransfer, hermezWallet, infoAccountSender.token);
    print('transferResponse: $transferResponse');
    //expect(nativeGreeting("John Smith"), 'Hello John Smith');
  });
}
