import 'dart:math';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:hermez_plugin/addresses.dart';
import 'package:hermez_plugin/utils/uint8_list_utils.dart';
import 'package:hex/hex.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

import 'eddsa_babyjub.dart' as eddsaBabyJub;
import "tx_utils.dart" show buildTransactionHashMessage;
import 'utils/hd_key.dart';

/// @class
/// Manage Babyjubjub keys
/// Perform standard wallet actions
class HermezWallet {
  dynamic privateKey;
  dynamic publicKey;
  dynamic publicKeyHex;
  dynamic publicKeyCompressed;
  dynamic publicKeyCompressedHex;
  dynamic hermezEthereumAddress;

  /// Initialize Babyjubjub wallet from private key
  /// @param {Uint8List} privateKey - 32 bytes buffer
  /// @param {String} hermezEthereumAddress - Hexadecimal string containing the public Ethereum key from Metamask
  HermezWallet(Uint8List privateKey, String hermezEthereumAddress) {
    if (privateKey.length != 32) {
      throw new ArgumentError('buf must be 32 bytes');
    }

    if (!isHermezEthereumAddress(hermezEthereumAddress)) {
      throw new ArgumentError('Invalid Hermez Ethereum address');
    }

    //final publicKey = circomlib.eddsa.prv2pub(privateKey);
    final priv = eddsaBabyJub.PrivateKey(privateKey);
    final eddsaBabyJub.PublicKey publicKey = priv.public();
    this.privateKey = privateKey;
    this.publicKey = [publicKey.p[0].toString(), publicKey.p[1].toString()];
    this.publicKeyHex = [
      publicKey.p[0].toRadixString(16),
      publicKey.p[1].toRadixString(16)
    ];
    this.publicKeyCompressed = publicKey.compress().toString();
    this.publicKeyCompressedHex = publicKey.compress().toString();
    this.hermezEthereumAddress = hermezEthereumAddress;
  }

  /// Creates a Hermez Wallet and Ethereum Wallet from mnemonic phrase
  /// @param {String} mnemonic - mnemonic phrase
  /// @returns {Object} Contains the `hermezWallet` as a HermezWallet instance and the `hermezEthereumAddress`
  static dynamic createWalletFromMnemonic(String mnemonic) async {
    //final Web3Client provider = getProvider();
    String seed = bip39.mnemonicToSeedHex(mnemonic);
    KeyData master = HDKey.getMasterKeyFromSeed(seed);

    print(HEX.encode(master
        .key)); // 171cb88b1b3c1db25add599712e36245d75bc65a1a5c9e18d76f9f2b1eab4012
    print(HEX.encode(master
        .chainCode)); // ef70a74db9c3a5af931b5fe73ed8e1a53464133654fd55e7a66f8570b8e33c3b
    // "m/44'/60'/0'/0/0"
    // m / purpose' / coin_type' / account' / change / address_index
    KeyData data = HDKey.derivePath("m/0'/2147483647'", seed);
    var pb = HDKey.getPublicKey(data.key);
    print(HEX.encode(data
        .key)); // ea4f5bfe8694d8bb74b7b59404632fd5968b774ed545e810de9c32a4fb4192f4
    print(HEX.encode(data
        .chainCode)); // 138f0b2551bcafeca6ff2aa88ba8ed0ed8de070841f0c4ef0165df8181eaad7f
    print(HEX.encode(
        pb)); // 005ba3b9ac6e90e83effcd25ac4e58a1365a9e35a3d3ae5eb07b9e4d90bcf7506d

    final signer = EthPrivateKey.createRandom(Random.secure());
    final ethereumAddress = await signer.extractAddress();
    final hermezEthereumAddress = getHermezAddress(ethereumAddress.hex);
    final hermezWallet =
        new HermezWallet(Uint8List.fromList(data.key), hermezEthereumAddress);
    return {hermezWallet, hermezEthereumAddress};
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
  dynamic signTransaction(transaction, encodedTransaction) {
    final hashMessage = buildTransactionHashMessage(encodedTransaction);
    final privKey = new eddsaBabyJub.PrivateKey(this.privateKey);
    final signature = privKey.sign(hashMessage);
    final Uint8List compressedSigLE =
        Uint8ArrayUtils.uint8ListfromString(signature);
    final packedSignature = eddsaBabyJub.packSignature(compressedSigLE);
    transaction.signature = packedSignature; // HEX.encode
    return transaction;
  }

  /// Generates the signature necessary for /create-account-authorization endpoint
  /// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
  /// @param {Object} signerData - Signer data used to build a Signer to create the walet
  /// @returns {String} The generated signature
  dynamic signCreateAccountAuthorization(String providerUrl, dynamic signerData) async {
    const provider = getProvider(providerUrl);
    const signer = getSigner(provider, signerData);

    const accountCreationAuthMsgArray = ethers.utils.toUtf8Bytes(CREATE_ACCOUNT_AUTH_MESSAGE);
    const chainId = (await provider.getNetwork()).chainId.toString(16)
    const chainIdHex = chainId.startsWith('0x') ? chainId : `0x${chainId}`
    const messageHex =
    ethers.utils.hexlify(accountCreationAuthMsgArray) +
    this.publicKeyCompressedHex +
    ethers.utils.hexZeroPad(chainIdHex, 2).slice(2) +
    getEthereumAddress(this.hermezEthereumAddress).slice(2)

    const messageArray = ethers.utils.arrayify(messageHex)
    const signature = await signer.signMessage(messageArray)
    // Generate the signature from params as there's a bug in ethers
    // that generates the base signature wrong
    const signatureParams = ethers.utils.splitSignature(signature)
    return signatureParams.r + signatureParams.s + signatureParams.v
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
