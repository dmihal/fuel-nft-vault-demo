use fuels::prelude::abigen;

abigen!(
    Contract(
        name = "Vault",
        abi = "./contracts/vault/out/debug/vault-abi.json"
    ),
    Contract(
        name = "TestUserWallet",
        abi = "./contracts/test_user_wallet/out/debug/test_user_wallet-abi.json"
    ),
    Script(
        name = "DepositScript",
        abi = "./scripts/deposit_script/out/debug/deposit_script-abi.json"
    ),
);
