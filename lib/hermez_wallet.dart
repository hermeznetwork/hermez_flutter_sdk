import 'dart:typed_data';

import 'package:hermez_sdk/utils/eip712.dart';
import 'package:hermez_sdk/utils/uint8_list_utils.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

import 'addresses.dart';
import 'constants.dart';
import 'eddsa_babyjub.dart' as eddsaBabyJub;
import 'environment.dart';
import "tx_utils.dart" show buildTransactionHashMessage;

/// @class
/// Manage Babyjubjub keys
/// Perform standard wallet actions
class HermezWallet {
  late dynamic privateKey;
  dynamic publicKey;
  dynamic publicKeyHex;
  String? publicKeyCompressed;
  String? publicKeyCompressedHex;
  String? publicKeyBase64;
  dynamic hermezEthereumAddress;

  /// Initialize Babyjubjub wallet from private key
  /// @param {Uint8List} privateKey - 32 bytes buffer
  /// @param {String} hermezEthereumAddress - Hexadecimal string containing the public Ethereum Address
  HermezWallet(Uint8List privateKey, String hermezEthereumAddress) {
    if (privateKey.length != 32) {
      throw new ArgumentError('buf must be 32 bytes');
    }

    if (!isHermezEthereumAddress(hermezEthereumAddress)) {
      throw new ArgumentError('Invalid Hermez Ethereum address');
    }
    final priv = eddsaBabyJub.PrivateKey(privateKey);
    final eddsaBabyJub.PublicKey publicKey = priv.public();
    this.privateKey = privateKey;
    this.publicKey = [publicKey.p[0].toString(), publicKey.p[1].toString()];
    this.publicKeyHex = [
      publicKey.p[0].toRadixString(16),
      publicKey.p[1].toRadixString(16)
    ];
    final compressedPublicKey =
        Uint8ArrayUtils.leBuff2int(publicKey.compress());
    this.publicKeyCompressed = compressedPublicKey.toString();
    this.publicKeyCompressedHex =
        compressedPublicKey.toRadixString(16).padLeft(64, '0');
    this.publicKeyBase64 = hexToBase64BJJ(publicKeyCompressedHex!);
    this.hermezEthereumAddress = hermezEthereumAddress;
  }

/*/// Signs message with private key
  /// @param {String} messageStr - message to sign
  /// @returns {String} - Babyjubjub signature packed and encoded as an hex string
  String signMessage(String messageStr) {
    final messBuff = hexToBuffer(messageStr);
    final messHash = hashBuffer(messBuff);
    final privateKey = new eddsaBabyJub.PrivateKey(this.privateKey);
    final sig = privateKey.sign(messHash);
    return sig.toRadixString(16);
  }*/

  /// To sign transaction with babyjubjub keys
  /// @param {object} transaction - Transaction object
  /// @param {Object} encodedTransaction - Transaction encoded object
  /// @returns {object} The signed transaction object
  Map<String, dynamic> signTransaction(Map<String, dynamic> transaction,
      Map<String, dynamic> encodedTransaction) {
    final hashMessage = buildTransactionHashMessage(encodedTransaction);
    final privKey = new eddsaBabyJub.PrivateKey(this.privateKey);
    final signature = privKey.sign(hashMessage);
    transaction['signature'] = signature;
    return transaction;
  }

