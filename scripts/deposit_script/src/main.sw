script;

use lib::{
    abis::Vault,
    data_structures::{TokenIdentifier, VaultId},
};

configurable {
    VAULT_CONTRACT_ADDRESS: ContractId = ContractId::from(b256::zero()),
}

fn main(asset: AssetId, amount: u64, recipient: Address) -> VaultId {
    let vault = abi(Vault, VAULT_CONTRACT_ADDRESS.into());
    let (vault_id, output_index) = vault.create_vault(asset, Identity::Address(recipient));

    vault.deposit_assets{
        coins: amount,
        asset_id: asset.into(),
    }(vault_id, TokenIdentifier::Output(output_index.unwrap()));

    vault_id
}
