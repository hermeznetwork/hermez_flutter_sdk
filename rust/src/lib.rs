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

use crate::eddsa::{Signature, decompress_point, Point};
use num_bigint::{Sign, BigInt};

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
pub extern fn decompress_signature(b: &[u8; 64]) -> Result<Signature, String> {
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

Result<Point, String>
pub extern fn unpack_point() -> Result<Point, String> {

}

#[no_mangle]
pub extern fn prv2pub(key: &[u8; 32]) -> Result<Point, String> {
    let prv: BigInt = BigInt::from_bytes_le(Sign::Plus, &key[..32]);
    let pk = B8.mul_scalar(&prv)?;
    Ok(pk.clone())
}