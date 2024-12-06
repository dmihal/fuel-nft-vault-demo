mod utils;

use fuels::{
    prelude::*,
    programs::responses::CallResponse,
    types::{Bits256, ContractId, output::Output},
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

#[tokio::test]
async fn can_create_and_deposit_same_tx() {
    let fixture = setup().await;

    let inputs = fixture.wallet.get_asset_inputs_for_amount(OTHER_ASSET, 100, None).await.unwrap();
    let outputs = vec![
        Output::change(fixture.wallet.address().into(), 0, OTHER_ASSET),
    ];

    let result = fixture.deposit_script
        .main(OTHER_ASSET, 100, fixture.wallet.address())
        .with_inputs(inputs)
        .with_outputs(outputs)
        .with_variable_output_policy(VariableOutputPolicy::Exactly(1))
        .with_contracts(&[&fixture.vault])
        .call()
        .await
        .unwrap();

    let vault_id = result.value;
    let vault_asset_id = fixture.vault.id().asset_id(&Bits256(u64_to_u8_32(vault_id)));

    let tx = fixture.vault.methods()
        .withdraw_assets(vault_id, TokenIdentifier::Input(1), 100, fixture.wallet.address().into())
        .add_custom_asset(vault_asset_id, 1, Some(fixture.wallet.address().clone()))
        .with_variable_output_policy(VariableOutputPolicy::Exactly(1))
        .call()
        .await
        .unwrap();
}
