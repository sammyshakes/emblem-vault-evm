# Emblem Vault System

A modular and upgradeable vault system using the Diamond Pattern and Beacon Proxy Pattern.

## Overview

The system consists of two main components:

1. Diamond System

   - Core vault functionality through upgradeable facets
   - Handles vault operations, claims, minting, and callbacks

2. Beacon System
   - Collection contracts (ERC721/ERC1155) that can mint individual vaults
   - Uses beacon proxy pattern for upgradeability

## Installation

1. Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. Clone the repository:

```bash
git clone https://github.com/your-org/emblem-vault.git
cd emblem-vault
```

3. Install dependencies:

```bash
forge install
```

## Environment Setup

Create a `.env` file with:

```env
# Required for all operations
PRIVATE_KEY=your_private_key
RPC_URL=your_rpc_url

# Required for Etherscan verification
ETHERSCAN_API_KEY=your_etherscan_key

# Required for diamond upgrades
DIAMOND_ADDRESS=deployed_diamond_address
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet

# Required for beacon upgrades
IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155

# Optional - for specific network deployments
MAINNET_RPC_URL=
GOERLI_RPC_URL=
POLYGON_RPC_URL=
MUMBAI_RPC_URL=
```

## Running Tests

Run all tests:

```bash
forge test
```

Run specific test file:

```bash
forge test --match-path test/DiamondVault.t.sol
```

Run with verbosity for more details:

```bash
forge test -vvv
```

Run with gas reporting:

```bash
forge test --gas-report
```

## Deployment

The system requires deploying both the Diamond and Beacon systems. See [script/README.md](script/README.md) for detailed deployment instructions.

Quick start:

1. Deploy Diamond System:

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url $RPC_URL --broadcast
```

2. Deploy Beacon System:

```bash
forge script script/DeployBeaconSystem.s.sol:DeployBeaconSystem --rpc-url $RPC_URL --broadcast
```

## Upgrading

1. Upgrade Diamond Facets:

```bash
# Set FACETS_TO_UPGRADE in .env first
forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets --rpc-url $RPC_URL --broadcast
```

2. Upgrade Beacon Implementations:

```bash
# Set IMPLEMENTATIONS_TO_UPGRADE in .env first
forge script script/UpgradeBeaconImplementations.s.sol:UpgradeBeaconImplementations --rpc-url $RPC_URL --broadcast
```

## Project Structure

```
emblem-vault/
├── src/
│   ├── beacon/           # Beacon proxy system
│   ├── facets/          # Diamond facets
│   ├── factories/       # Collection factory
│   ├── implementations/ # ERC721/ERC1155 implementations
│   ├── interfaces/      # Contract interfaces
│   └── libraries/       # Shared libraries
├── test/
│   ├── BeaconSystem.t.sol    # Beacon system tests
│   ├── BeaconVault.t.sol     # Beacon proxy tests
│   └── DiamondVault.t.sol    # Diamond system tests
├── script/
│   ├── DeployDiamondSystem.s.sol
│   ├── DeployBeaconSystem.s.sol
│   ├── UpgradeDiamondFacets.s.sol
│   └── UpgradeBeaconImplementations.s.sol
└── docs/                # Additional documentation
```

## Key Components

1. Diamond System

   - EmblemVaultDiamond: Main diamond contract
   - Facets: Core functionality split into upgradeable facets
   - LibDiamond: Diamond storage and cut functionality

2. Beacon System
   - VaultCollectionFactory: Creates collection contracts
   - VaultBeacon: Upgradeable beacon for implementations
   - ERC721/ERC1155 Implementations: Collection contract logic

## Testing Coverage

The system includes comprehensive tests:

1. DiamondVault.t.sol (17 tests)

   - Core vault functionality
   - Facet interactions
   - Access control

2. BeaconVault.t.sol (10 tests)

   - Proxy functionality
   - Implementation upgrades
   - Initialization

3. BeaconSystem.t.sol (11 tests)
   - Collection creation
   - Vault minting
   - Serial number tracking

## Documentation

Additional documentation can be found in:

- [script/README.md](script/README.md) - Deployment and upgrade instructions
- [docs/BEACON_DIAMOND_INTEGRATION.md](docs/BEACON_DIAMOND_INTEGRATION.md) - System architecture
- [docs/DIAMOND_VAULT_IMPROVEMENTS.md](docs/DIAMOND_VAULT_IMPROVEMENTS.md) - Improvement proposals

## License

MIT
