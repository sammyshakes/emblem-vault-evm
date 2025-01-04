# Emblem Vault Diamond System Deployment Report

## Diamond System Deployment (Avalanche Fuji Testnet)

### Deployment Command

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url fuji --broadcast --verify --slow -vvvv
```

### Diamond System Addresses

| Contract          | Address                                      | Link                                                                                    |
| ----------------- | -------------------------------------------- | --------------------------------------------------------------------------------------- |
| Diamond           | `0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d` | [View](https://testnet.snowtrace.io/address/0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d) |
| DiamondCutFacet   | `0xB9797497Ed43153a8EB4a3417168F4376b4a24A9` | [View](https://testnet.snowtrace.io/address/0xB9797497Ed43153a8EB4a3417168F4376b4a24A9) |
| DiamondLoupeFacet | `0xF619706cDA244Be007082a6C1f624279B343821d` | [View](https://testnet.snowtrace.io/address/0xF619706cDA244Be007082a6C1f624279B343821d) |
| OwnershipFacet    | `0x8dBaEb6c4FD7477927D1D90c4640E3DEdE3c1E23` | [View](https://testnet.snowtrace.io/address/0x8dBaEb6c4FD7477927D1D90c4640E3DEdE3c1E23) |
| CoreFacet         | `0xc566d12e81f86554dd82F1d1Ae63b03707500085` | [View](https://testnet.snowtrace.io/address/0xc566d12e81f86554dd82F1d1Ae63b03707500085) |
| ClaimFacet        | `0x360e976192440c11F06dbaCd8C87077376c74b1D` | [View](https://testnet.snowtrace.io/address/0x360e976192440c11F06dbaCd8C87077376c74b1D) |
| MintFacet         | `0xDB2Cb754330b542E2808FdeD5A4C7C8274c07B7a` | [View](https://testnet.snowtrace.io/address/0xDB2Cb754330b542E2808FdeD5A4C7C8274c07B7a) |
| CollectionFacet   | `0x18b3be2FBF408e29787fda1D77eC53e1B22Ad1Bc` | [View](https://testnet.snowtrace.io/address/0x18b3be2FBF408e29787fda1D77eC53e1B22Ad1Bc) |
| InitFacet         | `0xe691Dfe8efd784Dcf0Eb09F689f7b7F2Ec1d3237` | [View](https://testnet.snowtrace.io/address/0xe691Dfe8efd784Dcf0Eb09F689f7b7F2Ec1d3237) |

### Diamond System Features

- EIP-2535 Diamond Standard implementation
- Modular facet architecture for upgradeable functionality
- Integrated ownership and access control
- Support for both ERC721 and ERC1155 vault collections
- Advanced claiming and minting capabilities
- Collection management through dedicated facets

## Vault Implementation Deployment

### Deployment Command

```bash
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url fuji --broadcast --verify --slow -vvvv
```

### Implementation Addresses

| Contract                   | Address                                                                                                                         | Status     |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| ERC721VaultImplementation  | [`0xAb5A5667253F5452EeF8cCD3bF2BD890144695e6`](https://testnet.snowtrace.io/address/0xAb5A5667253F5452EeF8cCD3bF2BD890144695e6) | ✓ Verified |
| ERC1155VaultImplementation | [`0xd2343E5e80434995772c64f1c073B2CF0311D4a8`](https://testnet.snowtrace.io/address/0xd2343E5e80434995772c64f1c073B2CF0311D4a8) | ✓ Verified |

### Implementation Deployment Details

| Contract                   | Block    | Gas Used  | Cost (ETH)           |
| -------------------------- | -------- | --------- | -------------------- |
| ERC721VaultImplementation  | 37282952 | 2,241,797 | 0.003923146135430546 |
| ERC1155VaultImplementation | 37282953 | 2,717,812 | 0.004756172679607816 |

## Beacon System Deployment

### Deployment Command

```bash
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url fuji --broadcast --verify --slow -vvvv
```

### Beacon Addresses

| Contract           | Address                                                                                                                         | Status     |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| ERC721VaultBeacon  | [`0xeCb9dcfBEe7A450B967ADc72110DBca614eE1904`](https://testnet.snowtrace.io/address/0xeCb9dcfBEe7A450B967ADc72110DBca614eE1904) | ✓ Verified |
| ERC1155VaultBeacon | [`0xDd8C66d318aF05A3162F6Bed3CeD6fD63f7358e8`](https://testnet.snowtrace.io/address/0xDd8C66d318aF05A3162F6Bed3CeD6fD63f7358e8) | ✓ Verified |

### Beacon Deployment Details

| Contract           | Block    | Gas Used | Cost (ETH)          |
| ------------------ | -------- | -------- | ------------------- |
| ERC721VaultBeacon  | 37283049 | 270,145  | 0.00029715966694961 |
| ERC1155VaultBeacon | 37283053 | 270,230  | 0.00029725316700214 |

## Factory Deployment

### Factory Address

| Contract               | Address                                                                                                                         | Status     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| VaultCollectionFactory | [`0xeD6Bbdf42C18643c4c5Cd9903899f518BB72f16E`](https://testnet.snowtrace.io/address/0xeD6Bbdf42C18643c4c5Cd9903899f518BB72f16E) | ✓ Verified |

### Factory Deployment Details

| Contract               | Block    | Gas Used  | Cost (ETH)           |
| ---------------------- | -------- | --------- | -------------------- |
| VaultCollectionFactory | 37283055 | 1,022,911 | 0.001125202732158998 |

## Test Collections Deployment

### Deployment Command

```bash
forge script script/CreateTestCollections.s.sol:CreateTestCollections --rpc-url fuji --broadcast --verify --slow -vvvv
```

### ERC721 Test Collection

| Property       | Value                                                                                                                           |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Address        | [`0x12a84432093C56D9235C7cd390Bb6A7adDA78301`](https://testnet.snowtrace.io/address/0x12a84432093C56D9235C7cd390Bb6A7adDA78301) |
| Name           | "Test ERC721 Vault Collection"                                                                                                  |
| Symbol         | "TEST721"                                                                                                                       |
| Base URI       | https://v2.emblemvault.io/meta/                                                                                                 |
| Owner          | Diamond (0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d)                                                                            |
| Implementation | ERC721VaultImplementation (0xAb5A5667253F5452EeF8cCD3bF2BD890144695e6)                                                          |
| Beacon         | ERC721VaultBeacon (0xeCb9dcfBEe7A450B967ADc72110DBca614eE1904)                                                                  |
| Block          | 37283093                                                                                                                        |
| Gas Used       | 406,264                                                                                                                         |
| Cost           | 0.0007515884 ETH                                                                                                                |
| Status         | ✓ Contract verified                                                                                                             |

### ERC1155 Test Collection

| Property       | Value                                                                                                                           |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Address        | [`0x8D4f8238a9b9Aaaf8246c2C79Ad4596D1EAE14aF`](https://testnet.snowtrace.io/address/0x8D4f8238a9b9Aaaf8246c2C79Ad4596D1EAE14aF) |
| URI            | https://api.emblem.finance/erc1155/metadata/{id}.json                                                                           |
| Owner          | Diamond (0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d)                                                                            |
| Implementation | ERC1155VaultImplementation (0xd2343E5e80434995772c64f1c073B2CF0311D4a8)                                                         |
| Beacon         | ERC1155VaultBeacon (0xDd8C66d318aF05A3162F6Bed3CeD6fD63f7358e8)                                                                 |
| Block          | 37283094                                                                                                                        |
| Gas Used       | 381,382                                                                                                                         |
| Cost           | 0.0007055567 ETH                                                                                                                |
| Status         | ✓ Contract verified                                                                                                             |

## Test Vaults

### Minted Vaults

1. Empty Vault (Token ID 1)
   - Collection: 0x12a84432093C56D9235C7cd390Bb6A7adDA78301 (ERC721)
   - Owner: 0x107A120f536c8BD891A3c04fcA22a7814E260210
   - Block: 37283121
   - Gas Used: 197,792
   - Cost: 0.000237350400197792 ETH
   - Status: ✓ Minted successfully

## Utility Scripts

### Diamond Facet Upgrades

```bash
forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets --rpc-url fuji --broadcast --verify --slow -vvvv
```

Required environment variables:

```env
DIAMOND_ADDRESS=0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet,CollectionFacet
```

### Beacon Implementation Upgrades

```bash
forge script script/UpgradeBeaconImplementations.s.sol:UpgradeBeaconImplementations --rpc-url fuji --broadcast --verify --slow -vvvv
```

Required environment variables:

```env
IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155
ERC721_BEACON=0xeCb9dcfBEe7A450B967ADc72110DBca614eE1904
ERC1155_BEACON=0xDd8C66d318aF05A3162F6Bed3CeD6fD63f7358e8
```

### Collection URI Updates

1. Update ERC721 Collection URI:

```bash
forge script script/UpdateCollectionBaseURI.s.sol:UpdateCollectionBaseURI --rpc-url fuji --broadcast --verify --slow -vvvv --sig "run(address,string,uint8)" 0x12a84432093C56D9235C7cd390Bb6A7adDA78301 "https://api.emblem.finance/erc721/metadata/" 1
```

2. Update ERC1155 Collection URI:

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

## System Architecture

### Diamond System

- Core Diamond contract acts as the central proxy
- Modular facets provide specific functionality
- Upgradeable design through DiamondCut mechanism
- Integrated with Beacon system for collection management

### Beacon System

- Implements EIP-1967 beacon proxy pattern
- Separate implementations for ERC721 and ERC1155 vaults
- Factory pattern for standardized collection deployment
- Direct integration with Diamond for access control

## System Capabilities

### Diamond Permissions

- Create collections through factory
- Update beacon implementations
- Own all created collections
- Manage facet upgrades
- Control system access and ownership

### Factory Capabilities

- Create collections when called by Diamond
- Track and verify collections
- Provide collection information
- Standardize collection deployment

## Deployment Configuration

- Network: Avalanche Fuji Testnet (Chain ID: 43113)
- Diamond Address: 0x79AC7f72699a2938A975b873FB2Fbef86f5D6e4d
- Deployer Address: 0x107A120f536c8BD891A3c04fcA22a7814E260210
- Gas Price: 1.2-2.85 gwei

## Deployment Order

1. Deploy Diamond system with all facets
2. Deploy and verify implementations
3. Deploy Beacon system connected to Diamond
4. Create test collections through Diamond
5. Mint test vault
6. Verify all contracts on Snowtrace
7. System ready for production use

## Verification Status

All contracts have been successfully verified on Snowtrace:

- All Diamond facets ✓
- Both implementations ✓
- Both beacons ✓
- Factory ✓
- Both test collection proxies ✓
