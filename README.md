# Emblem Vault Diamond System

A modular and upgradeable vault system built on the EIP-2535 Diamond Standard, allowing for the creation and management of NFT vaults that can hold various digital assets.

## Features

- **Diamond Architecture**: Upgradeable facets for system functionality
- **Beacon System**: Upgradeable vault implementations
- **Factory Pattern**: Standardized collection deployment
- **Vault Types**: Support for both ERC721 and ERC1155 vaults
- **Asset Support**: Store ERC20, ERC721, and ERC1155 tokens in vaults
- **Witness System**: Secure minting through verified signatures
- **Gas Optimized**: Efficient proxy patterns and storage

## Deployed Contracts (Mainnet)

### Diamond System

**Diamond Address:** `0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60`

#### Core Facets

- **DiamondCutFacet:** `0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39`
- **DiamondLoupeFacet:** `0x50197F900Fed0E25Ccfc7Cc0c38354B2193572aB`
- **OwnershipFacet:** `0x9f8c10D32B4db3BEceEA1Fe0B3b91F43ab26d733`

#### Functional Facets

- **CoreFacet:** `0xEE483847aa8E52887A1C5477b8F5b0af28922681`
- **MintFacet:** `0xA137e2d3DeC0874512C8A71E7Ab176b6FaCB165d`
- **UnvaultFacet:** `0x79B66cf2f6b90f2Ee837c7eB41163F7725B56B25` (Replaced ClaimFacet)
- **InitFacet:** `0x5657a10c1AAe46Ae383342d7516290B4FecD9295`
- **CollectionFacet:** `0x76060779BF7164B40A63588C01d0E632B213A726`

### Vault Implementations

- **ERC721VaultImplementation:** `0x15086dd99D696AA6b0A036424Fb6Ad4923508a94`
- **ERC1155VaultImplementation:** `0xD35A23C5CFf0fe663F4357218c2B9b104399B659`

### Beacon System

- **ERC721VaultBeacon:** `0x8977704a454fE2063336324027440d7bc56689AA`
- **ERC1155VaultBeacon:** `0x2B05d2Ec965E10DB70EEeE8a62FFc39e399601A6`
- **VaultCollectionFactory:** `0x109De29e0FB4de58A66ce077253E0604D81AD14C`

### Collections

- **Diamond Hands Collection (ERC721A):** `0xAfE0130Bad95763A66871e1F2fd73B8e7ee18037`

## Documentation

- [System Architecture](docs/SystemArchitecture.md) - Complete system design and components
- [Deployment Guide](docs/DeploymentGuide.md) - Step-by-step deployment instructions
- [Minting Guide](docs/MintingGuide.md) - How to create and manage vaults
- [Upgrade Guide](docs/UpgradeGuide.md) - System upgrade procedures

## Quick Start

1. Install dependencies:

```bash
forge install
```

2. Set up environment:

```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Deploy system:

```bash
# Deploy Diamond system
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url <network> -vvvv --broadcast

# Deploy implementations and beacons
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url <network> -vvvv --broadcast
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url <network> -vvvv --broadcast

# Create test collections
forge script script/CreateTestCollections.s.sol:CreateTestCollections --rpc-url <network> -vvvv --broadcast
```

## Scripts

### Deployment

- `DeployDiamondSystem.s.sol` - Deploy complete Diamond system
- `DeployVaultImplementations.s.sol` - Deploy vault implementations
- `DeployBeaconAndFactory.s.sol` - Deploy beacons and factory
- `CreateTestCollections.s.sol` - Create test collections

### Management

- `MintTestVaults.s.sol` - Mint test vaults
- `UpdateCollectionBaseURI.s.sol` - Update collection URIs
- `SetupCollectionFactory.s.sol` - Configure factory in Diamond

### Upgrades

- `UpgradeDiamondFacets.s.sol` - Upgrade Diamond facets
- `UpgradeBeaconImplementations.s.sol` - Upgrade vault implementations
- `DeployUpdatedFactory.s.sol` - Deploy new factory

## Testing

Run the test suite:

```bash
forge test
```

Key test files:

- `DiamondBeaconIntegration.t.sol` - Integration tests
- `BeaconSystem.t.sol` - Beacon system tests
- `DiamondVault.t.sol` - Vault functionality tests

## Architecture

```
contracts/
├── facets/           # Diamond facets
├── implementations/  # Vault implementations
├── beacon/           # Beacon system
├── factories/        # Collection factory
├── interfaces/       # Contract interfaces
└── libraries/        # Shared libraries
```

## Security

- All contracts use OpenZeppelin libraries
- Diamond storage pattern prevents collisions
- Comprehensive test coverage
- Access control through Diamond owner
- Witness system for minting security

## License

MIT
