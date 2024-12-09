# Emblem Vault System Deployment Report

BSC Testnet Deployment - Chain ID: 97

## Deployment Environment

### Tools & Versions

- Foundry Framework
  - Forge: Used for contract compilation and deployment
  - Cast: Used for contract interaction
  - Anvil: Used for local testing
- Solidity Version: 0.8.28
- Node Version: Latest LTS
- Git Commit: ef7070f

### Scripts Used

- `DeployDiamondSystem.s.sol`: Diamond system deployment
- `DeployBeaconSystem.s.sol`: Beacon system deployment
- `SetupCollectionFactory.s.sol`: Post-deployment configuration
- `UpgradeBeaconImplementations.s.sol`: Implementation upgrades
- `UpdateCollectionBaseURI.s.sol`: Collection URI updates

### Deployment Parameters

- Network: BSC Testnet
- Chain ID: 97
- Gas Price: 80 gwei
- Deployment Account: 0x107A120f536c8BD891A3c04fcA22a7814E260210

## System Architecture Overview

The Emblem Vault system consists of two main components:

1. Diamond System - The core protocol using EIP-2535 Diamond Pattern
2. Beacon System - Upgradeable implementation contracts for vault collections

### Diamond System Architecture

- Main Diamond contract that delegates calls to various facets
- Multiple facets providing different functionalities:
  - Core operations (EmblemVaultCoreFacet)
    - Vault locking/unlocking
    - Witness management
    - Contract registration
    - Bypass rules
  - Minting capabilities (EmblemVaultMintFacet)
    - Buy with signed price
    - Buy with quote
  - Claiming functionality (EmblemVaultClaimFacet)
    - Standard claim
    - Claim with signed price
  - Collection management (EmblemVaultCollectionFacet)
    - Create vault collections
    - Upgrade implementations
    - Factory management
  - Callback handling (EmblemVaultCallbackFacet)
    - Register/unregister callbacks
    - Execute callbacks
    - Callback control
  - Standard Diamond facets:
    - DiamondCut: Upgrade functionality
    - DiamondLoupe: Introspection
    - Ownership: Access control

### Beacon System Architecture

- Upgradeable implementations for ERC721 and ERC1155 vaults
  - ERC721: Standard NFT vault implementation
  - ERC1155: Multi-token vault implementation
- Beacon proxy pattern for upgradeability
  - Allows atomic upgrades of all vault instances
  - Maintains upgrade control through beacon ownership
- Factory contract for creating new vault collections
  - Creates new proxy instances
  - Initializes vaults with correct parameters
  - Links to appropriate beacon

## Initial Deployment Process

### Step 1: Diamond System Deployment

First, the Diamond system was deployed using `DeployDiamondSystem.s.sol`

