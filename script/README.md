# Deployment and Upgrade Scripts

This directory contains scripts for deploying and upgrading the Emblem Vault system.

## Environment Setup

Create a `.env` file with:

```env
# Required for all operations
PRIVATE_KEY=your_private_key
RPC_URL=your_rpc_url

# Required for diamond upgrades
DIAMOND_ADDRESS=deployed_diamond_address
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet,CollectionFacet

# Required for beacon upgrades
IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155
```

## Deployment Flow

1. First, deploy the Diamond system:

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url $RPC_URL --broadcast
```

This will:

- Deploy all facets (Core, Claim, Mint, Callback, Collection, etc.)
- Deploy the diamond
- Add all facets to the diamond
- Initialize the diamond
- Save deployment addresses to `.env.diamond`

2. Then, deploy the Beacon system:

```bash
forge script script/DeployBeaconSystem.s.sol:DeployBeaconSystem --rpc-url $RPC_URL --broadcast
```

This will:

- Deploy ERC721 and ERC1155 implementations
- Deploy beacons pointing to these implementations
- Deploy the VaultCollectionFactory
- Save deployment addresses to `.env.beacon`

3. After deployment, set the collection factory in the diamond:

```solidity
// Using the CollectionFacet through the diamond
EmblemVaultCollectionFacet(diamondAddress).setCollectionFactory(factoryAddress);
```

## Upgrade Flow

### Upgrading Diamond Facets

1. Set the facets to upgrade in `.env`:

```env
DIAMOND_ADDRESS=your_diamond_address
FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet,CollectionFacet
```

2. Run the upgrade script:

```bash
forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets --rpc-url $RPC_URL --broadcast
```

Available facets:

- CoreFacet
- ClaimFacet
- MintFacet
- CallbackFacet
- CollectionFacet

### Upgrading Beacon Implementations

1. Set the implementations to upgrade in `.env`:

```env
IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155
```

2. Run the upgrade script:

```bash
forge script script/UpgradeBeaconImplementations.s.sol:UpgradeBeaconImplementations --rpc-url $RPC_URL --broadcast
```

This will:

- Deploy new implementation(s)
- Upgrade the beacon(s) to point to new implementation(s)
- Update `.env.beacon` with new addresses

## Script Details

### DeployDiamondSystem.s.sol

- Deploys all facets and the diamond
- Adds facets to diamond with correct function selectors
- Initializes the diamond
- Saves addresses to `.env.diamond`

### DeployBeaconSystem.s.sol

- Deploys ERC721/ERC1155 implementations
- Deploys beacons pointing to implementations
- Deploys VaultCollectionFactory
- Saves addresses to `.env.beacon`

### UpgradeDiamondFacets.s.sol

- Deploys new versions of specified facets
- Updates diamond to use new facet implementations
- Maintains all function selectors during upgrade

### UpgradeBeaconImplementations.s.sol

- Deploys new versions of ERC721/ERC1155 implementations
- Updates beacons to point to new implementations
- Updates `.env.beacon` with new addresses

## Important Notes

1. Always verify the `.env` file has the correct addresses before running upgrade scripts.
2. The deployment scripts save addresses to `.env.diamond` and `.env.beacon` - keep these files safe.
3. When upgrading facets, ensure all function selectors are properly maintained.
4. When upgrading implementations, ensure they remain compatible with existing collections.
