# Deployment and Upgrade Scripts

This directory contains scripts for deploying and upgrading the Emblem Vault system.

## Environment Setup

Create a `.env` file with:

```env
# Required for all operations
PRIVATE_KEY=deployer_private_key
DEPLOYER_ADDRESS=deployer_public_key

# Network RPC URLs
MAINNET_RPC_URL=
BSC_RPC_URL=
BSC_TESTNET_RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545/
FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc

# API Keys
ETHERSCAN_API_KEY=

# Diamond System Addresses (populate after deployment)
DIAMOND_ADDRESS=
DIAMOND_CUT_FACET=
DIAMOND_LOUPE_FACET=
OWNERSHIP_FACET=
CORE_FACET=
CLAIM_FACET=
MINT_FACET=
COLLECTION_FACET=
INIT_FACET=

# Implementation Addresses
ERC721_IMPLEMENTATION=
ERC1155_IMPLEMENTATION=

# Beacon System Addresses
ERC721_BEACON=
ERC1155_BEACON=
COLLECTION_FACTORY_ADDRESS=

# Test Collection Addresses
ERC721_COLLECTION=
ERC1155_COLLECTION=

# Upgrade Configuration
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet,CollectionFacet
IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155
```

## Deployment Flow

1. First, deploy the Diamond system:

```bash
forge script DeployDiamondSystem --rpc-url fuji --broadcast --verify --slow -vvvv
```

This will:

- Deploy all facets (Core, Unvault, Mint, Collection, etc.)
- Deploy the diamond
- Add all facets to the diamond
- Initialize the diamond

2. Then, deploy the Vault implementations:

```bash
forge script DeployVaultImplementations --rpc-url fuji --broadcast --verify --slow -vvvv
```

This will:

- Deploy ERC721 and ERC1155 implementations
- Verify implementations on Snowtrace

3. Deploy beacons and factory:

```bash
forge script DeployBeaconAndFactory --rpc-url fuji --broadcast --verify --slow -vvvv
```

This will:

- Deploy beacons pointing to implementations
- Deploy the VaultCollectionFactory
- Set factory in Diamond's CollectionFacet

4. Create collections:

For ERC721A collections:

```bash
forge script CreateERC721Collection --rpc-url mainnet --broadcast --verify --slow -vvvv
```

For ERC1155 collections:

```bash
forge script CreateERC1155Collection --rpc-url mainnet --broadcast --verify --slow -vvvv
```

Each script will:

- Create the specified collection type
- Verify the collection is properly registered
- Display the collection address and metadata URI

5. Mint test vault:

```bash
forge script MintTestVaults --rpc-url fuji --broadcast --verify --slow -vvvv --sig "mintEmptyVault(address,uint256)" <collection_address> <token_id>
```

Example:

```bash
forge script MintTestVaults --rpc-url fuji --broadcast --verify --slow -vvvv --sig "mintEmptyVault(address,uint256)" 0x12a84432093C56D9235C7cd390Bb6A7adDA78301 1
```

## Upgrade Flow

### Upgrading Diamond Facets

1. Set the facets to upgrade in `.env`:

```env
DIAMOND_ADDRESS=
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet,CollectionFacet
```

2. Run the upgrade script:

```bash
forge script UpgradeDiamondFacets --rpc-url fuji --broadcast --verify --slow -vvvv
```

### Upgrading Beacon Implementations

1. Set the implementations to upgrade in `.env`:

```env
IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155
```

2. Run the upgrade script:

```bash
forge script UpgradeBeaconImplementations --rpc-url fuji --broadcast --verify --slow -vvvv
```

### Updating Collection URIs

The system supports updating URIs for both ERC721 and ERC1155 collections:

1. For ERC721 collections:

```bash
forge script UpdateCollectionBaseURI --rpc-url fuji --broadcast --verify --slow -vvvv --sig "run(address,string,uint8)" 0x12a84432093C56D9235C7cd390Bb6A7adDA78301 "https://api.emblem.finance/erc721/metadata/" 1
```

2. For ERC1155 collections:

```bash
forge script UpdateCollectionBaseURI --rpc-url fuji --broadcast --verify --slow -vvvv --sig "run(address,string,uint8)" 0x8D4f8238a9b9Aaaf8246c2C79Ad4596D1EAE14aF "https://api.emblem.finance/erc1155/metadata/{id}.json" 2
```

Required environment variables:

```env
DIAMOND_ADDRESS=
ERC721_COLLECTION=
ERC1155_COLLECTION=
```

### Factory Updates

Deploy a new factory using existing beacons:

```bash
forge script DeployUpdatedFactory --rpc-url fuji --broadcast --verify --slow -vvvv
```

Required environment variables:

```env
DIAMOND_ADDRESS=
COLLECTION_FACTORY_ADDRESS=
ERC721_BEACON=
ERC1155_BEACON=
```

### Batch Collection Updates

Update multiple collections and URIs in one transaction:

```bash
forge script UpdateCollectionsAndURIs --rpc-url fuji --broadcast --verify --slow -vvvv
```

Required environment variables:

```env
DIAMOND_ADDRESS=
COLLECTION_FACTORY_ADDRESS=
ERC721_COLLECTION=
ERC1155_COLLECTION=
```

## Important Notes

1. Always verify the `.env` file has the correct addresses before running scripts
2. When upgrading facets, ensure all function selectors are properly maintained
3. When upgrading implementations, ensure they remain compatible with existing collections
4. When updating URIs, ensure the new URIs are properly formatted and accessible
5. For ERC1155 collections, the URI must include the `{id}` placeholder for token IDs