Command used:

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url bsc_testnet --broadcast --slow --verify -vvvv
```

#### Deployed Facets:

1. DiamondCutFacet: `0xb35a45aa3040297c6cbb04ecb5123974efedd1ab`

   - Handles diamond upgrades
   - Manages facet addition/replacement/removal
   - [View on BSCScan](https://testnet.bscscan.com/address/0xb35a45aa3040297c6cbb04ecb5123974efedd1ab)

2. DiamondLoupeFacet: `0xca9892288e1157c3fedac180149866691a37458c`

   - Provides diamond introspection
   - Lists facets and functions
   - [View on BSCScan](https://testnet.bscscan.com/address/0xca9892288e1157c3fedac180149866691a37458c)

3. OwnershipFacet: `0xeea4194f3f12d31d2cc7260ddbe41296339968ff`

   - Manages diamond ownership
   - Controls admin functions
   - [View on BSCScan](https://testnet.bscscan.com/address/0xeea4194f3f12d31d2cc7260ddbe41296339968ff)

4. EmblemVaultCoreFacet: `0x191ee872c022f34bbf5da245ebb8674175c9f83e`

   - Core vault operations
   - System configuration
   - [View on BSCScan](https://testnet.bscscan.com/address/0x191ee872c022f34bbf5da245ebb8674175c9f83e)

5. EmblemVaultClaimFacet: `0xd85b74a55d06634561553795d0edea5ca523ca58`

   - Handles vault claiming
   - Manages claim verification
   - [View on BSCScan](https://testnet.bscscan.com/address/0xd85b74a55d06634561553795d0edea5ca523ca58)

6. EmblemVaultMintFacet: `0x7d6cd100e6fd4eb456b7837493790cc34ff072e4`

   - Controls vault minting
   - Price verification
   - [View on BSCScan](https://testnet.bscscan.com/address/0x7d6cd100e6fd4eb456b7837493790cc34ff072e4)

7. EmblemVaultCallbackFacet: `0x2e428d2fe37aa70f8d19139fb25c1e3f0d56058b`

   - Manages callbacks
   - Hook system
   - [View on BSCScan](https://testnet.bscscan.com/address/0x2e428d2fe37aa70f8d19139fb25c1e3f0d56058b)

8. EmblemVaultCollectionFacet: `0xfBF38C976877D866f433437734a13b84360e0a2C`

   - Collection management
   - Implementation upgrades
   - [View on BSCScan](https://testnet.bscscan.com/address/0xfBF38C976877D866f433437734a13b84360e0a2C)

9. EmblemVaultInitFacet: `0xc7241f821dba320ebe611c65bdc17f71d5907f12`
   - Initialization logic
   - Configuration setup
   - [View on BSCScan](https://testnet.bscscan.com/address/0xc7241f821dba320ebe611c65bdc17f71d5907f12)

#### Main Diamond Contract:

- Address: `0xC125Eb48fbD6dC3D4AfBBA5dd2a6684f83424dEa`
- [View on BSCScan](https://testnet.bscscan.com/address/0xC125Eb48fbD6dC3D4AfBBA5dd2a6684f83424dEa)
- Initialization: Completed with owner set
- Supported Interfaces: ERC165, DiamondCut, DiamondLoupe, ERC173
- Upgrade Capability: Can be upgraded through DiamondCut facet

### Step 2: Beacon System Deployment

After the Diamond system, the Beacon system was deployed using `DeployBeaconSystem.s.sol`

Command used:

```bash
forge script script/DeployBeaconSystem.s.sol:DeployBeaconSystem --rpc-url bsc_testnet --broadcast --slow --verify -vvvv
```

#### Initial Vault Implementations:

1. ERC721VaultImplementation: `0x499374687048E68Dc7aE35966B4e0FBa5e17C77B`

   - Base implementation for ERC721-based vaults
   - Initialized with version 18446744073709551615
   - Supports standard ERC721 functionality
   - Custom vault-specific features
   - [View on BSCScan](https://testnet.bscscan.com/address/0x499374687048E68Dc7aE35966B4e0FBa5e17C77B)
   - Deployment Block: 46337322
   - Transaction Hash: 0xa2dec3f5a77e5e9852cfe6136328597b5f3d8f2cd7375474f8e784bfa241ccbe

2. ERC1155VaultImplementation: `0x49cb84d93C8A80f0Ee639002D318f043B53a6FcA`
   - Base implementation for ERC1155-based vaults
   - Initialized with version 18446744073709551615
   - Supports standard ERC1155 functionality
   - Custom vault-specific features
   - [View on BSCScan](https://testnet.bscscan.com/address/0x49cb84d93C8A80f0Ee639002D318f043B53a6FcA)
   - Deployment Block: 46337323
   - Transaction Hash: 0x7b2c4b9ece1041844ff77d584d6c57969457b6a4e4733a4d075994f69e8f2a87

#### Beacon Contracts:

1. ERC721VaultBeacon: `0x704BC33f34fb696405BB4074a770D284097AfC75`

   - Points to ERC721VaultImplementation
   - Ownership transferred to deployer
   - Upgradeable through owner
   - [View on BSCScan](https://testnet.bscscan.com/address/0x704BC33f34fb696405BB4074a770D284097AfC75)
   - Deployment Block: 46337324
   - Transaction Hash: 0x56eaa36b29059c5fffca39a322d5f4ff91183c0d8014f1807330741914a3e9d0

2. ERC1155VaultBeacon: `0x8aAa7EA37638C1C4466804434bE2e4dA02774AcC`
   - Points to ERC1155VaultImplementation
   - Ownership transferred to deployer
   - Upgradeable through owner
   - [View on BSCScan](https://testnet.bscscan.com/address/0x8aAa7EA37638C1C4466804434bE2e4dA02774AcC)
   - Deployment Block: 46337325
   - Transaction Hash: 0xf8ce2ee0da0881cb6704e825151b9104fd1e3405aaef6e746c86ab34fc24b6d4

#### Factory Contract:

VaultCollectionFactory: `0xbcFcBC144f0ac1C695ADad8A38B48f040eC73d96`

- Configured with both beacon addresses
- Creates new vault collections
- Manages proxy deployment
- Handles initialization
- [View on BSCScan](https://testnet.bscscan.com/address/0xbcFcBC144f0ac1C695ADad8A38B48f040eC73d96)
- Deployment Block: 46337326
- Transaction Hash: 0x0b68f4d19a6d4037fdc2d4e7a631b7975278fe5f6e8b01decc2d1d53d926e330

### Step 3: Post-Deployment Configuration

After deploying both the Diamond and Beacon systems, the following configuration steps were completed:

#### Collection Factory Integration

The VaultCollectionFactory was integrated with the Diamond system using the `SetupCollectionFactory` script:

Command used:

```bash
forge script SetupCollectionFactory --rpc-url bsc_testnet --broadcast -vvvv
```

Transaction Details:

- Transaction Hash: 0x778204508af844717f3949d497d3c0e46f87545ddb4d678d3663478c14dd3388
- Block Number: 46337875
- Gas Used: 35,494 gas
- Gas Price: 22 gwei
- Total Cost: 0.000780868 ETH

The transaction successfully:

- Set the collection factory (0xbcFcBC144f0ac1C695ADad8A38B48f040eC73d96) in the Diamond
- Emitted CollectionFactorySet event with:
  - oldFactory: 0x0000000000000000000000000000000000000000
  - newFactory: 0xbcFcBC144f0ac1C695ADad8A38B48f040eC73d96

## Recent Updates

### ERC1155 Implementation Upgrade

The ERC1155 implementation was upgraded to support URI updates:

- New Implementation: `0xB4693aE4453c65D0aD7F80D5609af75baa673087`
- Deployment Block: 46338856
- Transaction Hash: 0x73725c1cb3c2af5167eefb5e60086045a32a96de363230f7822c2ad070e1e473
- Changes:
  - Added public setURI function with onlyOwner modifier
  - Improved URI update functionality
  - Maintained all existing functionality

### Collection URI Updates

#### ERC721 Collection

- Collection Address: `0x7587d6A2e67eD18cA8279820e608894cC5c145A5`
- New Base URI: `https://api.emblem.finance/erc721/metadata/`
- Update Block: 46338884
- Transaction Hash: 0x3e7aa8a9c02dcf02c2bd7f9cf0856c4ac0cf7bb63d2215315c51916c8a4212b4
- Gas Used: 70,875 gas
- Gas Price: 10 gwei
- Total Cost: 0.00070875 ETH

