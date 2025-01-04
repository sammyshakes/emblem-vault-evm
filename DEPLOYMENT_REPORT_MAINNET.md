# Emblem Vault System Mainnet Deployment Report

Ethereum Mainnet Deployment - Chain ID: 1

## Deployment Environment

### Tools & Versions

- Foundry Framework
  - Forge: Used for contract compilation and deployment
  - Cast: Used for contract interaction
- Solidity Version: 0.8.28
- Node Version: Latest LTS

### Scripts Used

- `DeployDiamondSystem.s.sol`: Diamond system deployment
- `DeployVaultImplementations.s.sol`: Implementation contracts deployment
- `DeployBeaconAndFactory.s.sol`: Beacon system and factory deployment

### Deployment Parameters

- Network: Ethereum Mainnet
- Chain ID: 1
- Deployer Address: ${DEPLOYER_ADDRESS}

## Deployment Steps

### Step 1: Diamond System Deployment

1. Dry Run:

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url mainnet
```

2. Actual Deployment:

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url mainnet --broadcast --verify --slow -vvvv
```

After successful deployment, update .env with:

```env
DIAMOND_ADDRESS=
DIAMOND_CUT_FACET=
DIAMOND_LOUPE_FACET=
OWNERSHIP_FACET=
CORE_FACET=
CLAIM_FACET=
MINT_FACET=
COLLECTION_FACET=
INIT_FACET=
```

### Step 2: Vault Implementations Deployment

1. Dry Run:

```bash
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url mainnet
```

2. Actual Deployment:

```bash
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url mainnet --broadcast --verify --slow -vvvv
```

After successful deployment, update .env with:

```env
ERC721_IMPLEMENTATION=
ERC1155_IMPLEMENTATION=
```

### Step 3: Beacon and Factory Deployment

1. Dry Run:

```bash
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url mainnet
```

2. Actual Deployment:

```bash
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url mainnet --broadcast --verify --slow -vvvv
```

After successful deployment, update .env with:

```env
ERC721_BEACON=
ERC1155_BEACON=
COLLECTION_FACTORY_ADDRESS=
```

## Deployed Contracts

### Diamond System

- Diamond: (To be deployed)

  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

- DiamondCutFacet: (To be deployed)

  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

- DiamondLoupeFacet: (To be deployed)
  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

(Additional facets will be documented similarly)

### Vault Implementations

- ERC721VaultImplementation: (To be deployed)

  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

- ERC1155VaultImplementation: (To be deployed)
  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

### Beacon System

- ERC721VaultBeacon: (To be deployed)

  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

- ERC1155VaultBeacon: (To be deployed)

  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

- VaultCollectionFactory: (To be deployed)
  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

## Gas Reports

### Diamond System Deployment

(To be filled after dry run)

- Estimated total gas:
- Estimated cost at current gas price:

### Vault Implementations Deployment

(To be filled after dry run)

- Estimated total gas:
- Estimated cost at current gas price:

### Beacon System Deployment

(To be filled after dry run)

- Estimated total gas:
- Estimated cost at current gas price:

## Security Considerations

1. All contract ownership should be properly set to the deployer
2. Diamond storage slots should be properly initialized
3. Beacon implementations should be initialized with correct version numbers
4. Factory should be properly configured with beacon addresses
5. All facet functions should be accessible through the diamond

## Post-Deployment Verification Steps

1. Verify diamond initialization:

   ```bash
   cast call $DIAMOND_ADDRESS "owner()" --rpc-url mainnet
   ```

2. Verify facet function selectors:

   ```bash
   cast call $DIAMOND_ADDRESS "facets()" --rpc-url mainnet
   ```

3. Verify beacon implementation versions:

   ```bash
   cast call $ERC721_BEACON "implementation()" --rpc-url mainnet
   cast call $ERC1155_BEACON "implementation()" --rpc-url mainnet
   ```

4. Verify factory configuration:
   ```bash
   cast call $COLLECTION_FACTORY_ADDRESS "getBeacon(uint8)" --rpc-url mainnet
   ```

## Notes

- Each step requires updating environment variables before proceeding to the next
- Gas estimates will be updated after each dry run
- Contract addresses will be updated after each deployment step
- Etherscan verification will be performed automatically with --verify flag
- All transaction hashes and block numbers will be recorded for future reference
