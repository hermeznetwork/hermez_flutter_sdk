import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/libs/circomlib.dart';

void main() async {
  final circomlib = CircomLib(/*lib: await SetupUtil.getDylibAsync()*/);

  test('decompressSignature', () {
    final buf = "helloo";
    final version = circomlib.unpackSignature(buf);
    print('LZ4 version number: $version');
    assert(version == 10902);
  });

  test('pack_signature', () {
    final signature = "helloo";
    //final signature = Uint8ArrayUtils.leBuff2int(buf);
    final version = circomlib.packSignature(signature);
  });

  /*void testPackUnpackPoint() {
    String result = "PACK/UNPACK POINT - NOT OK";
    String response = _circomLib.packPoint(
        "17777552123799933955779906779655732241715742912184938656739573121738514868268",
        "2626589144620713026669568689430873010625803728049924121243784502389097019475");

    if (response ==
        "53B81ED5BFFE9545B54016234682E7B2F699BD42A5E9EAE27FF4051BC698CE85") {
      List<String> response2 = _circomLib.unpackPoint(response);
      List<String> compare = [
        "17777552123799933955779906779655732241715742912184938656739573121738514868268",
        "2626589144620713026669568689430873010625803728049924121243784502389097019475"
      ];
      if (response2[0] == compare[0] && response2[1] == compare[1]) {
        result = "PACK/UNPACK POINT - OK";
      }
    }
    setState(() {
      _response = result;
    });
  }

  void testSignVerify() {
    String result = "SIGN/VERIFY - NOT OK";
    String privateKey =
        "4325167421119908073005489081111652247460688304995713100909523264465269965395075545413371497545575448084603520390412614518888537510895798506393221609836256";
    String message = "12345";
    String response = _circomLib.signPoseidon(privateKey, message);
    bool response2 = _circomLib.verifyPoseidon(privateKey, response, message);
    if (response2) {
      result = "SIGN/VERIFY - OK";
    }
    setState(() {
      _response = result;
    });
  }

  void testPackUnpackSignature() {
    String result = "PACK/UNPACK SIGNATURE - ";
    String response = _circomLib.unpackSignature(
        "2F0CE8F0E5F292EFF57415D7DD84852A6B8A678C00B53ED4E0B17B0B79332B27254D7906795C3C6A80D90E793FC12475CF57E7CE5E1A00229B79F38B8CCE4F01");

    if (response ==
        "BAD4693783119F517BFFFC3584134BB32F0CE8F0E5F292EFF57415D7DD84852A254D7906795C3C6A80D90E793FC12475CF57E7CE5E1A00229B79F38B8CCE4F01") {
      String response2 = _circomLib.packSignature(response);
      if (response2 ==
          "2F0CE8F0E5F292EFF57415D7DD84852A6B8A678C00B53ED4E0B17B0B79332B27254D7906795C3C6A80D90E793FC12475CF57E7CE5E1A00229B79F38B8CCE4F01") {
        result = "PACK/UNPACK SIGNATURE - OK";
      }
    }
    setState(() {
      _response = result + response;
    });
  }

  /*


  //dynamic hermezWallet = HermezWallet.createWalletFromMnemonic("mnemonic");
    // sync call
    //String response = nativeGreeting("John Smith");
    /* CircomLib circomLib = CircomLib();
    circomLib.String response = nativeDecompressSignature(Uint8List(0));

    setState(() {
      _response = response;
    });*/

   */
  * let sk = new_key();
        let pk = sk.public().unwrap();

        for i in 0..5 {
            let msg_raw = "123456".to_owned() + &i.to_string();
            let msg = BigInt::parse_bytes(msg_raw.as_bytes(), 10).unwrap();
            let sig = sk.sign(msg.clone()).unwrap();

            let compressed_sig = sig.compress();
            let decompressed_sig = decompress_signature(&compressed_sig).unwrap();
            assert_eq!(&sig.r_b8.x, &decompressed_sig.r_b8.x);
            assert_eq!(&sig.r_b8.y, &decompressed_sig.r_b8.y);
            assert_eq!(&sig.s, &decompressed_sig.s);

            let v = verify(pk.clone(), decompressed_sig, msg);
            assert_eq!(v, true);
        }
  * */
}
