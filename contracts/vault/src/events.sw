library;

use lib::data_structures::VaultId;

pub struct NewVaultEvent {
    pub vault_id: VaultId,
    pub asset_id: AssetId,
}

pub struct DepositEvent {
    pub vault_id: VaultId,
    pub amount: u64,
}

pub struct WithdrawEvent {
    pub vault_id: VaultId,
    pub amount: u64,
    pub recipient: Identity,
}
