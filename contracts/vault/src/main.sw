contract;

mod events;
mod utils;

use std::{
    asset::{mint},
    auth::{caller_is_external, caller_contract_id},
    call_frames::msg_asset_id,
    context::{msg_amount, balance_of},
    hash::Hash,
    inputs::{input_amount, input_asset_id},
    outputs::{output_amount, output_asset_id},
    registers::global_gas,
    tx::tx_id,
};
use events::*;
use lib::abis::Vault;
use lib::data_structures::*;
use lib::u64_to_subid;
use utils::transfer;

storage {
    next_vault_id: VaultId = 0,
    vaults: StorageMap<VaultId, VaultData> = StorageMap {},
}

enum Error {
    AlreadyJoinedCampaign: (),
    InvalidAsset: (),
    InvalidTokenId: (),
    InvalidTokenAmount: (),
    InsufficientvaultCampaignsProvided: (),
    MustBeCalledFromContract: (),
    MustBeCalledFromScript: (),
}

impl Vault for Contract {
    #[storage(read, write)]
    fn create_vault(asset: AssetId, recipient: Identity) -> (VaultId, Option<u64>) {
        let vault_id = storage.next_vault_id.read();
        storage.next_vault_id.write(vault_id + 1);
        
        let vault = VaultData {
            asset_id: asset,
            amount: 0,
        };
        storage.vaults.insert(vault_id, vault);

        log(NewVaultEvent {
            vault_id,
            asset_id: asset,
        });

        let vault_sub_id = u64_to_subid(vault_id);
        let vault_asset_id = AssetId::new(ContractId::this(), vault_sub_id);
        mint(vault_sub_id, 1);
        let output_index = transfer(recipient, vault_asset_id, 1);

        (vault_id, output_index)
    }

    #[payable]
    #[storage(read, write)]
    fn deposit_assets(vault_id: VaultId, vault_token: TokenIdentifier) {
        validate_token(vault_id, vault_token);

        let mut vault = storage.vaults.get(vault_id).read();
        require(vault.asset_id == msg_asset_id(), Error::InvalidAsset);

        vault.amount += msg_amount();
        storage.vaults.insert(vault_id, vault);

        log(DepositEvent {
            vault_id,
            amount: msg_amount(),
        });
    }

    #[storage(read, write)]
    fn withdraw_assets(vault_id: VaultId, vault_token: TokenIdentifier, amount: u64, recipient: Identity) {
        validate_token(vault_id, vault_token);

        let mut vault = storage.vaults.get(vault_id).read();
        vault.amount -= amount;
        storage.vaults.insert(vault_id, vault);

        let _ = transfer(recipient, vault.asset_id, amount);

        log(WithdrawEvent {
            vault_id,
            amount: msg_amount(),
            recipient,
        });
    }
}

fn validate_token(vault_id: VaultId, token: TokenIdentifier) {
    let expected_asset_id = AssetId::new(ContractId::this(), u64_to_subid(vault_id));

    let (asset_id, amount) = match token {
        TokenIdentifier::Input(idx) => (input_asset_id(idx), input_amount(idx)),
        TokenIdentifier::Output(idx) => (output_asset_id(idx), output_amount(idx)),
        TokenIdentifier::Caller => {
            require(!caller_is_external(), Error::MustBeCalledFromContract);
            let caller = caller_contract_id();
            let balance = balance_of(caller, expected_asset_id);
            require(balance == 1, Error::InvalidTokenAmount);
            return;
        }
    };
    require(caller_is_external(), Error::MustBeCalledFromScript);
    require(asset_id.is_some() && asset_id.unwrap() == expected_asset_id, Error::InvalidTokenId);
    require(amount.is_some() && amount.unwrap() == 1, Error::InvalidTokenAmount);
}