#### ERC1155 Collection

- Collection Address: `0x064724D71E0B3C2bB03384d1188A2F34144a13bd`
- New URI: `https://api.emblem.finance/erc1155/metadata/{id}.json`
- Update Block: 46338977
- Transaction Hash: 0x72beeb93e604f0a705030166388de1de20e6fa916c6a3cefe76de845345de9d9
- Gas Used: 72,558 gas
- Gas Price: 20 gwei
- Total Cost: 0.00145116 ETH

## Contract Verification

All contracts have been verified on BSCScan and can be viewed at their respective addresses. Each contract's source code and constructor arguments are publicly available for review.

## Upgrade Mechanisms

### Diamond System Upgrades

- Facets can be added, replaced, or removed through the DiamondCut facet
- Only the contract owner can perform upgrades
- Function selectors can be reorganized across facets

### Beacon System Upgrades

- Implementation contracts can be upgraded through their respective beacons
- All proxies automatically use new implementation
- Separate upgrade paths for ERC721 and ERC1155 vaults

## Next Steps

1. ✅ Set the collection factory in the diamond by calling setCollectionFactory on the CollectionFacet
2. ✅ Update collection URIs to point to the correct metadata endpoints
3. Test vault collection creation through the factory
4. Verify all system functionalities through the Diamond proxy
5. Set up necessary access controls and permissions
6. Configure any system parameters through the CoreFacet

## Gas Usage Summary

### Diamond System

Total gas used: Approximately 6.9M gas

- Deployment costs vary by facet complexity
- Initialization included in deployment

### Beacon System

Initial Deployment:

- ERC721VaultImplementation: 2,865,770 gas (0.2292616 ETH @ 80 gwei)
- ERC1155VaultImplementation: 2,542,956 gas (0.20343648 ETH @ 80 gwei)
- ERC721VaultBeacon: 264,577 gas (0.02116616 ETH @ 80 gwei)
- ERC1155VaultBeacon: 264,594 gas (0.02116752 ETH @ 80 gwei)
- VaultCollectionFactory: 875,833 gas (0.07006664 ETH @ 80 gwei)
  Total initial gas used: 6,813,730 gas (0.5450984 ETH @ 80 gwei)

Recent Updates:

- ERC1155 Implementation Upgrade: 764,949 gas (0.00764949 ETH @ 10 gwei)
- ERC721 URI Update: 70,875 gas (0.00070875 ETH @ 10 gwei)
- ERC1155 URI Update: 72,558 gas (0.00145116 ETH @ 20 gwei)

### Post-Deployment Configuration

- Collection Factory Setup: 35,494 gas (0.000780868 ETH @ 22 gwei)

## Notes

- All contracts deployed with Solidity version 0.8.28
- Deployment executed on BSC Testnet with chain ID 97
- All contracts successfully verified on BSCScan
- System ready for collection factory integration with the Diamond
- Upgrade mechanisms in place for both systems
- Security considerations implemented in all contracts
- Deployment transactions and blocks recorded for future reference
- URI updates completed for both ERC721 and ERC1155 collections
- ERC1155 implementation successfully upgraded to support URI updates
