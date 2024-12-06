use fuels::prelude::abigen;

abigen!(
    Contract(
        name = "Vault",
        abi = "./contracts/vault/out/debug/vault-abi.json"
    ),
);
