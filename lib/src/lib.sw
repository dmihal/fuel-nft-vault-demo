library;

pub mod abis;
pub mod data_structures;

pub fn u64_to_subid(num: u64) -> SubId {
    let num_u256: u256 = num.into();
    SubId::from(num_u256)
}
