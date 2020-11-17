// WARNING still updating the code, it works, but is still in process the refactor.

pub mod eddsa;

use poseidon_rs::Poseidon;
pub type Fr = poseidon_rs::Fr;

#[macro_use]
extern crate lazy_static;
#[macro_use]
extern crate arrayref;
extern crate generic_array;
extern crate mimc_rs;
extern crate num;
extern crate num_bigint;
extern crate num_traits;
extern crate rand6;
extern crate rand;
#[macro_use]
extern crate ff;
use ff::*;

use crate::eddsa::{Signature, decompress_point, Point, PrivateKey, verify};
use num_bigint::{Sign, BigInt, ToBigInt};
use std::os::raw::c_char;
use std::ffi::{CString, CStr};

lazy_static! {
 static ref B8: Point = Point {
        x: Fr::from_str(
            "5299619240641551281634865583518297030282874472190772894086521144482721001553",
        )
        .unwrap(),
        y: Fr::from_str(
            "16950150798460657717958625567821834550301663161624707787222815936182638968203",
        )
        .unwrap(),
            // z: Fr::one(),
    };
}

#[no_mangle]
pub extern fn pack_signature(b: &[u8; 64]) -> Result<Signature, String> {

}

#[no_mangle]
pub extern fn unpack_signature(b: &[u8; 64]) -> Result<Signature, String> {
    let r_b8_bytes: [u8; 32] = *array_ref!(b[..32], 0, 32);
    let s: BigInt = BigInt::from_bytes_le(Sign::Plus, &b[32..]);
    let r_b8 = decompress_point(r_b8_bytes);
    match r_b8 {
        Result::Err(err) => return Err(err.to_string()),
        Result::Ok(res) => Ok(Signature {
            r_b8: res.clone(),
            s: s,
        }),
    }
}

#[no_mangle]
pub extern fn pack_point(b: &[u8; 64]) -> Result<Signature, String> {

}

#[no_mangle]
pub extern fn unpack_point(b: &[u8; 32]) -> Result<Point, String> {
    let r_b8_bytes: [u8; 32] = *array_ref!(b[..32], 0, 32);
    let r_b8 = decompress_point(r_b8_bytes);
    match r_b8 {
        Result::Err(err) => return Err(err.to_string()),
        Result::Ok(res) => Ok(res),
    }
}






/*Result<Point, String>
pub extern fn unpack_point() -> Result<Point, String> {

}*/

#[no_mangle]
pub extern fn prv2pub(key: &[u8; 32]) -> Result<Point, String> {
    let prv: BigInt = BigInt::from_bytes_le(Sign::Plus, &key[..32]);
    let pk = B8.mul_scalar(&prv)?;
    Ok(pk.clone())
}

#[no_mangle]
pub extern fn poseidon(tx_compressed_data: *const c_char, to_eth_addr: *const c_char, to_bjj_ay: *const c_char, rq_txcompressed_data_v2: *const c_char, rq_to_eth_addr: *const c_char, rq_to_bjj_ay: *const c_char) -> *mut c_char {
    let b0: Fr = Fr::from_str(tx_compressed_data).unwrap();
    let b1: Fr = Fr::from_str(to_eth_addr).unwrap();
    let b2: Fr = Fr::from_str(to_bjj_ay).unwrap();
    let b3: Fr = Fr::from_str(rq_txcompressed_data_v2).unwrap();
    let b4: Fr = Fr::from_str(rq_to_eth_addr).unwrap();
    let b5: Fr = Fr::from_str(rq_to_bjj_ay).unwrap();

    let mut big_arr: Vec<Fr> = Vec::new();
    big_arr.push(b0.clone());
    big_arr.push(b1.clone());
    big_arr.push(b2.clone());
    big_arr.push(b3.clone());
    big_arr.push(b4.clone());
    big_arr.push(b5.clone());
    let poseidon = Poseidon::new();
    let h = poseidon.hash(big_arr.clone()).unwrap();
    return h.toString();
    /*assert_eq!(
        h.to_string(),
        "Fr(0x186a5454a7c47c73dfc74ac32ea40a57d27eeb4e2bfc6551dd7b66686d3fd1ab)" // "11043376183861534927536506085090418075369306574649619885724436265926427398571"
    );*/
}

#[no_mangle]
pub extern fn signPoseidon(private_key: *const c_char, message: *const c_char) -> Signature {
    let sk = private_key.to_bigint().unwrap();
    let pk = PrivateKey { key: sk };
    let msg = message.to_bigint().unwrap();
    let sig = pk.sign(msg.clone()).unwrap();
    return sig;
}

#[no_mangle]
pub extern fn verifyPoseidon(private_key: *const c_char, signature: &[u8; 64], message: *const c_char) -> bool {
    let sk = private_key.to_bigint().unwrap();
    let r_b8_bytes: [u8; 32] = *array_ref!(signature[..32], 0, 32);
    let s: BigInt = BigInt::from_bytes_le(Sign::Plus, &signature[32..]);
    let r_b8 = decompress_point(r_b8_bytes);
    let sig = Signature { r_b8 : r_b8.clone().unwrap(), s };
    let pk = PrivateKey { key: sk };
    let msg = message.to_bigint().unwrap();
    return verify(pk.public().unwrap(), sig.clone(), msg.clone());
}



/*#[no_mangle]
pub extern fn rust_greeting(to: *const c_char) -> *mut c_char {
    let c_str = unsafe { CStr::from_ptr(to) };
    let recipient = match c_str.to_str() {
        Err(_) => "there",
        Ok(string) => string,
    };

    CString::new("Hello ".to_owned() + recipient).unwrap().into_raw()
}*/