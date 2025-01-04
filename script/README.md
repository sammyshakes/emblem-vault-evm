# Deployment and Upgrade Scripts

This directory contains scripts for deploying and upgrading the Emblem Vault system.

## Environment Setup

Create a `.env` file with:

```env
# Required for all operations
PRIVATE_KEY=your_private_key
DEPLOYER_ADDRESS=0x107A120f536c8BD891A3c04fcA22a7814E260210

# Network RPC URLs
FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc

# Diamond System Addresses
DIAMOND_ADDRESS=0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d
DIAMOND_CUT_FACET=0xB9797497Ed43153a8EB4a3417168F4376b4a24A9
DIAMOND_LOUPE_FACET=0xF619706cDA244Be007082a6C1f624279B343821d
OWNERSHIP_FACET=0x8dBaEb6c4FD7477927D1D90c4640E3DEdE3c1E23
CORE_FACET=0xc566d12e81f86554dd82F1d1Ae63b03707500085
CLAIM_FACET=0x360e976192440c11F06dbaCd8C87077376c74b1D
MINT_FACET=0xDB2Cb754330b542E2808FdeD5A4C7C8274c07B7a
COLLECTION_FACET=0x18b3be2FBF408e29787fda1D77eC53e1B22Ad1Bc
INIT_FACET=0xe691Dfe8efd784Dcf0Eb09F689f7b7F2Ec1d3237

# Implementation Addresses
ERC721_IMPLEMENTATION=0xAb5A5667253F5452EeF8cCD3bF2BD890144695e6
ERC1155_IMPLEMENTATION=0xd2343E5e80434995772c64f1c073B2CF0311D4a8

# Beacon System Addresses
ERC721_BEACON=0xeCb9dcfBEe7A450B967ADc72110DBca614eE1904
ERC1155_BEACON=0xDd8C66d318aF05A3162F6Bed3CeD6fD63f7358e8
COLLECTION_FACTORY_ADDRESS=0xeD6Bbdf42C18643c4c5Cd9903899f518BB72f16E

# Test Collection Addresses
ERC721_COLLECTION=0x12a84432093C56D9235C7cd390Bb6A7adDA78301
ERC1155_COLLECTION=0x8D4f8238a9b9Aaaf8246c2C79Ad4596D1EAE14aF

# Upgrade Configuration
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet,CollectionFacet
IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155
```

## Deployment Flow

1. First, deploy the Diamond system:

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url fuji --broadcast --verify --slow -vvvv
```

This will:

- Deploy all facets (Core, Claim, Mint, Collection, etc.)
- Deploy the diamond
- Add all facets to the diamond
- Initialize the diamond

2. Then, deploy the Vault implementations:

```bash
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url fuji --broadcast --verify --slow -vvvv
```

This will:

- Deploy ERC721 and ERC1155 implementations
- Verify implementations on Snowtrace

3. Deploy beacons and factory:

```bash
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url fuji --broadcast --verify --slow -vvvv
```

This will:

- Deploy beacons pointing to implementations
- Deploy the VaultCollectionFactory
- Set factory in Diamond's CollectionFacet

4. Create collections:

For ERC721A collections:

```bash
forge script script/CreateERC721Collection.s.sol:CreateERC721Collection --rpc-url mainnet --broadcast --verify --slow -vvvv
```

For ERC1155 collections:

```bash
forge script script/CreateERC1155Collection.s.sol:CreateERC1155Collection --rpc-url mainnet --broadcast --verify --slow -vvvv
```

Each script will:

- Create the specified collection type
- Verify the collection is properly registered
- Display the collection address and metadata URI

5. Mint test vault:

```bash
forge script script/MintTestVaults.s.sol:MintTestVaults --rpc-url fuji --broadcast --verify --slow -vvvv --sig "mintEmptyVault(address,uint256)" <collection_address> <token_id>
```

Example:

```bash
forge script script/MintTestVaults.s.sol:MintTestVaults --rpc-url fuji --broadcast --verify --slow -vvvv --sig "mintEmptyVault(address,uint256)" 0x12a84432093C56D9235C7cd390Bb6A7adDA78301 1
```

## Upgrade Flow

### Upgrading Diamond Facets

1. Set the facets to upgrade in `.env`:

```env
DIAMOND_ADDRESS=0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet,CollectionFacet
```

2. Run the upgrade script:

```bash
forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets --rpc-url fuji --broadcast --verify --slow -vvvv
```

### Upgrading Beacon Implementations

1. Set the implementations to upgrade in `.env`:

```env
IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155
```

2. Run the upgrade script:

```bash
forge script script/UpgradeBeaconImplementations.s.sol:UpgradeBeaconImplementations --rpc-url fuji --broadcast --verify --slow -vvvv
```

### Updating Collection URIs

The system supports updating URIs for both ERC721 and ERC1155 collections:

1. For ERC721 collections:

```bash
forge script script/UpdateCollectionBaseURI.s.sol:UpdateCollectionBaseURI --rpc-url fuji --broadcast --verify --slow -vvvv --sig "run(address,string,uint8)" 0x12a84432093C56D9235C7cd390Bb6A7adDA78301 "https://api.emblem.finance/erc721/metadata/" 1
```

2. For ERC1155 collections:

```bash
forge script script/UpdateCollectionBaseURI.s.sol:UpdateCollectionBaseURI --rpc-url fuji --broadcast --verify --slow -vvvv --sig "run(address,string,uint8)" 0x8D4f8238a9b9Aaaf8246c2C79Ad4596D1EAE14aF "https://api.emblem.finance/erc1155/metadata/{id}.json" 2
```

Required environment variables:

```env
DIAMOND_ADDRESS=0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d
ERC721_COLLECTION=0x12a84432093C56D9235C7cd390Bb6A7adDA78301
ERC1155_COLLECTION=0x8D4f8238a9b9Aaaf8246c2C79Ad4596D1EAE14aF
```

### Factory Updates

Deploy a new factory using existing beacons:

```bash
forge script script/DeployUpdatedFactory.s.sol:DeployUpdatedFactory --rpc-url fuji --broadcast --verify --slow -vvvv
```

Required environment variables:

```env
DIAMOND_ADDRESS=0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d
COLLECTION_FACTORY_ADDRESS=0xeD6Bbdf42C18643c4c5Cd9903899f518BB72f16E
ERC721_BEACON=0xeCb9dcfBEe7A450B967ADc72110DBca614eE1904
ERC1155_BEACON=0xDd8C66d318aF05A3162F6Bed3CeD6fD63f7358e8
```

### Batch Collection Updates

Update multiple collections and URIs in one transaction:

```bash
forge script script/UpdateCollectionsAndURIs.s.sol:UpdateCollectionsAndURIs --rpc-url fuji --broadcast --verify --slow -vvvv
```

Required environment variables:

```env
DIAMOND_ADDRESS=0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d
COLLECTION_FACTORY_ADDRESS=0xeD6Bbdf42C18643c4c5Cd9903899f518BB72f16E
ERC721_COLLECTION=0x12a84432093C56D9235C7cd390Bb6A7adDA78301
ERC1155_COLLECTION=0x8D4f8238a9b9Aaaf8246c2C79Ad4596D1EAE14aF
```

## Important Notes

1. Always verify the `.env` file has the correct addresses before running scripts
2. When upgrading facets, ensure all function selectors are properly maintained
3. When upgrading implementations, ensure they remain compatible with existing collections
4. When updating URIs, ensure the new URIs are properly formatted and accessible
5. For ERC1155 collections, the URI must include the `{id}` placeholder for token IDs
