pub mod abis;
pub mod setup;

use fuels::types::errors::{
  Error,
  transaction::Reason,
};

pub fn u64_to_u8_32(num: u64) -> [u8; 32] {
  let mut arr = [0u8; 32]; // Initialize a zeroed array
  arr[..8].copy_from_slice(&num.to_le_bytes()); // Copy the bytes of the u64 (little-endian) into the array
  arr
}

pub fn assert_revert_containing_msg(msg: &str, error: Error) {
  if let Error::Transaction(reason) = error {
    if let Reason::Reverted { reason, .. } = reason {
      assert!(
        reason.contains(msg),
        "message: \"{msg}\" not contained in reason: \"{reason}\""
      );
      return;
    }
  }
  panic!("Error was not a RevertTransactionError");
}
