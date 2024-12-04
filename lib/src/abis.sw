library;

use ::data_structures::{TokenIdentifier, VaultId};

abi Vault {
    #[storage(read, write)]
    fn create_vault(asset: AssetId, recipient: Identity) -> (VaultId, Option<u64>);

    #[payable]
    #[storage(read, write)]
    fn deposit_assets(vault_id: VaultId, vault_token: TokenIdentifier);

    #[storage(read, write)]
    fn withdraw_assets(vault_id: VaultId, vault_token: TokenIdentifier, amount: u64, recipient: Identity);
}
