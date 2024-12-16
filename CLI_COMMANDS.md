# Emblem Vault System CLI Commands

## Environment Setup

```bash
# Install dependencies
forge install

# Copy and edit environment file
cp .env.example .env
```

## Deployment Commands

### 1. Diamond System

```bash
# Deploy Diamond system with verification
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem \
--rpc-url fuji -vvvv --broadcast --verify \
--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
--etherscan-api-key "verifyContract"
```

### 2. Vault Implementations

```bash
# Deploy and verify implementations
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations \
--rpc-url fuji -vvvv --broadcast --verify \
--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
--etherscan-api-key "verifyContract"
```

### 3. Beacon System

```bash
# Deploy beacons and factory
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory \
--rpc-url fuji -vvvv --broadcast --verify \
--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
--etherscan-api-key "verifyContract"
```

### 4. Test Collections

```bash
# Create test collections
forge script script/CreateTestCollections.s.sol:CreateTestCollections \
--rpc-url fuji -vvvv --broadcast --verify \
--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
--etherscan-api-key "verifyContract"
```

## Upgrade Commands

### Diamond Facet Upgrades

```bash
# Upgrade specified facets
forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets \
--rpc-url fuji -vvvv --broadcast --verify \
--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
--etherscan-api-key "verifyContract"
```

### Implementation Upgrades

```bash
# Upgrade vault implementations
forge script script/UpgradeBeaconImplementations.s.sol:UpgradeBeaconImplementations \
--rpc-url fuji -vvvv --broadcast --verify \
--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
--etherscan-api-key "verifyContract"
```

### Factory Upgrades

```bash
# Deploy new factory
forge script script/DeployUpdatedFactory.s.sol:DeployUpdatedFactory \
--rpc-url fuji -vvvv --broadcast --verify \
--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
--etherscan-api-key "verifyContract"
```

## Management Commands

### Mint Test Vaults

```bash
# Mint ERC721 vault
forge script script/MintTestVaults.s.sol:MintTestVaults \
--rpc-url fuji -vvvv --broadcast \
--sig "mintVault(address,uint256,bytes)" \
<collection_address> \
<token_id> \
<vault_data>
```

### Update Collection URIs

```bash
# Update ERC721 collection URI
forge script script/UpdateCollectionBaseURI.s.sol:UpdateCollectionBaseURI \
--rpc-url fuji -vvvv --broadcast \
--sig "run(address,string,uint8)" \
<collection_address> \
<new_base_uri> \
1

# Update ERC1155 collection URI
forge script script/UpdateCollectionBaseURI.s.sol:UpdateCollectionBaseURI \
--rpc-url fuji -vvvv --broadcast \
--sig "run(address,string,uint8)" \
<collection_address> \
<new_uri> \
2
```

## Testing Commands

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/DiamondBeaconIntegration.t.sol

# Run with verbosity
forge test -vvvv

# Run with gas report
forge test --gas-report
```

## Contract Interaction

### Read Contract State

```bash
# Check collection status
cast call <factory_address> "isCollection(address)" <collection_address> --rpc-url fuji

# Get implementation address
cast call <beacon_address> "implementation()" --rpc-url fuji

# Check vault owner
cast call <collection_address> "owner()" --rpc-url fuji
```

### Write Contract State

```bash
# Transfer ownership
cast send <contract_address> "transferOwnership(address)" <new_owner> \
--private-key <your_private_key> --rpc-url fuji

# Set factory in Diamond
cast send <diamond_address> "setCollectionFactory(address)" <factory_address> \
--private-key <your_private_key> --rpc-url fuji
```

## Network Options

### Avalanche Fuji

```bash
--rpc-url fuji
--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan'
--etherscan-api-key "verifyContract"
```

### BSC Testnet

```bash
--rpc-url bsc_testnet
--verifier-url 'https://api-testnet.bscscan.com/api'
--etherscan-api-key <your_bscscan_api_key>
```
