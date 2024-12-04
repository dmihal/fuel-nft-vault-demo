library;

use std::{
    address::Address,
    asset_id::AssetId,
    error_signals::FAILED_TRANSFER_TO_ADDRESS_SIGNAL,
    revert::revert,
    outputs::{output_amount, output_count, output_type, Output},
    option::Option::{self, *},
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
