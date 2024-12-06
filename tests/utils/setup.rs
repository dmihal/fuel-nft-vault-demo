use fuels::{
    prelude::*,
};
use super::abis::{Vault};

pub const ETH_ASSET: AssetId = AssetId::new([0u8; 32]);
pub const OTHER_ASSET: AssetId = AssetId::new([1u8; 32]);

pub struct Fixture {
    pub provider: Provider,
    pub wallet: WalletUnlocked,
    pub vault: Vault<WalletUnlocked>,
}

pub async fn setup() -> Fixture {
    let num_wallets = 3;
    let initial_amount = 10_000_000_000_000_000;

    let asset_ids = [
        ETH_ASSET,
        OTHER_ASSET,
    ];
    let asset_configs = asset_ids
        .map(|id| AssetConfig {
            id,
            num_coins: 1,
            coin_amount: initial_amount,
        })
        .into();

    let wallets_config = WalletsConfig::new_multiple_assets(num_wallets, asset_configs);

    let wallets = launch_custom_provider_and_get_wallets(wallets_config, None, None).await.unwrap();
    let wallet = wallets[0].clone();
    let provider = wallet.provider().unwrap().clone();

    let vault = deploy_vault(&wallet).await;

    Fixture {
        provider,
        wallet,
        vault,
    }
}

async fn deploy_vault(wallet: &WalletUnlocked) -> Vault<WalletUnlocked> {
    let id = Contract::load_from(
        "./contracts/vault/out/debug/vault.bin",
        LoadConfiguration::default(),
    )
    .unwrap()
    .deploy(wallet, TxPolicies::default())
    .await
    .unwrap();

    Vault::new(id.clone(), wallet.clone())
}
