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

use crate::eddsa::{Signature, decompress_point, Point, PrivateKey, verify, decompress_signature, compress_point, PointProjective};
use num_bigint::{Sign, BigInt, ToBigInt};
use std::os::raw::c_char;
use std::ffi::{CString, CStr};
use std::cmp::min;

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
pub extern fn pack_signature(signature: &[u8; 64]) -> [u8; 64] {
    let r_b8_bytes: [u8; 32] = *array_ref!(signature[..32], 0, 32);
    let s: BigInt = BigInt::from_bytes_le(Sign::Plus, &signature[32..]);
    let r_b8 = decompress_point(r_b8_bytes);
    let sig = Signature { r_b8 : r_b8.clone().unwrap(), s };
    let res = sig.compress();
    return res;
}

#[no_mangle]
pub extern fn unpack_signature(compressed_signature: &[u8; 64]) -> [u8; 64] {
    let decompressed_sig = decompress_signature(&compressed_signature).unwrap();
    let mut r: [u8; 64] = [0; 64];
    let r_b8_bytes = compress_point(&decompressed_sig.r_b8);
    let (_, s_bytes) = decompressed_sig.s.to_bytes_le();
    let len = min(s_bytes.len(), r.len());
    r[..len].copy_from_slice(&s_bytes[..len]);
    if &x_big > &(&Q.clone() >> 1) {
        r[63] = r[63] | 0x80;
    }
    r
}

#[no_mangle]
pub extern fn pack_point(point: &[u8; 64]) -> [u8; 32] {
    let x_big: BigInt = BigInt::from_bytes_le(Sign::Plus, &point[..32]);
    let y_big: BigInt = BigInt::from_bytes_le(Sign::Plus, &point[32..]);
    let mut r: [u8; 32] = [0; 32];
    let (_, y_bytes) = y_big.to_bytes_le();
    let len = min(y_bytes.len(), r.len());
    r[..len].copy_from_slice(&y_bytes[..len]);
    if &x_big > &(&Q.clone() >> 1) {
        r[31] = r[31] | 0x80;
    }
    r
}

#[no_mangle]
pub extern fn unpack_point(point: &[u8; 32]) -> [u8; 64] {
    let r_b8_bytes: [u8; 32] = *array_ref!(point[..32], 0, 32);
    let r_b8 = decompress_point(r_b8_bytes);
    let p = r_b8.unwrap();
    let mut r: [u8; 64] = [0; 64];
    let mut x_vec = to_hex(&p.x).as_bytes();
    let mut y_vec =  to_hex(&p.y).as_bytes();
    x_vec.
    x_vec.append(&mut y_vec);
    /*let x_big = BigInt::parse_bytes(, 16).unwrap();
    let y_big = BigInt::parse_bytes(to_hex(&p.y).as_bytes(), 16).unwrap();
    let (_, y_bytes) = y_big.to_bytes_le();
    let len = min(y_bytes.len(), r.len());
    r[..len].copy_from_slice(&y_bytes[..len]);
    if &x_big > &(&Q.clone() >> 1) {
        r[31] = r[31] | 0x80;
    }
    r*/
}

#[no_mangle]
pub extern fn prv2pub(private_key: *const c_char) -> [u8; 32] {
    let sk = private_key.to_bigint().unwrap();
    let pk = B8.mul_scalar(&sk)?;
    let mut r: [u8; 32] = [0; 32];
    let x_big = BigInt::parse_bytes(to_hex(&pk.x).as_bytes(), 16).unwrap();
    let y_big = BigInt::parse_bytes(to_hex(&pk.y).as_bytes(), 16).unwrap();
    let (_, y_bytes) = y_big.to_bytes_le();
    let len = min(y_bytes.len(), r.len());
    r[..len].copy_from_slice(&y_bytes[..len]);
    if &x_big > &(&Q.clone() >> 1) {
        r[31] = r[31] | 0x80;
    }
    r
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
}

#[no_mangle]
pub extern fn signPoseidon(private_key: *const c_char, message: *const c_char) -> [u8; 64] {
    let sk = private_key.to_bigint().unwrap();
    let pk = PrivateKey { key: sk };
    let msg = message.to_bigint().unwrap();
    let sig = pk.sign(msg.clone()).unwrap();
    return sig.compress();
}

#[no_mangle]
pub extern fn verifyPoseidon(private_key: *const c_char, signature: &[u8; 64], message: *const c_char) -> int8 {
    let sk = private_key.to_bigint().unwrap();
    let r_b8_bytes: [u8; 32] = *array_ref!(signature[..32], 0, 32);
    let s: BigInt = BigInt::from_bytes_le(Sign::Plus, &signature[32..]);
    let r_b8 = decompress_point(r_b8_bytes);
    let sig = Signature { r_b8 : r_b8.clone().unwrap(), s };
    let pk = PrivateKey { key: sk };
    let msg = message.to_bigint().unwrap();
    return if verify(pk.public().unwrap(), sig.clone(), msg.clone()) {
        1
    } else {
        0
    }
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