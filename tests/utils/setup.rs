use fuels::{
    prelude::*,
    core::codec::EncoderConfig,
};
use super::abis::{Vault, DepositScript, DepositScriptConfigurables};

pub const ETH_ASSET: AssetId = AssetId::new([0u8; 32]);
pub const OTHER_ASSET: AssetId = AssetId::new([1u8; 32]);

pub struct Fixture {
    pub provider: Provider,
    pub wallet: WalletUnlocked,
    pub vault: Vault<WalletUnlocked>,
    pub deposit_script: DepositScript<WalletUnlocked>,
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

    let bin_path = "./scripts/deposit_script/out/debug/deposit_script.bin";
    let deposit_script = DepositScript::new(wallet.clone(), &bin_path)
        .with_configurables(DepositScriptConfigurables::new(EncoderConfig::default())
            .with_VAULT_CONTRACT_ADDRESS(vault.id().into())
            .unwrap());

    Fixture {
        provider,
        wallet,
        vault,
        deposit_script,
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
