import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

class eip712 {
  static Uint8List abiRawEncode(encTypes, encValues) {
    //parseAbiType(name).encode(data, buffer)
    //const hexStr = ethers.utils.defaultAbiCoder.encode(encTypes, encValues);
    //return Uint8List.fromList(hexStr.slice(2, hexStr.length), 'hex');
    return Uint8List(10);
  }

  static Future<MsgSignature> sign(Map domain, String primaryType,
      Map<String, String> message, Map types, EthPrivateKey signer) async {
    MsgSignature signature;

    try {
      if (signer.privateKey != null) {
        final digest = digestToSign(domain, primaryType, message, types);
        signature = await signer.signToSignature(digest);
        //signature.v = '0x' + (signature.v).toRadixString(16);
      } else {
        final address = await signer.extractAddress();
        final msgParams = json.encode({domain, primaryType, message, types});

        final String signMsg = "";

        BigInt r = hexToInt('0x' + signMsg.substring(2).substring(0, 64));
        BigInt s = hexToInt('0x' + signMsg.substring(2).substring(64, 128));
        int v = hexToDartInt('0x' + signMsg.substring(2).substring(128, 130));

        signature = MsgSignature(r, s, v);
      }
    } catch (e) {
      throw new Error();
    }

    return signature;
  }

  static Uint8List digestToSign(domain, primaryType, message, types) {
    final originHex = '1901';
    final domainSeparatorBytes = domainSeparator(domain);
    final domainSeparatorHex = bytesToHex(domainSeparatorBytes);
    final structHashBytes = structHash(primaryType, message, types);
    final structHashHex = bytesToHex(structHashBytes);

    final v = originHex + domainSeparatorHex + structHashHex;
    final h = keccak256(hexToBytes(v));

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

  static Uint8List structHash(
      primaryType, data, Map<String, List<Map<String, String>>> types) {
    return keccak256(encodeData(primaryType, data, types));
  }

  static Uint8List encodeData(String primaryType, Map data,
      Map<String, List<Map<String, String>>> types) {
    List encTypes = [];
    List encValues = [];

    // Add typehash
    encTypes.add('bytes32');
    encValues.add(typeHash(primaryType, types));

    // Add field contents
    types[primaryType].forEach((Map<String, String> field) {
      var value = data[field['name']];
      if (field['type'] == 'string' || field['type'] == 'bytes') {
        encTypes.add('bytes32');
        value = keccakUtf8(value);
        encValues.add(value);
      } else if (types[field['type']] != null) {
        encTypes.add('bytes32');
        value = keccak256(encodeData(field['type'], value, types));
        encValues.add(value);
      } else if (field['type'].lastIndexOf(']') == field['type'].length - 1) {
        throw 'TODO: Arrays currently uninplemented in encodeData';
      } else {
        encTypes.add(field['type']);
        encValues.add(value);
      }
    });

    return abiRawEncode(encTypes, encValues);
  }

  static Uint8List typeHash(
      String primaryType, Map<String, List<Map<String, String>>> types) {
    return keccakUtf8(encodeType(primaryType, types));
  }

  static String encodeType(
      String primaryType, Map<String, List<Map<String, String>>> types) {
    if (types == null) {
      types = {};
    }
    // Get dependencies primary first, then alphabetical
    List<String> deps = dependencies(primaryType);
    /*deps =*/ deps.removeWhere((t) => t != primaryType);
    deps.sort(); //filter(t => t != primaryType);
    [primaryType].addAll(deps); //concat(deps.sort());

    // Format as a string with fields
    String result = '';
    deps.forEach((type) {
      if (types[type] == null) {
        throw new ErrorDescription(
            "Type '${type}' not defined in types (${json.encode(types)})");
      }
      //result += "${type}(${types[type].map(({ name, type }) => ${type} ${name}).join(',')})";
    });
    return result;
  }

  // Recursively finds all the dependencies of a type
  static List dependencies(String primaryType,
      {List<String> found, Map<String, List<Map<String, String>>> types}) {
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
