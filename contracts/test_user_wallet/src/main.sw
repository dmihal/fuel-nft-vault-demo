contract;

use lib::{
    abis::Vault,
    data_structures::{TokenIdentifier, VaultId},
};

configurable {
    VAULT_CONTRACT_ADDRESS: ContractId = ContractId::from(b256::zero()),
}

abi TestUserWallet {
    fn deposit(vault_id: u64, asset: AssetId, amount: u64);

    fn withdraw(vault_id: u64, amount: u64, recipient: Identity);
}

impl TestUserWallet for Contract {
    fn deposit(vault_id: u64, asset: AssetId, amount: u64) {
        let vault = abi(Vault, VAULT_CONTRACT_ADDRESS.into());

        vault.deposit_assets{
            coins: amount,
            asset_id: asset.into(),
        }(vault_id, TokenIdentifier::Caller);
    }

    fn withdraw(vault_id: u64, amount: u64, recipient: Identity) {
        let vault = abi(Vault, VAULT_CONTRACT_ADDRESS.into());

        vault.withdraw_assets(vault_id, TokenIdentifier::Caller, amount, recipient);
    }
}
