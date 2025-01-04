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

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
