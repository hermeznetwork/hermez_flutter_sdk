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
use std::str;

use crate::eddsa::{Signature, decompress_point, Point, PrivateKey, verify, decompress_signature, compress_point,PointProjective, Q};
use num_bigint::{Sign, BigInt, ToBigInt};
use std::os::raw::{c_char};
use std::ffi::{CStr, CString};
use std::cmp::min;
use std::str::FromStr;

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
    let x_big: BigInt = BigInt::from_bytes_le(Sign::Plus, &r_b8_bytes[..16]);
    let y_big: BigInt = BigInt::from_bytes_le(Sign::Plus, &r_b8_bytes[16..]);

    let r_b8: Point = Point {
        x: Fr::from_str(
            &x_big.to_string(),
        ).unwrap(),
        y: Fr::from_str(
            &y_big.to_string(),
        ).unwrap(),
    };

    let sig = Signature { r_b8 : r_b8.clone(), s };
    let res = sig.compress();
    return res;
}

#[no_mangle]
pub extern fn unpack_signature(compressed_signature: &[u8; 64]) -> [u8; 64] {
    let decompressed_sig = decompress_signature(&compressed_signature).unwrap();

    let mut b: Vec<u8> = Vec::new();

    let x_big = BigInt::parse_bytes(to_hex(&decompressed_sig.r_b8.x).as_bytes(), 16).unwrap();
    let y_big = BigInt::parse_bytes(to_hex(&decompressed_sig.r_b8.y).as_bytes(), 16).unwrap();
    let (_, x_bytes) = x_big.to_bytes_le();
    let (_, y_bytes) = y_big.to_bytes_le();

    let mut x_16bytes: [u8; 16] = [0; 16];
    let lenx = min(x_bytes.len(), x_16bytes.len());
    x_16bytes[..lenx].copy_from_slice(&x_bytes[..lenx]);
    b.append(&mut x_16bytes.to_vec());

    let mut y_16bytes: [u8; 16] = [0; 16];
    let leny = min(y_bytes.len(), y_16bytes.len());
    y_16bytes[..leny].copy_from_slice(&y_bytes[..leny]);
    b.append(&mut y_16bytes.to_vec());

    let (_, s_bytes) = decompressed_sig.s.to_bytes_le();
    let mut s_32bytes: [u8; 32] = [0; 32];
    let lens = min(s_bytes.len(), s_32bytes.len());
    s_32bytes[..lens].copy_from_slice(&s_bytes[..lens]);
    b.append(&mut s_32bytes.to_vec());

    let mut r: [u8; 64] = [0; 64];
    let res_len = min(r.len(), b.len());
    r[..res_len].copy_from_slice(&b[..res_len]);
    r
}

fn vector_as_u8_64_array(vector: Vec<u8>) -> [u8; 64] {
    let mut arr = [0u8;64];
    for (place, element) in arr.iter_mut().zip(vector.iter()) {
        *place = *element;
    }
    arr
}

#[no_mangle]
pub extern fn pack_point(point_x: *const c_char, point_y: *const c_char) -> *mut c_char {
    let point_x_cstr = unsafe { CStr::from_ptr(point_x) };
    let point_x_str = match point_x_cstr.to_str() {
        Err(_) => "there",
        Ok(string) => string,
    };
    let point_y_cstr = unsafe { CStr::from_ptr(point_y) };
    let point_y_str = match point_y_cstr.to_str() {
        Err(_) => "there",
        Ok(string) => string,
    };
    let p: Point = Point {
        x: Fr::from_str(point_x_str).unwrap(),
        y: Fr::from_str(point_y_str).unwrap(),
    };
    let compressed_point = compress_point(&p);
    let hex_string = to_hex_string(compressed_point.to_vec());
    CString::new(hex_string.as_str()).unwrap().into_raw()
}

pub fn to_hex_string(bytes: Vec<u8>) -> String {
    let strs: Vec<String> = bytes.iter()
        .map(|b| format!("{:02X}", b))
        .collect();
    strs.connect(" ")
}

#[no_mangle]
pub extern fn unpack_point(point: &[u8; 32]) -> [u8; 32] {
    let p_bytes: [u8; 32] = *array_ref!(point[..32], 0, 32);
    let r_b8 = decompress_point(p_bytes);
    let p = r_b8.unwrap();
    let mut r: [u8; 32] = [0; 32];
    let x_big = BigInt::parse_bytes(to_hex(&p.x).as_bytes(), 16).unwrap();
    let y_big = BigInt::parse_bytes(to_hex(&p.y).as_bytes(), 16).unwrap();
    let (_, y_bytes) = y_big.to_bytes_le();
    let len = min(y_bytes.len(), r.len());
    r[..len].copy_from_slice(&y_bytes[..len]);
    if &x_big > &(&Q.clone() >> 1) {
        r[31] = r[31] | 0x80;
    }
    r
}

