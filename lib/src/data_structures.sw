library;

pub type VaultId = u64;

pub enum TokenIdentifier {
    Input: u64,
    Output: u64,
    Caller: (),
}

pub struct VaultData {
    pub asset_id: AssetId,
    pub amount: u64,
}
