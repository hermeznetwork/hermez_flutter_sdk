# hermez_sdk

[![pub package](https://img.shields.io/badge/pub-1.0.0-orange)](https://pub.dev/packages/hermez_sdk)
[![build](https://github.com/hermeznetwork/hermez_flutter_sdk/workflows/hermez_sdk/badge.svg?branch=master)](https://github.com/hermeznetwork/hermez_flutter_sdk/actions?query=workflow%3Ahermez_sdk)
[![license](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://github.com/hermeznetwork/hermez_mobile_library/blob/master/LICENSE)

## Description

This is a flutter Plugin for Hermez Mobile SDK (https://hermez.io). This plugin provides a cross-platform tool (iOS, Android) to communicate with the Hermez API and network.

## Installation

To use this plugin, add `hermez_sdk` as a [dependency](https://flutter.io/using-packages/) in your `pubspec.yaml` file like this

```yaml
dependencies:
  hermez_sdk: ^x.y.z
```
This will get you the latest version.

If you want to test a specific branch of the repository, pull `hermez_sdk` like this

```yaml
dependencies:
  hermez_sdk:
      git:
        url: ssh://git@github.com/hermeznetwork/hermez-mobile-library.git
        ref: branchPathName
```

Also, add the abi contracts in json files to the assets folder of your project and to your `pubspec.yaml` file like this

```yaml
assets:
    - HermezABI.json
    - ERC20ABI.json
    - WithdrawalDelayerABI.json
```

## Setup

NOTE: In order to interact with Hermez, you will need to supply your own Ethereum node. You can check these links to help you set up a node (https://blog.infura.io/getting-started-with-infura-28e41844cc89, https://blog.infura.io/getting-started-with-infuras-ethereum-api).

## Usage

To start using this package first import it in your Dart file.

```dart
import 'package:hermez_sdk/hermez_sdk.dart';
```

### Initialization

To initialize the Hermez SDK you can call the init method with one of the supported environments as a parameter, or setup all the different parameters passing the environment 'custom'.

```dart
HermezSDK.init(
  'rinkeby',
   web3ApiKey: EXAMPLES_WEB3_API_KEY
);
```

or 

```dart
HermezSDK.init(
  'custom',
  envParams: EnvParams(
      EXAMPLES_WEB3_CHAIN_ID,
      {
        ContractName.hermez: EXAMPLES_HERMEZ_ROLLUP_ADDRESS, // Hermez
        ContractName.withdrawalDelayer:
            EXAMPLES_HERMEZ_WDELAYER_ADDRESS, // WithdrawalDelayer
      },
      EXAMPLES_HERMEZ_API_URL,
      EXAMPLES_HERMEZ_EXPLORER_URL,
      EXAMPLES_WEB3_URL + EXAMPLES_WEB3_API_KEY,
      EXAMPLES_WEB3_RDP_URL + EXAMPLES_WEB3_API_KEY),
);
```

### Supported Tokens

Before being able to operate on the Hermez Network, we must ensure that the token we want to operate with is listed. For that we make a call to the Hermez Coordinator API that will list all available tokens. All tokens in Hermez Network must be ERC20.

We can see there are 2 tokens registered. ETH will always be configured at index 0. The second token is HEZ. For the rest of the examples we will work with ETH. In the future, more tokens will be included in Hermez.

```dart
import 'package:hermez_sdk/api.dart' as coordinatorApi;
import 'package:hermez_sdk/model/tokens_response.dart';

...

Future<TokensResponse> getHermezSupportedTokens() async {
  TokensResponse tokensResponse = await coordinatorApi.getTokens();
  return tokensResponse;
}
```

```json
{
  "tokens": [
    {
      "itemId": 1,
      "id": 0,
      "ethereumBlockNum": 0,
      "ethereumAddress": "0x0000000000000000000000000000000000000000",
      "name": "Ether",
      "symbol": "ETH",
      "decimals": 18,
      "USD": 1787,
      "fiatUpdate": "2021-02-28T18:55:17.372008Z"
    },
    {
      "itemId": 2,
      "id": 1,
      "ethereumBlockNum": 8153596,
      "ethereumAddress": "0x2521bc90b4f5fb9a8d61278197e5ff5cdbc4fbf2",
      "name": "Hermez Network Token",
      "symbol": "HEZ",
      "decimals": 18,
      "USD": 5.365,
      "fiatUpdate": "2021-02-28T18:55:17.386805Z"
    }
  ],
  "pendingItems": 0
}
```

### Create Wallet

We can create a new Hermez wallet by providing the Ethereum private key of an Ethereum account. This wallet will store the Ethereum and Baby JubJub keys for the Hermez account. The Ethereum address is used to authorize L1 transactions, and the Baby JubJub key is used to authorize L2 transactions. We will create two wallets.

> [!NOTE]
> You will need to supply two private keys to test and initialize both accounts. The keys provided here are invalid and are shown as an example.

```dart
import 'package:hermez_sdk/hermez_wallet.dart';

...

void createHermezWallets() async {
    // load first account
    final wallet =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY1);
    final HermezWallet hermezWallet = wallet[0];
    final String hermezEthereumAddress = wallet[1];

    // load second account
    final wallet2 =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY2);
    final HermezWallet hermezWallet2 = wallet2[0];
    final String hermezEthereumAddress2 = wallet2[1];
}
```

### Move tokens from Ethereum to Hermez Network

Creating a Hermez account and depositing tokens is done simultaneously as an L1 transaction. In this example we are going to deposit 1 ETH tokens into the newly created Hermez accounts.

```dart
import 'package:hermez_sdk/tx.dart' as tx;
import 'package:hermez_sdk/utils.dart';
import 'package:hermez_sdk/hermez_compressed_amount.dart';

...

void moveTokensFromEthereumToHermez() async {
 
    // load  account and ethereum token

    ...

    // set amount to transfer
    final amount = 1.0;
    final amountDeposit = getTokenAmountBigInt(amount, tokenERC20.decimals);
    final compressedDepositAmount =
        HermezCompressedAmount.compressAmount(amountDeposit.toDouble());

    // perform deposit account 1
    String txHash = await tx.deposit(compressedDepositAmount, hermezEthereumAddress, tokenERC20,
        hermezWallet.publicKeyCompressedHex, EXAMPLES_PRIVATE_KEY1);
}
```

### Token Balance

A token balance can be obtained by querying the API and passing the hermezEthereumAddress of the Hermez account.

```dart
void getTokenBalance() async {

    // load  accounts and ethereum token
    
    ...

    // get sender account information
    final infoAccountSender = (await coordinatorApi
            .getAccounts(hermezEthereumAddress, [tokenERC20.id]))
        .accounts[0];

    // get receiver account information
    final infoAccountReceiver = (await coordinatorApi
            .getAccounts(hermezEthereumAddress2, [tokenERC20.id]))
        .accounts[0];
}
```

```json
[
  {
    "accountIndex": "hez:ETH:4253",
    "balance": "1099600000000000000",
    "bjj": "hez:dMfPJlK_UtFqVByhP3FpvykOg5kAU3jMLD7OTx_4gwzO",
    "hezEthereumAddress": "hez:0x74d5531A3400f9b9d63729bA9C0E5172Ab0FD0f6",
    "itemId": 4342,
    "nonce": 1,
    "token": {
      "USD": 1789,
      "decimals": 18,
      "ethereumAddress": "0x0000000000000000000000000000000000000000",
      "ethereumBlockNum": 0,
      "fiatUpdate": "2021-02-28T18:55:17.372008Z",
      "id": 0,
      "itemId": 1,
      "name": "Ether",
      "symbol": "ETH"
    }
  },
  {
    "accountIndex": "hez:ETH:4254",
    "balance": "1097100000000000000",
    "bjj": "hez:HESLP_6Kp_nn5ANmSGiOnhhYvF3wF5Davf7xGi6lwh3U",
    "hezEthereumAddress": "hez:0x12FfCe7D5d6d09564768d0FFC0774218458162d4",
    "itemId": 4343,
    "nonce": 6,
    "token": {
      "USD": 1789,
      "decimals": 18,
      "ethereumAddress": "0x0000000000000000000000000000000000000000",
      "ethereumBlockNum": 0,
      "fiatUpdate": "2021-02-28T18:55:17.372008Z",
      "id": 0,
      "itemId": 1,
      "name": "Ether",
      "symbol": "ETH"
    }
  }
]
```

We can see that the field accountIndex is formed by the token symbol it holds and an index. A Hermez account can only hold one type of token. Account indexes start at 256. Indexes 0-255 are reserved for internal use. Note that the balances do not match with the ammount deposited of 1 ETH because accounts already existed in Hermez Network before the deposit, so we performed a deposit on top instead.

Alternatively, an account query can be filtered using the assigned accountIndex

```dart
    final account1ByIdx = coordinatorApi.getAccount(infoAccountSender.accountIndex);

    final account2ByIdx = coordinatorApi.getAccount(infoAccountReceiver.accountIndex);

```

```json
[
  {
    "accountIndex": "hez:ETH:4253",
    "balance": "1099600000000000000",
    "bjj": "hez:dMfPJlK_UtFqVByhP3FpvykOg5kAU3jMLD7OTx_4gwzO",
    "hezEthereumAddress": "hez:0x74d5531A3400f9b9d63729bA9C0E5172Ab0FD0f6",
    "itemId": 4342,
    "nonce": 1,
    "token": {
      "USD": 1789,
      "decimals": 18,
      "ethereumAddress": "0x0000000000000000000000000000000000000000",
      "ethereumBlockNum": 0,
      "fiatUpdate": "2021-02-28T18:55:17.372008Z",
      "id": 0,
      "itemId": 1,
      "name": "Ether",
      "symbol": "ETH"
    }
  },
  {
    "accountIndex": "hez:ETH:4254",
    "balance": "1097100000000000000",
    "bjj": "hez:HESLP_6Kp_nn5ANmSGiOnhhYvF3wF5Davf7xGi6lwh3U",
    "hezEthereumAddress": "hez:0x12FfCe7D5d6d09564768d0FFC0774218458162d4",
    "itemId": 4343,
    "nonce": 6,
    "token": {
      "USD": 1789,
      "decimals": 18,
      "ethereumAddress": "0x0000000000000000000000000000000000000000",
      "ethereumBlockNum": 0,
      "fiatUpdate": "2021-02-28T18:55:17.372008Z",
      "id": 0,
      "itemId": 1,
      "name": "Ether",
      "symbol": "ETH"
    }
  }
]
```

### Move tokens from Hermez to Ethereum Network

Withdrawing funds is a two step process:

1. Exit
2. Withdrawal

#### Exit

The Exit transaction is used as a first step to retrieve the funds from Hermez Network back to Ethereum. There are two types of Exit transactions:

- Normal Exit, referred as Exit from now on. This is a L2 transaction type.
- Force Exit, an L1 transaction type which has extended guarantees that will be processed by the Coordinator. We will talk more about Force Exit here
    
The Exit is requested as follows:

```dart
void moveTokensFromHermezToEthereumStep1Exit() async {
    // load account

    ...
    
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

    final exitResponse = await tx.generateAndSendL2Tx(l2ExitTx, hermezWallet, infoAccountSender.token);
  }
```

```json
{
  "status": 200,
  "id": "0x0257305cdc43060a754a5c2ea6b0e0f6e28735ea8e75d841ca4a7377aa099d91b7",
  "nonce": 2
}
```

After submitting our Exit request to the Coordinator, we can check the status of the transaction by calling the Coordinator's Transaction Pool. The Coordinator's transaction pool stores all those transactions that are waiting to be forged.

```dart
final txExitPool = await coordinatorApi.getPoolTransaction(exitResponse['id']);
```

```json
{
  "amount": "1000000000000000000",
  "fee": 204,
  "fromAccountIndex": "hez:ETH:4253",
  "fromBJJ": "hez:dMfPJlK_UtFqVByhP3FpvykOg5kAU3jMLD7OTx_4gwzO",
  "fromHezEthereumAddress": "hez:0x74d5531A3400f9b9d63729bA9C0E5172Ab0FD0f6",
  "id": "0x0257305cdc43060a754a5c2ea6b0e0f6e28735ea8e75d841ca4a7377aa099d91b7",
  "info": null,
  "nonce": 2,
  "requestAmount": null,
  "requestFee": null,
  "requestFromAccountIndex": null,
  "requestNonce": null,
  "requestToAccountIndex": null,
  "requestToBJJ": null,
  "requestToHezEthereumAddress": null,
  "requestTokenId": null,
  "signature": "38f23d06826be8ea5a0893ee67f4ede885a831523c0c626c102edb05e1cf890e418b5820e3e6d4b530386d0bc84b3c3933d655527993ad77a55bb735d5a67c03",
  "state": "pend",
  "timestamp": "2021-03-16T12:31:50.407428Z",
  "toAccountIndex": "hez:ETH:1",
  "toBjj": null,
  "toHezEthereumAddress": null,
  "token": {
    "USD": 1781.9,
    "decimals": 18,
    "ethereumAddress": "0x0000000000000000000000000000000000000000",
    "ethereumBlockNum": 0,
    "fiatUpdate": "2021-02-28T18:55:17.372008Z",
    "id": 0,
    "itemId": 1,
    "name": "Ether",
    "symbol": "ETH"
  },
  "type": "Exit"
}
```

We can see the state field is set to pend (meaning pending). There are 4 possible states:

1. pend : Pending
2. fging : Forging
3. fged : Forged
4. invl : Invalid
    
If we continue polling the Coordinator about the status of the transaction, the state will eventually be set to fged.

We can also query the Coordinator to check whether or not our transaction has been forged. getHistoryTransaction reports those transactions that have been forged by the Coordinator.

```dart
final txExitConf = await coordinatorApi.getHistoryTransaction(txExitPool.id);
```

And we can confirm our account status and check that the correct amount has been transfered out of the account.

```dart
final accountResponse = await coordinatorApi.getAccounts(hermezEthereumAddress, [tokenERC20.id]);
final infoAccount = accountResponse.accounts.length > 0 ? accountResponse.accounts[0]: null;
```

#### Withdraw

After doing any type of Exit transaction, which moves the user's funds from their token account to a specific Exit Merkle tree, one needs to do a Withdraw of those funds to an Ethereum L1 account. To do a Withdraw we need to indicate the accountIndex that includes the Ethereum address where the funds will be transferred, the amount and type of tokens, and some information to verify the ownership of those tokens. Additionally, there is one boolean flag. If set to true, the Withdraw will be instantaneous.

```dart
void moveTokensFromHermezToEthereumStep2Withdraw() async {
    // load ethereum token and account

    ...

    final exitInfoN = (await coordinatorApi.getExits(
            hermezEthereumAddress, true, tokenERC20.id))
        .exits;

    if (exitInfoN != null && exitInfoN.length > 0) {
      final exitInfo = exitInfoN.last;
      // set to perform instant withdraw
      final isInstant = true;

      // perform withdraw
      tx.withdraw(
          double.parse(exitInfo.balance),
          exitInfo.accountIndex,
          exitInfo.token,
          hermezWallet.publicKeyCompressedHex,
          exitInfo.batchNum,
          exitInfo.merkleProof.siblings,
          EXAMPLES_PRIVATE_KEY1,
          isInstant: isInstant);
    }
}
```

The funds should now appear in the Ethereum account that made the withdrawal.

#### Force Exit

This is the L1 equivalent of an Exit. With this option, the smart contract forces Coordinators to pick up L1 transactions before they pick up L2 transactions to ensure that L1 transactions will eventually be picked up.

This is a security measure. We don't expect users to need to make a Force Exit.

```dart
void moveTokensFromHermezToEthereumStep1ForceExit() async {
    // load ethereum token and account info
    
    ...

    // set amount to force exit
    final amount = 0.0001;
    final amountForceExit = getTokenAmountBigInt(amount, tokenERC20.decimals);
    final compressedForceExitAmount =
        HermezCompressedAmount.compressAmount(amountForceExit.toDouble());

    // perform force exit
    tx.forceExit(compressedForceExitAmount, infoAccountSender.accountIndex,
        tokenERC20, EXAMPLES_PRIVATE_KEY1);
}
```

The last step to recover the funds will be to send a new Withdraw request to the smart contract as we did after the regular Exit request.

```dart
void moveTokensFromHermezToEthereumStep2Withdraw() async {
    // load ethereum token and account

    ...

    final exitInfoN = (await coordinatorApi.getExits(
            hermezEthereumAddress, true, tokenERC20.id))
        .exits;

    if (exitInfoN != null && exitInfoN.length > 0) {
      final exitInfo = exitInfoN.last;
      // set to perform instant withdraw
      final isInstant = true;

      // perform withdraw
      tx.withdraw(
          double.parse(exitInfo.balance),
          exitInfo.accountIndex,
          exitInfo.token,
          hermezWallet.publicKeyCompressedHex,
          exitInfo.batchNum,
          exitInfo.merkleProof.siblings,
          EXAMPLES_PRIVATE_KEY1,
          isInstant: isInstant);
    }
}
```

### Transfers

First, we compute the fees for the transaction. For this we consult the recommended fees from the Coordinator.

```dart
    // fee computation
    final state = await coordinatorApi.getState();
    final fees = state.recommendedFee;
```

```json
{
  "existingAccount": 96.34567219671051,
  "createAccount": 192.69134439342102,
  "createAccountInternal": 240.86418049177627
}
```

The returned fees are the suggested fees for different transactions:

- existingAccount : Make a transfer to an existing account
- createAccount : Make a transfer to a non-existent account, and create a regular account
- createAccountInternal : Make a transfer to an non-existent account and create internal account

The fee amounts are given in USD. However, fees are payed in the token of the transaction. So, we need to do a conversion.

```dart
    final usdTokenExchangeRate = tokenERC20.USD;
    final fee = fees.existingAccount / usdTokenExchangeRate;
```

Finally we make the final transfer transaction.

```dart
    // set amount to transfer
    final amount = 0.0001;
    final amountTransfer = getTokenAmountBigInt(amount, tokenERC20.decimals);
    final compressedTransferAmount =
            HermezCompressedAmount.compressAmount(amountTransfer.toDouble());
    // generate L2 transaction
    final l2TxTransfer = {
      from: infoAccountSender.accountIndex,
      to: infoAccountReceiver.accountIndex,
      amount: compressedTransferAmount,
      fee: fee
    };

    final transferResponse = await tx.generateAndSendL2Tx(l2TxTransfer, hermezWallet, infoAccountSender.token);
```

```json
{
  "status": 200,
  "id": "0x02e7c2c293173f21249058b1d71afd5b1f3c0de4f1a173bac9b9aa4a2d149483a2",
  "nonce": 3
}
```

The result status 200 shows that transaction has been correctly received. Additionally, we receive the nonce matching the transaction we sent, and an id that we can use to verify the status of the transaction either using getHistoryTransaction() or getPoolTransaction().

As we saw with the Exit transaction, every transaction includes a ´nonce´. This nonce is a protection mechanism to avoid replay attacks. Every L2 transaction will increase the nonce by 1.

### Transaction Status

Transactions received by the Coordinator will be stored in its transaction pool while they haven't been processed. To check a transaction in the transaction pool we make a query to the Coordinator node.

```dart
final txTransferPool = await coordinatorApi.getPoolTransaction(transferResponse['id']);
```

```json
{
  "amount": "100000000000000",
  "fee": 202,
  "fromAccountIndex": "hez:ETH:4253",
  "fromBJJ": "hez:dMfPJlK_UtFqVByhP3FpvykOg5kAU3jMLD7OTx_4gwzO",
  "fromHezEthereumAddress": "hez:0x74d5531A3400f9b9d63729bA9C0E5172Ab0FD0f6",
  "id": "0x02e7c2c293173f21249058b1d71afd5b1f3c0de4f1a173bac9b9aa4a2d149483a2",
  "info": null,
  "nonce": 3,
  "requestAmount": null,
  "requestFee": null,
  "requestFromAccountIndex": null,
  "requestNonce": null,
  "requestToAccountIndex": null,
  "requestToBJJ": null,
  "requestToHezEthereumAddress": null,
  "requestTokenId": null,
  "signature": "c9e1a61ce2c3c728c6ec970ae646b444a7ab9d30aa6015eb10fb729078c1302978fe9fb0419b4d944d4f11d83582043a48546dff7dda22de7c1e1da004cd5401",
  "state": "pend",
  "timestamp": "2021-03-16T13:20:33.336469Z",
  "toAccountIndex": "hez:ETH:4254",
  "toBjj": "hez:HESLP_6Kp_nn5ANmSGiOnhhYvF3wF5Davf7xGi6lwh3U",
  "toHezEthereumAddress": "hez:0x12FfCe7D5d6d09564768d0FFC0774218458162d4",
  "token": {
    "USD": 1786,
    "decimals": 18,
    "ethereumAddress": "0x0000000000000000000000000000000000000000",
    "ethereumBlockNum": 0,
    "fiatUpdate": "2021-02-28T18:55:17.372008Z",
    "id": 0,
    "itemId": 1,
    "name": "Ether",
    "symbol": "ETH"
  },
  "type": "Transfer"
}
```

We can also check directly with the Coordinator in the database of forged transactions.

```dart
final transferConf = await coordinatorApi.getHistoryTransaction(transferResponse['id']);
```

```json
{
  "L1Info": null,
  "L1orL2": "L2",
  "L2Info": { "fee": 202, "historicFeeUSD": 182.8352, "nonce": 3 },
  "amount": "100000000000000",
  "batchNum": 4724,
  "fromAccountIndex": "hez:ETH:4253",
  "fromBJJ": "hez:dMfPJlK_UtFqVByhP3FpvykOg5kAU3jMLD7OTx_4gwzO",
  "fromHezEthereumAddress": "hez:0x74d5531A3400f9b9d63729bA9C0E5172Ab0FD0f6",
  "historicUSD": 0.17855,
  "id": "0x02e7c2c293173f21249058b1d71afd5b1f3c0de4f1a173bac9b9aa4a2d149483a2",
  "itemId": 14590,
  "position": 1,
  "timestamp": "2021-03-16T13:24:48Z",
  "toAccountIndex": "hez:ETH:4254",
  "toBJJ": "hez:HESLP_6Kp_nn5ANmSGiOnhhYvF3wF5Davf7xGi6lwh3U",
  "toHezEthereumAddress": "hez:0x12FfCe7D5d6d09564768d0FFC0774218458162d4",
  "token": {
    "USD": 1787.2,
    "decimals": 18,
    "ethereumAddress": "0x0000000000000000000000000000000000000000",
    "ethereumBlockNum": 0,
    "fiatUpdate": "2021-02-28T18:55:17.372008Z",
    "id": 0,
    "itemId": 1,
    "name": "Ether",
    "symbol": "ETH"
  },
  "type": "Transfer"
}
```

At this point, the balances in both accounts will be updated with the result of the transfer

```dart
    // get sender account information
    final infoAccountSender = (await coordinatorApi
            .getAccounts(hermezEthereumAddress, [tokenERC20.id]))
        .accounts[0];

    // get receiver account information
    final infoAccountReceiver = (await coordinatorApi
            .getAccounts(hermezEthereumAddress2, [tokenERC20.id]))
        .accounts[0];
```

```json
[{
  "accountIndex": "hez:ETH:4253",
  "balance": "477700000000000000",
  "bjj": "hez:dMfPJlK_UtFqVByhP3FpvykOg5kAU3jMLD7OTx_4gwzO",
  "hezEthereumAddress": "hez:0x74d5531A3400f9b9d63729bA9C0E5172Ab0FD0f6",
  "itemId": 4342,
  "nonce": 4,
  "token": {
    "USD": 1793,
    "decimals": 18,
    "ethereumAddress": "0x0000000000000000000000000000000000000000",
    "ethereumBlockNum": 0,
    "fiatUpdate": "2021-02-28T18:55:17.372008Z",
    "id": 0,
    "itemId": 1,
    "name": "Ether",
    "symbol": "ETH"
  }
},
{
  "accountIndex": "hez:ETH:256",
  "balance": "1874280899837791518",
  "bjj": "hez:YN2DmRh0QgDrxz3NLDqH947W5oNys7YWqkxsQmFVeI_m",
  "hezEthereumAddress": "hez:0x9F255048EC1141831A28019e497F3f76e559356E",
  "itemId": 1,
  "nonce": 2,
  "token": {
    "USD": 1793,
    "decimals": 18,
    "ethereumAddress": "0x0000000000000000000000000000000000000000",
    "ethereumBlockNum": 0,
    "fiatUpdate": "2021-02-28T18:55:17.372008Z",
    "id": 0,
    "itemId": 1,
    "name": "Ether",
    "symbol": "ETH"
  }
}]
```

### Create Account Authorization

Imagine that Bob wants to send a transfer of Ether to Mary using Hermez, but Mary only has an Ethereum account but no Hermez account. To complete this transfer, Mary could open a Hermez account and proceed as the previous transfer example. Alternatively, Mary could authorize the Coordinator to create a Hermez account on her behalf so that she can receive Bob's transfer.

First we create a wallet for Mary:

```dart
    // load third account
    final wallet3 =
        await HermezWallet.createWalletFromPrivateKey(EXAMPLES_PRIVATE_KEY3);
    final HermezWallet hermezWallet3 = wallet3[0];
    final String hermezEthereumAddress3 = wallet3[1];
```

The authorization for the creation of a Hermez account is done using the private key stored in the newly created Hermez wallet.

NOTE: that the account is not created at this moment. The account will be created when Bob performs the transfer. Also, it is Bob that pays for the fees associated with the account creation.

```dart
    final signature = await hermezWallet3
        .signCreateAccountAuthorization(EXAMPLES_PRIVATE_KEY3);
    final res = await coordinatorApi.postCreateAccountAuthorization(
        hermezWallet3.hermezEthereumAddress,
        hermezWallet3.publicKeyBase64,
        signature);
```

We can find out if the Coordinator has been authorized to create a Hermez account on behalf of a user by:

```dart
final authResponse = await coordinatorApi.getCreateAccountAuthorization(hermezWallet3.hermezEthereumAddress);
```

```json
{
  "hezEthereumAddress": "hez:0xd3B6DcfCA7Eb3207905Be27Ddfa69453625ffbf9",
  "bjj": "hez:ct0ml6FjdUN6uGUHZ70qOq5-58cZ19SJDeldMH021oOk",
  "signature": "0x22ffc6f8d569a92c48a4e784a11a9e57b840fac21eaa7fedc9dc040c4a45d502744a35eeb0ab173234c0f687b252bd0364647bff8db270ffcdf1830257de28e41c",
  "timestamp": "2021-03-16T14:56:05.295946Z"
}
```

Once we verify the receiving Ethereum account has authorized the creation of a Hermez account, we can proceed with the transfer from Bob's account to Mary's account. For this, we set the destination address to Mary's Ethereum address and set the fee using the createAccount value.

```dart
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
```

```json
{
  "status": 200,
  "id": "0x025398af5b69f132d8c2c5b7b225df1436baf7d1774a6b017a233bf273b4675c8f",
  "nonce": 0
}
```

After the transfer has been forged, we can check Mary's account on Hermez

```dart
// get receiver account information
    final infoAccountReceiver = (await coordinatorApi
            .getAccounts(hermezWallet3.hermezEthereumAddress, [tokenERC20.id]))
        .accounts[0];
```

```json
{
  "accountIndex": "hez:ETH:265",
  "balance": "1000000000000000",
  "bjj": "hez:ct0ml6FjdUN6uGUHZ70qOq5-58cZ19SJDeldMH021oOk",
  "hezEthereumAddress": "hez:0xd3B6DcfCA7Eb3207905Be27Ddfa69453625ffbf9",
  "itemId": 10,
  "nonce": 0,
  "token": {
    "USD": 1795.94,
    "decimals": 18,
    "ethereumAddress": "0x0000000000000000000000000000000000000000",
    "ethereumBlockNum": 0,
    "fiatUpdate": "2021-03-16T14:56:57.460862Z",
    "id": 0,
    "itemId": 1,
    "name": "Ether",
    "symbol": "ETH"
  }
}
```
