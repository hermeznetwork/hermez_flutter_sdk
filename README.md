# hermez_sdk

## Description

This is a flutter Plugin for Hermez Mobile SDK (https://hermez.io). This plugin provides a cross-platform tool (iOS, Android) to communicate with the Hermez API and network.

## Installation

To use this plugin, add `hermez_sdk` as a [dependency](https://flutter.io/using-packages/) in your `pubspec.yaml` file like this

```yaml
dependencies:
  hermez_sdk:
```
This will get you the latest version.

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

### Create Wallet

### Move tokens from Ethereum to Hermez Network

### Token Balance

### Move tokens from Hermez to Ethereum Network

#### Exit

#### Withdraw

#### Force Exit

### Transfers

### Transaction Status

### Create Account Authorization


