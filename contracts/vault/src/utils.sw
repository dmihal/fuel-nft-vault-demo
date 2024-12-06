library;

use std::{
    address::Address,
    asset_id::AssetId,
    error_signals::FAILED_TRANSFER_TO_ADDRESS_SIGNAL,
    revert::revert,
    outputs::{output_amount, output_count, output_type, Output, GTF_OUTPUT_COIN_ASSET_ID},
    option::Option::{self, *},
    tx::{
        GTF_CREATE_OUTPUT_AT_INDEX,
        GTF_CREATE_OUTPUTS_COUNT,
        GTF_SCRIPT_OUTPUT_AT_INDEX,
        GTF_SCRIPT_OUTPUTS_COUNT,
        Transaction,
        tx_type,
    },
};

pub fn transfer(to: Identity, asset_id: AssetId, amount: u64) -> Option<u64> {
    match to {
        Identity::Address(addr) => Some(transfer_to_address(addr, asset_id, amount)),
        Identity::ContractId(id) => {
            force_transfer_to_contract(id, asset_id, amount);
            None
        },
    }
}

fn force_transfer_to_contract(to: ContractId, asset_id: AssetId, amount: u64) {
    asm(r1: amount, r2: asset_id, r3: to.bits()) {
        tr r3 r1 r2;
    }
}

// Update the function from std-lib to return the output index
pub fn transfer_to_address(to: Address, asset_id: AssetId, amount: u64) -> u64 {
    // maintain a manual index as we only have `while` loops in sway atm:
    let mut index = 0;

    // If an output of type `OutputVariable` is found, check if its `amount` is
    // zero. As one cannot transfer zero coins to an output without a panic, a
    // variable output with a value of zero is by definition unused.
    let number_of_outputs = output_count().as_u64();
    while index < number_of_outputs {
        if let Some(Output::Variable) = output_type(index) {
            if let Some(0) = output_amount(index) {
                asm(r1: to.bits(), r2: index, r3: amount, r4: asset_id) {
                    tro r1 r2 r3 r4;
                };
                return index;
            }
        }
        index += 1;
    }

    revert(FAILED_TRANSFER_TO_ADDRESS_SIGNAL);

    0
}

pub fn output_asset_id(index: u64) -> Option<AssetId> {
    match output_type(index) {
        Some(Output::Coin) => Some(AssetId::from(__gtf::<b256>(index, GTF_OUTPUT_COIN_ASSET_ID))),
        Some(Output::Change) => Some(AssetId::from(__gtf::<b256>(index, GTF_OUTPUT_COIN_ASSET_ID))),
        Some(Output::Variable) => {
            let ptr = output_pointer(index).unwrap();
            let buffer = b256::zero();
            Some(
                AssetId::from(
                    asm(r1: buffer, r2, r3: ptr) {
                        addi r2 r3 i48;
                        mcpi r1 r2 i32;
                        r1: b256
                    },
                )
            )
        }
        _ => None,
    }
}

fn output_pointer(index: u64) -> Option<raw_ptr> {
    if output_type(index).is_none() {
        return None
    }

    match tx_type() {
        Transaction::Script => Some(__gtf::<raw_ptr>(index, GTF_SCRIPT_OUTPUT_AT_INDEX)),
        Transaction::Create => Some(__gtf::<raw_ptr>(index, GTF_CREATE_OUTPUT_AT_INDEX)),
        Transaction::Upgrade => Some(__gtf::<raw_ptr>(index, GTF_SCRIPT_OUTPUT_AT_INDEX)),
        Transaction::Upload => Some(__gtf::<raw_ptr>(index, GTF_SCRIPT_OUTPUT_AT_INDEX)),
        Transaction::Blob => Some(__gtf::<raw_ptr>(index, GTF_SCRIPT_OUTPUT_AT_INDEX)),
        _ => None,
    }
}
