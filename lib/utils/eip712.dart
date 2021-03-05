import 'dart:typed_data';

import 'package:web3dart/contracts.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
// ignore: implementation_imports
import 'package:web3dart/src/utils/length_tracking_byte_sink.dart'
    show LengthTrackingByteSink;

class eip712 {
  static Uint8List abiRawEncode(encTypes, encValues) {
    String resultHex = '';
    if (encTypes.length != encValues.length) {
      throw ArgumentError('types/values length mismatch');
    }
    for (int i = 0; i < encTypes.length; i++) {
      String name = encTypes[i];
      dynamic data = encValues[i];
      LengthTrackingByteSink buffer = new LengthTrackingByteSink();
      parseAbiType(name).encode(data, buffer);
      print(buffer.asBytes());
      resultHex += bytesToHex(buffer.asBytes());
    }

    //const hexStr = ethers.utils.defaultAbiCoder.encode(encTypes, encValues);
    //return Uint8List.fromList(hexStr.slice(2, hexStr.length), 'hex');

    return hexToBytes(resultHex);
  }

  /*
  * encode(types: Array<string | ParamType>, values: Array<any>): string {
        if (types.length !== values.length) {
            logger.throwError("types/values length mismatch", Logger.errors.INVALID_ARGUMENT, {
                count: { types: types.length, values: values.length },
                value: { types: types, values: values }
            });
        }

        const coders = types.map((type) => this._getCoder(ParamType.from(type)));
        const coder = (new TupleCoder(coders, "_"));

        const writer = this._getWriter();
        coder.encode(writer, values);
        return writer.data;
    }
  * */

  static encodeDigest() {
    final eip191Header = '0x1901';
  }

  static Future<Uint8List> sign(Map domain, String primaryType,
      Map<String, dynamic> message, Map types, EthPrivateKey signer) async {
    //MsgSignature signature;
    Uint8List signature;
    try {
      if (signer.privateKey != null) {
        final digest = digestToSign(domain, primaryType, message, types);
        print(bytesToHex(digest));
        //signature = await signer.signToSignature(digest);
        signature = await signer.sign(digest);
        //signature.v = '0x' + (signature.v).toRadixString(16);
      }
      /* else {
        final address = await signer.extractAddress();
        final msgParams = json.encode({domain, primaryType, message, types});

        final String signMsg = "";

        BigInt r = hexToInt('0x' + signMsg.substring(2).substring(0, 64));
        BigInt s = hexToInt('0x' + signMsg.substring(2).substring(64, 128));
        int v = hexToDartInt('0x' + signMsg.substring(2).substring(128, 130));

        signature = MsgSignature(r, s, v);
      }*/
    } catch (e) {
      throw new Error();
    }

    return signature;
  }

  static Uint8List digestToSign(domain, primaryType, message, types) {
    final eip191HeaderHex = '1901';

    //final domainHash = structHash('EIP712Domain', domain, types);

    final domainSeparatorBytes = domainSeparator(domain);
    final domainSeparatorHex = bytesToHex(domainSeparatorBytes);
    final structHashBytes = structHash(primaryType, message, types);
    final structHashHex = bytesToHex(structHashBytes);

    final v = eip191HeaderHex + domainSeparatorHex + structHashHex;
    final h = hexToBytes(v);

    return h;
  }

  static Uint8List domainSeparator(Map domain) {
    final types = {
      'EIP712Domain': [
        {'name': 'name', 'type': 'string'},
        {'name': 'version', 'type': 'string'},
        {'name': 'chainId', 'type': 'uint256'},
        {'name': 'verifyingContract', 'type': 'address'},
        {'name': 'salt', 'type': 'bytes32'}
      ]
          .where((a) => domain.containsKey(a['name']))
          .toList() //.filter(a => domain[a.name])
    };
    return keccak256(encodeData('EIP712Domain', domain, types));
  }

  static Uint8List structHash(primaryType, data, Map types) {
    return keccak256(encodeData(primaryType, data, types));
  }

  static Uint8List encodeData(String primaryType, Map data, Map types) {
    final args = types[primaryType];
    if (args == null || args.length == 0) {
      throw ArgumentError('TypedDataUtils: $primaryType type is unknown');
    }

    List<String> abiTypes = [];
    List<dynamic> abiValues = [];

    final typeHashBytes = typeHash(primaryType, types);

    // Add typehash
    abiTypes.add('bytes32');
    abiValues.add(typeHashBytes);

    // Add field contents
    types[primaryType].forEach((Map<String, String> field) {
      var value = data[field['name']];
      if (field['type'] == 'string' || field['type'] == 'bytes') {
        abiTypes.add('bytes32');
        value = keccakUtf8(value);
        abiValues.add(value);
      } else if (types[field['type']] != null) {
        abiTypes.add('bytes32');
        value = keccak256(encodeData(field['type'], value, types));
        abiValues.add(value);
      } else if (field['type'].lastIndexOf(']') == field['type'].length - 1) {
        throw 'TODO: Arrays currently uninplemented in encodeData';
      } else {
        abiTypes.add(field['type']);
        abiValues.add(value);
      }
    });

    return abiRawEncode(abiTypes, abiValues);
  }

  static Uint8List typeHash(String primaryType, Map types) {
    return keccakUtf8(encodeType(primaryType, types));
  }

  static String encodeType(String primaryType, Map types) {
    if (types == null) {
      types = {};
    }
    // Get dependencies primary first, then alphabetical
    List<String> deps = dependencies(primaryType);
    /*deps =*/ deps.removeWhere((t) => t != primaryType);
    deps.sort();
    List<String> deps2 = [primaryType]; //filter(t => t != primaryType);
    deps2.addAll(deps); //concat(deps.sort());

    // Format as a string with fields
    String result = '';
    deps2.forEach((type) {
      /*if (types[type] == null) {
        throw new ErrorDescription(
            "Type '${type}' not defined in types (${json.encode(types)})");
      }*/
      result += '$type(';
      List<Map<String, String>> types2 = types[type];
      List<String> values = [];
      types2.forEach(
          (element) => values.add('${element['type']} ${element['name']}'));
      result += values.join(',');
      result += ')';
      /*result +=
          '$type(${types[type].forEach((element) => '${element['type']} ${element['name']}').join(',')})';*/
    });
    return result;
  }

  // Recursively finds all the dependencies of a type
  static List dependencies(String primaryType,
      {List<String> found, Map types}) {
    if (found == null) {
      found = [];
    }
    if (types == null) {
      types = {};
    }

    if (found.contains(primaryType)) {
      return found;
    }
    if (types[primaryType] == null) {
      return found;
    }
    found.add(primaryType);
    types[primaryType].forEach((field) {
      dependencies(field['type'], found: found).forEach((dep) {
        if (!found.contains(dep)) {
          found.add(dep);
        }
      });
    });
    return found;
  }
}
