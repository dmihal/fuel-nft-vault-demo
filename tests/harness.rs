mod utils;

use fuels::{
    prelude::*,
    types::{Bits256, ContractId},
};
use utils::{
    abis::TokenIdentifier,
    assert_revert_containing_msg,
    setup::{setup, ETH_ASSET, OTHER_ASSET},
    u64_to_u8_32,
};

#[tokio::test]
async fn can_deposit_and_withdraw() {
    let fixture = setup().await;

    let result = fixture.vault.methods()
        .create_vault(OTHER_ASSET, fixture.wallet.address().into())
        .with_variable_output_policy(VariableOutputPolicy::Exactly(1))
        .call()
        .await
        .unwrap();

    let (position_id, _) = result.value;

    let position_asset_id = fixture.vault.id().asset_id(&Bits256(u64_to_u8_32(position_id)));

    let err = fixture.vault.methods()
        .deposit_assets(position_id, TokenIdentifier::Input(2))
        .call_params(CallParameters::default().with_asset_id(OTHER_ASSET).with_amount(100))
        .unwrap()
        .call()
        .await
        .err()
        .unwrap();
    assert_revert_containing_msg("InvalidTokenId", err);

    let tx = fixture.vault.methods()
        .deposit_assets(position_id, TokenIdentifier::Input(2))
        .call_params(CallParameters::default().with_asset_id(OTHER_ASSET).with_amount(100))
        .unwrap()
        .add_custom_asset(position_asset_id, 1, Some(fixture.wallet.address().clone()))
        .call()
        .await
        .unwrap();

    let tx = fixture.vault.methods()
        .withdraw_assets(position_id, TokenIdentifier::Input(1), 100, fixture.wallet.address().into())
        .add_custom_asset(position_asset_id, 1, Some(fixture.wallet.address().clone()))
        .with_variable_output_policy(VariableOutputPolicy::Exactly(1))
        .call()
        .await
        .unwrap();
}
