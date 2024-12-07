# Diamond Vault Handler Implementation Guide

## Overview

This document outlines how to improve the existing VaultHandlerV8Upgradable contract by converting it to a more efficient diamond proxy pattern implementation. The diamond pattern will provide better modularity, gas efficiency, and upgradeability.

## Core Improvements

### 1. Modular Facet Structure

Split the monolithic contract into specialized facets:

#### VaultCoreFacet

- Core vault locking/unlocking functionality
- Token ownership tracking
- Basic vault operations

```solidity
function lockVault(address _nftAddress, uint256 tokenId)
function unlockVault(address _nftAddress, uint256 tokenId)
function isVaultLocked(address _nftAddress, uint256 tokenId)
```

#### ClaimFacet

- Claim functionality with signature verification
- Burn routing logic

```solidity
function claim(address _nftAddress, uint256 tokenId)
function claimWithSignedPrice(address _nftAddress, uint256 _tokenId, uint256 _nonce, address _payment, uint _price, bytes calldata _signature)
function burnRouter(address _nftAddress, uint256 tokenId, bool shouldClaim)
```

#### MintFacet

- Minting functionality with signature verification
- Support for different token standards (ERC721, ERC1155, ERC721A)

```solidity
function buyWithSignedPrice(address _nftAddress, address _payment, uint _price, address _to, uint256 _tokenId, uint256 _nonce, bytes calldata _signature, bytes calldata serialNumber, uint256 _amount)
function buyWithQuote(address _nftAddress, uint _price, address _to, uint256 _tokenId, uint256 _nonce, bytes calldata _signature, bytes calldata serialNumber, uint256 _amount)
function mintRouter(address _nftAddress, address _to, uint256 _tokenId, uint256 _nonce, uint256 _amount, address signer, bytes calldata serialNumber)
```

#### CallbackFacet

- Callback registration and execution
- Event handling

```solidity
function registerCallback(address _contract, address target, uint256 tokenId, CallbackType _type, bytes4 _function, bool allowRevert)
function executeCallbacks(address _from, address _to, uint256 tokenId, CallbackType _type)
```

#### AdminFacet

- Administrative functions
- Contract registration
- Witness management

```solidity
function addWitness(address _witness)
function changeRecipient(address _recipient)
function registerContract(address _contract, uint _type)
```

### 2. Storage Improvements

#### LibVaultStorage

```solidity
library LibVaultStorage {
    bytes32 constant VAULT_STORAGE_POSITION = keccak256("diamond.standard.vault.storage");

    struct VaultStorage {
        // Core storage
        mapping(address => mapping(uint256 => bool)) lockedVaults;
        mapping(address => bool) witnesses;
        mapping(uint256 => bool) usedNonces;

        // Configuration
        string metadataBaseUri;
        address recipientAddress;
        address quoteContract;
        bool initialized;
        bool shouldBurn;

        // Interface IDs
        bytes4 INTERFACE_ID_ERC1155;
        bytes4 INTERFACE_ID_ERC20;
        bytes4 INTERFACE_ID_ERC721;
        bytes4 INTERFACE_ID_ERC721A;

        // Registration storage
        mapping(address => uint256) registeredContracts;
        mapping(uint256 => address[]) registeredOfType;

        // Callback storage
        mapping(address => mapping(uint256 => mapping(CallbackType => Callback[]))) registeredCallbacks;
        mapping(address => mapping(CallbackType => Callback[])) registeredWildcardCallbacks;
    }
}
```

### 3. Key Improvements

1. **Modularity**:

   - Each facet handles a specific concern
   - Easier to upgrade individual components
   - Better code organization and maintenance

2. **Gas Efficiency**:

   - Smaller function footprints
   - Optimized storage layout
   - Reduced deployment costs through facet reuse

3. **Security**:

   - Isolated functionality reduces attack surface
   - Easier to audit individual facets
   - More granular access control

4. **Flexibility**:
   - Easy to add new features through new facets
   - Can upgrade specific functionality without affecting others
   - Better support for future token standards

### 4. Implementation Strategy

1. **Initial Setup**:

   ```solidity
   Diamond diamond = new Diamond(owner, diamondCutFacet);
   ```

2. **Deploy Facets**:

   ```solidity
   VaultCoreFacet vaultCore = new VaultCoreFacet();
   ClaimFacet claim = new ClaimFacet();
   MintFacet mint = new MintFacet();
   CallbackFacet callback = new CallbackFacet();
   AdminFacet admin = new AdminFacet();
   ```

3. **Add Facets to Diamond**:
   ```solidity
   // Add facets through diamondCut
   diamond.diamondCut(
       [
           {facetAddress: address(vaultCore), action: FacetCutAction.Add, functionSelectors: getSelectors(vaultCore)},
           {facetAddress: address(claim), action: FacetCutAction.Add, functionSelectors: getSelectors(claim)},
           // ... other facets
       ],
       address(0),
       ""
   );
   ```

### 5. Migration Path

1. **Phase 1: Setup**

   - Deploy new diamond implementation
   - Deploy initial facets
   - Set up storage structure

2. **Phase 2: Data Migration**

   - Create migration scripts for existing data
   - Transfer ownership and permissions
   - Migrate locked vault states

3. **Phase 3: Switchover**
   - Verify all functionality
   - Update dependent contracts
   - Switch to new implementation

### 6. Benefits Over Current Implementation

1. **Code Organization**:

   - Current: Single monolithic contract
   - New: Modular facets with clear responsibilities

2. **Upgradeability**:

   - Current: Entire contract must be upgraded
   - New: Individual facets can be upgraded independently

3. **Gas Efficiency**:

   - Current: Large deployment cost
   - New: Reduced costs through facet reuse

4. **Maintainability**:

   - Current: Complex intertwined functionality
   - New: Clear separation of concerns

5. **Extensibility**:
   - Current: Limited by contract size
   - New: Unlimited through additional facets

## Conclusion

The diamond pattern implementation provides a more robust, efficient, and maintainable solution for the vault handler. It maintains all existing functionality while providing better upgradeability and extensibility for future features.
