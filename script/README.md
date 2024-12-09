# Deployment and Upgrade Scripts

This directory contains scripts for deploying and upgrading the Emblem Vault system.

## Environment Setup

Create a `.env` file with:

```env
PRIVATE_KEY=your_private_key
RPC_URL=your_rpc_url

# For diamond upgrades
DIAMOND_ADDRESS=deployed_diamond_address
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet

# For beacon upgrades
IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155
```

## Scripts

### 1. Deploy Diamond System

Deploys the complete diamond system with all facets.

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url $RPC_URL --broadcast
```

This will:

- Deploy all facets
- Deploy the diamond
- Add all facets to the diamond
- Initialize the diamond

### 2. Deploy Beacon System

Deploys the complete beacon system for vault collections.

```bash
forge script script/DeployBeaconSystem.s.sol:DeployBeaconSystem --rpc-url $RPC_URL --broadcast
```

This will:

- Deploy ERC721 and ERC1155 implementations
- Deploy beacons pointing to these implementations
- Deploy the VaultCollectionFactory
- Save all addresses to `.env.beacon`

### 3. Upgrade Diamond Facets

Upgrades specific facets in the diamond system.

```bash
# Set which facets to upgrade in .env:
# FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet

forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets --rpc-url $RPC_URL --broadcast
```

Available facets:

- CoreFacet
- ClaimFacet
- MintFacet
- CallbackFacet
- CollectionFacet

### 4. Upgrade Beacon Implementations

Upgrades ERC721 and/or ERC1155 implementations.

```bash
# Set which implementations to upgrade in .env:
# IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155

forge script script/UpgradeBeaconImplementations.s.sol:UpgradeBeaconImplementations --rpc-url $RPC_URL --broadcast
```

This will:

- Deploy new implementation(s)
- Upgrade the beacon(s) to point to new implementation(s)
- Update `.env.beacon` with new addresses

## Deployment Flow

1. First time deployment:

```bash
# Deploy diamond system
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url $RPC_URL --broadcast

# Deploy beacon system
forge script script/DeployBeaconSystem.s.sol:DeployBeaconSystem --rpc-url $RPC_URL --broadcast
```

2. Upgrading facets:

```bash
# Set FACETS_TO_UPGRADE in .env
forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets --rpc-url $RPC_URL --broadcast
```

3. Upgrading implementations:

```bash
# Set IMPLEMENTATIONS_TO_UPGRADE in .env
forge script script/UpgradeBeaconImplementations.s.sol:UpgradeBeaconImplementations --rpc-url $RPC_URL --broadcast
```