  /// Generates the signature necessary for /create-account-authorization endpoint
  /// @param {String} privateKey - private key used to create the wallet
  /// @returns {String} The generated signature
  Future<String> signCreateAccountAuthorization(String privateKey) async {
    final signer = EthPrivateKey.fromHex(privateKey);

    final bJJ = this.publicKeyCompressedHex!.startsWith('0x')
        ? this.publicKeyCompressedHex!
        : '0x${this.publicKeyCompressedHex}';

    final Map<String, dynamic> domain = {
      'name': EIP_712_PROVIDER,
      'version': EIP_712_VERSION,
      'chainId':
          BigInt.from(getCurrentEnvironment()!.chainId).toRadixString(16),
      'verifyingContract':
          EthereumAddress.fromHex(getCurrentEnvironment()!.contracts['Hermez']!)
    };

    final Map<String, dynamic> message = {
      'Provider': EIP_712_PROVIDER,
      'Authorisation': CREATE_ACCOUNT_AUTH_MESSAGE,
      'BJJKey': hexToBytes(bJJ)
    };

    final String primaryType = 'Authorise';

    final Map<String, List<TypedDataArgument>> types = {
      'Authorise': [
        TypedDataArgument('Provider', 'string'),
        TypedDataArgument('Authorisation', 'string'),
        TypedDataArgument('BJJKey', 'bytes32')
      ],
      'EIP712Domain': [
        TypedDataArgument('name', 'string'),
        TypedDataArgument('version', 'string'),
        TypedDataArgument('chainId', 'uint256'),
        TypedDataArgument('verifyingContract', 'address')
      ]
    };

    final typedData = TypedData(types, primaryType, domain, message);

    final messageHash = eip712.encodeDigest(typedData);
    final signature = await signer.sign(messageHash);
    final signatureHex = bytesToHex(signature, include0x: true);
    return signatureHex;
  }

  /// Creates a HermezWallet from one of the Ethereum wallets in the provider
  /// @param {String} privateKey - Signer data used to build a Signer to create the wallet
  /// @returns {Object} Contains the `hermezWallet` as a HermezWallet instance and the `hermezEthereumAddress`
  static dynamic createWalletFromPrivateKey(String privateKey) async {
    final prvKey = EthPrivateKey.fromHex(privateKey);
    final ethereumAddress = await prvKey.extractAddress();
    final hermezEthereumAddress = getHermezAddress(ethereumAddress.hex);
    final signature = await prvKey.sign(
        Uint8ArrayUtils.uint8ListfromString(HERMEZ_ACCOUNT_ACCESS_MESSAGE));
    final hashedBufferSignature = keccak256(signature);
    final hermezWallet =
        new HermezWallet(hashedBufferSignature, hermezEthereumAddress);

    return List.from([hermezWallet, hermezEthereumAddress]);
  }

  /// Creates a HermezWallet from Babyjubjub private key
  /// This creates a wallet for an internal account
  /// An internal account has a Babyjubjub key and Ethereum account 0xFFFF...FFFF
  /// Random wallet is created if no private key is provided
  /// @param {Uint8List} privateKey - 32 bytes buffer
  /// @returns {Object} Contains the `hermezWallet` as a HermezWallet instance and the `hermezEthereumAddress`
  static dynamic createWalletFromBjjPvtKey(Uint8List? privateKey) async {
    Uint8List privateBjjKey = privateKey != null ? privateKey : Uint8List(32);
    if (privateKey == null) {
      privateBjjKey.fillRange(0, 32, 1);
    }
    final hermezWallet =
        new HermezWallet(privateBjjKey, INTERNAL_ACCOUNT_ETH_ADDR);

    return List.from([hermezWallet, INTERNAL_ACCOUNT_ETH_ADDR]);
  }
}

/*/// Verifies signature for a given message using babyjubjub
/// @param {String} publicKeyHex - Babyjubjub public key encoded as hex string
/// @param {String} messStr - clear message data
/// @param {String} signatureHex - Ecdsa signature compressed and encoded as hex string
/// @returns {bool} True if validation is successful; otherwise false
bool verifyBabyJub(String publicKeyHex, String messStr, String signatureHex) {
  final pkBuff = BigInt.from(int.parse(publicKeyHex, radix: 16));
  final pk = eddsaBabyJub.PublicKey.newFromCompressed(pkBuff);
  final msgBuff = Uint8ArrayUtils.uint8ListfromString(messStr);
  final hashBuff = hashBuffer(msgBuff);
  final hashStr = Uint8ArrayUtils.bigIntToBytes(hashBuff);
  final hash = Uint8ArrayUtils.uint8ListToString(hashStr);
  final sigBuff = Uint8ArrayUtils.bigIntToBytes(
      BigInt.from(int.parse(signatureHex, radix: 16)));
  final sig = eddsaBabyJub.Signature.newFromCompressed(sigBuff);
  return pk.verify(hash, sig);
}*/
