# Fuel NFT Vault

This repo shows a demo of how to use an NFT asset to represent "ownership" in a Sway smart contract. The example contract implements a simple asset "vault", where users can deposit and withdraw an asset.

## Description

**Basic usage**

A user first calls the `create_vault` method, which will generate a new "vault ID", and mint an NFT to the user's address.

When the user wants to deposit funds, they'll call the `deposit_assets` method with the assets to deposit. They must also include the NFT in the transaction, by "transferring" the NFT to the same address. The `vault_token` parameter of the function call will "point" to the input, using the `Input` option of the `TokenIdentifier`, which will indicate the input index of the NFT.

When a user wants to withdraw funds, they repeat the same process, but calling the `withdraw_assets` method.

**Bundled calls**

Applications will typically want to make the process of creating a vault transparent to users by bundling the calls to `create_vault` and `deposit_assets` in the same transaction. This repo contains a script `deposit_script` which chains these two calls together. When using the two calls in the same transaction, the NFT asset is just being minted, therefore the `vault_token` must point to the _output_ as opposed to the _input_.

**Use with smart contracts**

Normal accounts (EOAs and predicates) can use the vault by referencing their coins as inputs or outputs. However, the vault can also be interacted with by other smart contracts. If a smart contract holds a vault NFT, it can call `deposit_assets` or `withdraw_assets` and simply set the `vault_token` value to `TokenIdentifier::Caller`. The vault contract will read the calling contract's asset balance to validate the state of the NFT.

## Advantages over `msg_sender()`

Developers who switch from developing on the EVM/Solidity to developing on Fuel/Sway will typically use the `msg_sender()` function, which aims to emulate the functionality of Solidity's `msg.sender` value.

This technique provides many advantages over using the `msg_sender`
