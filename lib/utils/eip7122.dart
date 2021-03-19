import 'dart:typed_data';

import 'package:web3dart/contracts.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
// ignore: implementation_imports
//import 'package:web3dart/src/utils/rlp.dart' as rlp;
import 'package:web3dart/src/utils/length_tracking_byte_sink.dart'
    show LengthTrackingByteSink;

class TypedData {
  Map<String, List<TypedDataArgument>> types;
  String primaryType;
  Map<String, dynamic> domain;
  dynamic message;

  TypedData(this.types, this.primaryType, this.domain, this.message);
}

class TypedDataArgument {
  String name;
  String type;

  TypedDataArgument(this.name, this.type);
}

class TypedDataDomain {
  String name;
  String version;
  BigInt chainId;
  EthereumAddress verifyingContract;
  String salt;

  TypedDataDomain(this.name, this.version, this.chainId, this.verifyingContract,
      {this.salt});
}

class eip7122 {
  static Uint8List encodeDigest(TypedData typedData) {
    final eip191HeaderHex = "1901";
    final eip191Header = hexToBytes(eip191HeaderHex);
    final domainHash = hashStruct(typedData, 'EIP712Domain', typedData.domain);
    final domainHashHex = bytesToHex(domainHash);
    final messageHash = zeroPad(
        hashStruct(typedData, typedData.primaryType, typedData.message), 32);
    final messageHashHex = bytesToHex(messageHash);

    final bytesBuilder = BytesBuilder();
    //bytesBuilder.addByte(42);
    bytesBuilder.add(eip191Header);
    bytesBuilder.add(domainHash);
    bytesBuilder.add(messageHash);

    /*List<String> abiTypes = [];
    List<dynamic> abiValues = [];

    abiTypes.add('bytes');
    abiValues.add(eip191Header);

    abiTypes.add('bytes32');
    abiValues.add(domainHash);

    abiTypes.add('bytes32');
    abiValues.add(messageHash);*/

    /*const pack = ethers.utils.solidityPack(
        ['bytes', 'bytes32', 'bytes32'],
        [eip191Header, zeroPad(domainHash, 32), zeroPad(messageHash, 32)]
    )*/

    /*LengthTrackingByteSink buffer = new LengthTrackingByteSink();
    // ignore: invalid_use_of_visible_for_testing_member
    parseAbiType('bytes').encode(eip191Header, buffer);
    print(buffer.asBytes());*/

    //final v = bytesToHex(abiRawEncode(abiTypes, abiValues));

    //LengthTrackingByteSink buffer = new LengthTrackingByteSink();
    //parseAbiType('bytes').encode(hexToBytes(v), buffer);

    /*const data = JSON.stringify({
      types: {
        EIP712Domain: domain,
        Authorise: authorise
      },
      domain: domainData,
      primaryType: "Authorise",
      message: message
    });*/
    final message = bytesToHex(bytesBuilder.toBytes());

    final h = bytesBuilder.toBytes();

    return h;
  }

  static Uint8List hashStruct(
      TypedData typedData, String primaryType, dynamic data) {
    return keccak256(encodeData(typedData, primaryType, data));
  }

  static Uint8List encodeData(
      TypedData typedData, String primaryType, dynamic data) {
    final types = typedData.types;
    final args = types[primaryType];
    if (args == null || args.length == 0) {
      throw ArgumentError('TypedDataUtils: $primaryType type is not defined');
    }

    List<String> abiTypes = [];
    List<dynamic> abiValues = [];

    final typeHashBytes = typeHash(types, primaryType);

    // Add typehash
    abiTypes.add('bytes32');
    abiValues.add(zeroPad(typeHashBytes, 32));

    // Add field contents
    types[primaryType].forEach((TypedDataArgument field) {
      var value = data[field.name];
      if (types[field.type] != null) {
        abiTypes.add('bytes32');
        value = keccak256(encodeData(typedData, field.type, value));
        abiValues.add(value);
      } else if (field.type == 'string' || field.type == 'bytes') {
        abiTypes.add('bytes32');
        if (field.type == 'string') {
          value = zeroPad(keccakUtf8(value), 32);
        } else {
          value = zeroPad(keccak256(value), 32);
        }
        abiValues.add(value);
      } else if (field.type.lastIndexOf(']') == field.type.length - 1) {
        throw 'TODO: Arrays currently uninplemented in encodeData';
      } else {
        abiTypes.add(field.type);
        abiValues.add(value);
      }
    });

    return abiRawEncode(abiTypes, abiValues);
  }

  static Uint8List typeHash(
      Map<String, List<TypedDataArgument>> typedDataTypes, String primaryType) {
    return keccak256(
        Uint8List.fromList(encodeType(typedDataTypes, primaryType).codeUnits));
  }

  static String encodeType(
      Map<String, List<TypedDataArgument>> typedDataTypes, String primaryType) {
    final args = typedDataTypes[primaryType];
    if (args == null || args.length == 0) {
      throw ArgumentError('TypedDataUtils: $primaryType type is not defined');
    }

    final List<String> subTypes = [];
    String s = primaryType + '(';

    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      final arrayArg = arg.type.indexOf('[');
      final argType = arrayArg < 0 ? arg.type : arg.type.substring(0, arrayArg);

      if (typedDataTypes[argType] != null &&
          typedDataTypes[argType].length > 0) {
        bool set = false;
        for (int x = 0; x < subTypes.length; x++) {
          if (subTypes[x] == argType) {
            set = true;
          }
        }
        if (!set) {
          subTypes.add(argType);
        }
      }

      s += arg.type + ' ' + arg.name;
      if (i < args.length - 1) {
        s += ',';
      }
    }
    s += ')';

    subTypes.sort();
    for (int i = 0; i < subTypes.length; i++) {
      final subEncodeType = encodeType(typedDataTypes, subTypes[i]);
      s += subEncodeType;
    }

    return s;
  }

  static Uint8List abiRawEncode(encTypes, encValues) {
    String resultHex = '';
    if (encTypes.length != encValues.length) {
      throw ArgumentError('types/values length mismatch');
    }

    for (int i = 0; i < encTypes.length; i++) {
      String name = encTypes[i];
      dynamic data = encValues[i];
      LengthTrackingByteSink buffer = new LengthTrackingByteSink();
      // ignore: invalid_use_of_visible_for_testing_member
      parseAbiType(name).encode(data, buffer);
      print(buffer.asBytes());
      print(bytesToHex(buffer.asBytes()));
      resultHex += bytesToHex(buffer.asBytes());
    }

    return hexToBytes(resultHex);
  }

  static Uint8List zeroPad(Uint8List data, int size) {
    //assert(data.length <= size);
    if (data.length >= size) return data;
    return Uint8List(size)..setRange(size - data.length, size, data);
  }
}