#[no_mangle]
pub extern fn prv2pub(private_key: *const c_char) -> [u8; 32] {

    let private_key_str = unsafe { CStr::from_ptr(private_key) };
    //let sk: BigInt = BigInt::parse_bytes(private_key_str.to_bytes(), 16).unwrap();
    /*let y_big: BigInt = BigInt::parse_bytes(&point[32..], 10).unwrap();*/
    let sk = BigInt::from_bytes_be(Sign::Plus, private_key_str.to_bytes());
    let pk = B8.mul_scalar(&sk).unwrap();
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
pub extern fn hash_poseidon(tx_compressed_data: *const c_char, to_eth_addr: *const c_char, to_bjj_ay: *const c_char, rq_txcompressed_data_v2: *const c_char, rq_to_eth_addr: *const c_char, rq_to_bjj_ay: *const c_char) -> *const [u8] {
    let tx_compressed_data_str = unsafe { CStr::from_ptr(tx_compressed_data) }.to_str().unwrap();
    let b0: Fr = Fr::from_str(tx_compressed_data_str).unwrap();
    let to_eth_addr_str = unsafe { CStr::from_ptr(to_eth_addr) }.to_str().unwrap();
    let b1: Fr = Fr::from_str(to_eth_addr_str).unwrap();
    let to_bjj_ay_str = unsafe { CStr::from_ptr(to_bjj_ay) }.to_str().unwrap();
    let b2: Fr = Fr::from_str(to_bjj_ay_str).unwrap();
    let rq_txcompressed_data_v2_str = unsafe { CStr::from_ptr(rq_txcompressed_data_v2) }.to_str().unwrap();
    let b3: Fr = Fr::from_str(rq_txcompressed_data_v2_str).unwrap();
    let rq_to_eth_addr_str = unsafe { CStr::from_ptr(rq_to_eth_addr) }.to_str().unwrap();
    let b4: Fr = Fr::from_str(rq_to_eth_addr_str).unwrap();
    let rq_to_bjj_ay_str = unsafe { CStr::from_ptr(rq_to_bjj_ay) }.to_str().unwrap();
    let b5: Fr = Fr::from_str(rq_to_bjj_ay_str).unwrap();

    let mut big_arr: Vec<Fr> = Vec::new();
    big_arr.push(b0.clone());
    big_arr.push(b1.clone());
    big_arr.push(b2.clone());
    big_arr.push(b3.clone());
    big_arr.push(b4.clone());
    big_arr.push(b5.clone());
    let poseidon = Poseidon::new();
    let h = poseidon.hash(big_arr.clone()).unwrap();
    return h.to_string().as_bytes();
}

#[no_mangle]
pub extern fn sign_poseidon(private_key: *const c_char, message: *const c_char) -> [u8; 64] {
    let private_key_str = unsafe { CStr::from_ptr(private_key) }.to_str().unwrap();
    let sk = BigInt::from_str(private_key_str).unwrap();
    let pk = PrivateKey { key: sk };
    let message_str = unsafe { CStr::from_ptr(message) }.to_str().unwrap();
    let msg = BigInt::from_str(message_str).unwrap();
    let sig = pk.sign(msg.clone()).unwrap();
    return sig.compress();
}

#[no_mangle]
pub extern fn verify_poseidon(private_key: *const c_char, signature: &[u8; 64], message: *const c_char) -> c_char {
    let private_key_str = unsafe { CStr::from_ptr(private_key) }.to_str().unwrap();
    let sk = BigInt::from_str(private_key_str).unwrap();
    let r_b8_bytes: [u8; 32] = *array_ref!(signature[..32], 0, 32);
    let s: BigInt = BigInt::from_bytes_le(Sign::Plus, &signature[32..]);
    let r_b8 = decompress_point(r_b8_bytes);
    let sig = Signature { r_b8 : r_b8.clone().unwrap(), s };
    let pk = PrivateKey { key: sk };
    let message_str = unsafe { CStr::from_ptr(message) }.to_str().unwrap();
    let msg = BigInt::from_str(message_str).unwrap();
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