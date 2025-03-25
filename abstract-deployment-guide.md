# Abstract Layer 2 Deployment Guide for Emblem Vault Diamond

This guide provides specific commands for deploying your Emblem Vault Diamond project to Abstract Layer 2.

## Prerequisites

- Private key for deployment account with sufficient funds on Abstract Layer 2
- Abstract Layer 2 RPC URL (typically https://rpc.abstract.xyz)
- Abstract Explorer API key (if needed for verification)

## Deployment Steps

### 1. Deploy Vault Implementations

```bash
# Deploy ERC721 and ERC1155 vault implementations
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/DeployVaultImplementations.s.sol --rpc-url https://rpc.abstract.xyz --private-key <PRIVATE_KEY> --broadcast
```

### 2. Deploy Beacon and Factory

```bash
# Deploy beacon and factory system
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/DeployBeaconAndFactory.s.sol --rpc-url https://rpc.abstract.xyz --private-key <PRIVATE_KEY> --broadcast
```

### 3. Deploy Diamond System

```bash
# Deploy the main diamond system
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/DeployDiamondSystem.s.sol --rpc-url https://rpc.abstract.xyz --private-key <PRIVATE_KEY> --broadcast
```

### 4. Create Priority Collections (if needed)

```bash
# Create priority collections
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/CreatePriorityCollections.s.sol --rpc-url https://rpc.abstract.xyz --private-key <PRIVATE_KEY> --broadcast
```

## Contract Verification

After deployment, verify your contracts on the Abstract Explorer:

```bash
# Verify Diamond contract
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync verify-contract <DIAMOND_ADDRESS> EmblemVaultDiamond --chain-id <ABSTRACT_CHAIN_ID> --verifier-url https://explorer.abstract.xyz/api --etherscan-api-key <API_KEY>

# Verify ERC721 Implementation
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync verify-contract <ERC721_IMPL_ADDRESS> ERC721VaultImplementation --chain-id <ABSTRACT_CHAIN_ID> --verifier-url https://explorer.abstract.xyz/api --etherscan-api-key <API_KEY>

# Verify ERC1155 Implementation
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync verify-contract <ERC1155_IMPL_ADDRESS> ERC1155VaultImplementation --chain-id <ABSTRACT_CHAIN_ID> --verifier-url https://explorer.abstract.xyz/api --etherscan-api-key <API_KEY>
```

## Deployment Verification

You can inspect the deployed diamond using:

```bash
# Inspect diamond
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/InspectDiamondSimple.s.sol --rpc-url https://rpc.abstract.xyz
```

## Troubleshooting

If you encounter issues with the deployment:

1. Check that your account has sufficient funds on Abstract Layer 2
2. Ensure you're using the correct RPC URL for Abstract
3. Verify that all dependencies are properly installed
4. Check the deployment logs for specific error messages

For verification issues:

1. Make sure you're using the correct contract address and name
2. Ensure your source code matches exactly what was deployed
3. Check that you're using the correct chain ID for Abstract Layer 2

## Notes

- Store your deployment addresses in a secure location
- Consider creating a deployment report file similar to your existing reports in the deployment-reports directory
- For upgrades or modifications after initial deployment, use the UpgradeDiamondFacets.s.sol script
