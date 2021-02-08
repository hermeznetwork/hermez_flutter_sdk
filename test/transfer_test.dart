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

  test('transfer', () async {
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
    final l2TxTransfer = {
      'type': 'Transfer',
      'from': infoAccountSender.accountIndex,
      'to': infoAccountReceiver.accountIndex,
      'amount': amountTransfer,
      'fee': userFee
    };

    final transferResponse = await generateAndSendL2Tx(
        l2TxTransfer, hermezWallet, infoAccountSender.token);
    print('transferResponse: $transferResponse');
    //expect(nativeGreeting("John Smith"), 'Hello John Smith');
  });
}
