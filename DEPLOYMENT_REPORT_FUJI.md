# Emblem Vault Diamond System Deployment Report

## Diamond System Deployment (Avalanche Fuji Testnet)

### Deployment Command

```bash
forge script DeployDiamondSystem --rpc-url fuji -vvvv --broadcast --verify --slow --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' --etherscan-api-key "verifyContract"
```

### Diamond System Addresses

| Contract          | Address                                      | Link                                                                                    |
| ----------------- | -------------------------------------------- | --------------------------------------------------------------------------------------- |
| Diamond           | `0x161Ab371A04755cd2eb1963ca8373fea7Bf42d80` | [View](https://testnet.snowtrace.io/address/0x161Ab371A04755cd2eb1963ca8373fea7Bf42d80) |
| DiamondCutFacet   | `0x3007b326E3E03444dc247F8cA607F7579F32B153` | [View](https://testnet.snowtrace.io/address/0x3007b326E3E03444dc247F8cA607F7579F32B153) |
| DiamondLoupeFacet | `0xBf82b1826F95BD4a250bc3D91d076A166CDaE7Bc` | [View](https://testnet.snowtrace.io/address/0xBf82b1826F95BD4a250bc3D91d076A166CDaE7Bc) |
| OwnershipFacet    | `0x0Cf9C7b256F47D6aD6F9a2b4f85698Eff919FdAF` | [View](https://testnet.snowtrace.io/address/0x0Cf9C7b256F47D6aD6F9a2b4f85698Eff919FdAF) |
| CoreFacet         | `0x57F482f3af7b7bE52a8205a83c93cf09b60c4f5a` | [View](https://testnet.snowtrace.io/address/0x57F482f3af7b7bE52a8205a83c93cf09b60c4f5a) |
| ClaimFacet        | `0x20DA34794077D48743a7C3a24543c963140eec2A` | [View](https://testnet.snowtrace.io/address/0x20DA34794077D48743a7C3a24543c963140eec2A) |
| MintFacet         | `0x2995b2Cc55809626c6b925bE2D0Dc2cEF21596F7` | [View](https://testnet.snowtrace.io/address/0x2995b2Cc55809626c6b925bE2D0Dc2cEF21596F7) |
| CollectionFacet   | `0x188d5F2C731C5027A4D66f8aF015fD02E2c1b06B` | [View](https://testnet.snowtrace.io/address/0x188d5F2C731C5027A4D66f8aF015fD02E2c1b06B) |
| InitFacet         | `0x3CeDe8592D66B77948B5914d065D102502b9f069` | [View](https://testnet.snowtrace.io/address/0x3CeDe8592D66B77948B5914d065D102502b9f069) |

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
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url fuji -vvvv --broadcast --verify --slow --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' --etherscan-api-key "verifyContract"
```

### Implementation Addresses

| Contract                   | Address                                                                                                                         | Status     |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| ERC721VaultImplementation  | [`0x7Cd80cb11bc886653d0883988E338f18FD6949c2`](https://testnet.snowtrace.io/address/0x7Cd80cb11bc886653d0883988E338f18FD6949c2) | ✓ Verified |
| ERC1155VaultImplementation | [`0xF5f81E6d59a147b8c42A6d0224f92cE6cBCAD1dC`](https://testnet.snowtrace.io/address/0xF5f81E6d59a147b8c42A6d0224f92cE6cBCAD1dC) | ✓ Verified |

### Implementation Deployment Details

| Contract                   | Block    | Gas Used  | Cost (ETH)    |
| -------------------------- | -------- | --------- | ------------- |
| ERC721VaultImplementation  | 37159997 | 2,241,797 | 0.03001766183 |
| ERC1155VaultImplementation | 37159998 | 2,149,193 | 0.02877769427 |

## Beacon System Deployment

### Deployment Command

```bash
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url fuji -vvvv --broadcast --verify --slow --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' --etherscan-api-key "verifyContract"
```

### Beacon Addresses

| Contract           | Address                                                                                                                         | Status     |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| ERC721VaultBeacon  | [`0x4CEdFB5438F9C9EE79A76cB068A138FA9d4E62d0`](https://testnet.snowtrace.io/address/0x4CEdFB5438F9C9EE79A76cB068A138FA9d4E62d0) | ✓ Verified |
| ERC1155VaultBeacon | [`0x7F99C8BBC04767e4B79eF95B60AB256239C18f61`](https://testnet.snowtrace.io/address/0x7F99C8BBC04767e4B79eF95B60AB256239C18f61) | ✓ Verified |

### Beacon Deployment Details

| Contract           | Block    | Gas Used | Cost (ETH) |
| ------------------ | -------- | -------- | ---------- |
| ERC721VaultBeacon  | 37160134 | 270,145  | 0.00378203 |
| ERC1155VaultBeacon | 37160135 | 270,230  | 0.00378322 |

## Factory Deployment

### Factory Address

| Contract               | Address                                                                                                                         | Status     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| VaultCollectionFactory | [`0xC9cF92Dd6BA4C8fB7e9b3600C40fC483Fa696741`](https://testnet.snowtrace.io/address/0xC9cF92Dd6BA4C8fB7e9b3600C40fC483Fa696741) | ✓ Verified |

### Factory Deployment Details

| Contract               | Block    | Gas Used  | Cost (ETH)  |
| ---------------------- | -------- | --------- | ----------- |
| VaultCollectionFactory | 37160136 | 1,022,911 | 0.014320754 |

Total System Gas Used: 5,954,276
Total System Cost: 0.08068136 ETH

## Test Collections Deployment

### Deployment Command

```bash
forge script script/CreateTestCollections.s.sol:CreateTestCollections --rpc-url fuji -vvvv --broadcast --verify --slow --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' --etherscan-api-key "verifyContract"
```

### ERC721 Test Collection

| Property       | Value                                                                                                                           |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Address        | [`0x9D64037413969f3DF07E336Bd776B785f9c0Eb9D`](https://testnet.snowtrace.io/address/0x9D64037413969f3DF07E336Bd776B785f9c0Eb9D) |
| Name           | "Test ERC721 Vault Collection"                                                                                                  |
| Symbol         | "TEST721"                                                                                                                       |
| Base URI       | https://v2.emblemvault.io/meta/                                                                                                 |
| Owner          | Diamond (0x161Ab371A04755cd2eb1963ca8373fea7Bf42d80)                                                                            |
| Implementation | ERC721VaultImplementation (0x7Cd80cb11bc886653d0883988E338f18FD6949c2)                                                          |
| Beacon         | ERC721VaultBeacon (0x4CEdFB5438F9C9EE79A76cB068A138FA9d4E62d0)                                                                  |
| Block          | 37160242                                                                                                                        |
| Gas Used       | 406,264                                                                                                                         |
| Cost           | 0.0101566 ETH                                                                                                                   |
| Status         | ✓ Contract verified                                                                                                             |

### ERC1155 Test Collection

| Property       | Value                                                                                                                           |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Address        | [`0x11d871Cb9f7b7F7d83DCeAdc9c8e84B0aD63d8aa`](https://testnet.snowtrace.io/address/0x11d871Cb9f7b7F7d83DCeAdc9c8e84B0aD63d8aa) |
| URI            | https://api.emblem.finance/erc1155/metadata/{id}.json                                                                           |
| Owner          | Diamond (0x161Ab371A04755cd2eb1963ca8373fea7Bf42d80)                                                                            |
| Implementation | ERC1155VaultImplementation (0xF5f81E6d59a147b8c42A6d0224f92cE6cBCAD1dC)                                                         |
| Beacon         | ERC1155VaultBeacon (0x7F99C8BBC04767e4B79eF95B60AB256239C18f61)                                                                 |
| Block          | 37160243                                                                                                                        |
| Gas Used       | 381,593                                                                                                                         |
| Cost           | 0.009539825 ETH                                                                                                                 |
| Status         | ✓ Contract verified                                                                                                             |

Total Test Collections Gas Used: 787,857
Total Test Collections Cost: 0.019696425 ETH

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
- Diamond Address: `0x161Ab371A04755cd2eb1963ca8373fea7Bf42d80`
- Deployer Address: `0x107A120f536c8BD891A3c04fcA22a7814E260210`
- Gas Price: 13.39-25 gwei

## Deployment Order

1. Deploy Diamond system with all facets
2. Deploy and verify implementations
3. Deploy Beacon system connected to Diamond
4. Set factory in Diamond's CollectionFacet
5. Create test collections through Diamond
6. Verify all contracts on Snowtrace
7. System ready for production use

## Verification Status

All contracts have been successfully verified on Snowtrace:

- All Diamond facets ✓
- Both implementations ✓
- Both beacons ✓
- Factory ✓
- Both test collection proxies ✓

## Available Scripts

### Deployment Scripts

| Script                     | Description                                     | Command                                                                                                                     |
| -------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| DeployDiamondSystem        | Deploys complete Diamond system with all facets | `forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url fuji -vvvv --broadcast --verify`               |
| DeployVaultImplementations | Deploys ERC721/ERC1155 implementations          | `forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url fuji -vvvv --broadcast --verify` |
| DeployBeaconAndFactory     | Deploys beacons and factory                     | `forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url fuji -vvvv --broadcast --verify`         |
| CreateTestCollections      | Creates test ERC721/ERC1155 collections         | `forge script script/CreateTestCollections.s.sol:CreateTestCollections --rpc-url fuji -vvvv --broadcast --verify`           |

### Upgrade Scripts

| Script                       | Description                                | Command                                                                                                                         |
| ---------------------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| UpgradeDiamondFacets         | Upgrades specified Diamond facets          | `forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets --rpc-url fuji -vvvv --broadcast --verify`                 |
| UpgradeBeaconImplementations | Upgrades vault implementations             | `forge script script/UpgradeBeaconImplementations.s.sol:UpgradeBeaconImplementations --rpc-url fuji -vvvv --broadcast --verify` |
| DeployUpdatedFactory         | Deploys new factory using existing beacons | `forge script script/DeployUpdatedFactory.s.sol:DeployUpdatedFactory --rpc-url fuji -vvvv --broadcast --verify`                 |

### Management Scripts

| Script                  | Description             | Command                                                                                                                                                                               |
| ----------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| UpdateCollectionBaseURI | Updates collection URIs | `forge script script/UpdateCollectionBaseURI.s.sol:UpdateCollectionBaseURI --rpc-url fuji -vvvv --broadcast --verify --sig "run(address,string,uint8)" <collection> <new_uri> <type>` |
| SetupCollectionFactory  | Sets factory in Diamond | `forge script script/SetupCollectionFactory.s.sol:SetupCollectionFactory --rpc-url fuji -vvvv --broadcast --verify`                                                                   |

### Script Requirements

#### Environment Variables

Required in `.env` file:

```bash
# Required for all operations
PRIVATE_KEY=your_private_key
DEPLOYER_ADDRESS=your_deployer_address

# Required for upgrades
DIAMOND_ADDRESS=deployed_diamond_address
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet,CollectionFacet

# Required for beacon operations
ERC721_IMPLEMENTATION=implementation_address
ERC1155_IMPLEMENTATION=implementation_address
ERC721_BEACON=beacon_address
ERC1155_BEACON=beacon_address
COLLECTION_FACTORY_ADDRESS=factory_address

# Required for test collections
ERC721_COLLECTION=collection_address
ERC1155_COLLECTION=collection_address
```

#### Verification

All scripts support contract verification with:

- `--verify` flag
- `--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan'`
- `--etherscan-api-key "verifyContract"`

## Test Vaults

### Base URI Update

- Collection: `0x9D64037413969f3DF07E336Bd776B785f9c0Eb9D`
- New Base URI: `ipfs://Qmer52AeUTA26MWcCfdYVMuzdTmdXNbExfMaTJkgUeZKPR/`
- Transaction: `0x1da7614bba8e06f5e979f6e1ca6bd8ba30f1fe98cf6ece07150daa70dde2a64a`
- Gas Used: 118,517
- Cost: 0.000142220400118517 ETH

### Minted Vaults

1. Empty Vault (Token ID 1)

   - Owner: `0x107A120f536c8BD891A3c04fcA22a7814E260210`
   - Contents: None
   - URI: `ipfs://Qmer52AeUTA26MWcCfdYVMuzdTmdXNbExfMaTJkgUeZKPR/1`

2. ERC20 Vault (Token ID 2)

   - Owner: `0x107A120f536c8BD891A3c04fcA22a7814E260210`
   - Contents: 1 USDC.e (`0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E`)
   - URI: `ipfs://Qmer52AeUTA26MWcCfdYVMuzdTmdXNbExfMaTJkgUeZKPR/2`
   - Transaction: `0x0964198e37f59b82a13b0728e9b485fb6f756610fcbb109af1cdbe9210ce891d`
   - Gas Used: 183,697
   - Cost: 0.000505166750183697 ETH

3. ERC721 Vault (Token ID 3)
