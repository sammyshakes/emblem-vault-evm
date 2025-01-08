// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./LibDiamond.sol";

/// @title LibEmblemVaultStorage
/// @notice Library for managing Emblem Vault storage
/// @dev Uses diamond storage pattern for upgradeable storage
library LibEmblemVaultStorage {
    bytes32 constant EMBLEM_VAULT_STORAGE_POSITION = keccak256("emblem.vault.storage");
    bytes32 constant REENTRANCY_GUARD_POSITION = keccak256("emblem.vault.reentrancy.guard");

    // Custom errors
    error AlreadyInitialized();
    error NotInitialized();
    error ReentrantCall();
    error NotWitness();
    error NonceAlreadyUsed();
    error ZeroAddress();
    error AlreadyUnvaulted();
    error UnvaultingDisabled();

    struct ReentrancyGuard {
        bool entered;
    }

    /// @notice Main storage structure for the Emblem Vault system
    /// @dev Uses diamond storage pattern for upgradeability
    struct VaultStorage {
        // System State
        bool initialized;
        bool byPassable;
        bool unvaultingEnabled; // Global switch for unvaulting
        // Core Mappings
        mapping(address => mapping(uint256 => bool)) lockedVaults;
        mapping(address => bool) witnesses;
        mapping(uint256 => bool) usedNonces;
        // Configuration
        string metadataBaseUri;
        address recipientAddress;
        address vaultFactory; // For beacon pattern integration
        // Unvault Tracking
        mapping(address => mapping(uint256 => bool)) unvaulted; // nft => identifier => unvaulted
        mapping(address => mapping(uint256 => address)) unvaulters; // nft => identifier => unvaulter
        mapping(address => uint256) totalUnvaulted; // nft => count
        mapping(address => bool) burnAddresses; // For burn address verification
        // Interface IDs (constant but stored for gas optimization)
        bytes4 INTERFACE_ID_ERC1155;
        bytes4 INTERFACE_ID_ERC20;
        bytes4 INTERFACE_ID_ERC721A;
        // Bypass System
        mapping(address => mapping(bytes4 => bool)) byPassableFunction;
        mapping(address => mapping(uint256 => bool)) byPassableIds;
        // Statistics
        uint256 witnessCount; // Track number of witnesses
        // Collection Ownership
        address collectionOwner;
    }

    error CollectionOwnerNotSet();

    function setCollectionOwner(address _owner) internal {
        if (_owner == address(0)) revert ZeroAddress();
        vaultStorage().collectionOwner = _owner;
    }

    function getCollectionOwner() internal view returns (address) {
        address owner = vaultStorage().collectionOwner;
        if (owner == address(0)) revert CollectionOwnerNotSet();
        return owner;
    }

    /// @notice Get the reentrancy guard storage
    function reentrancyGuard() internal pure returns (ReentrancyGuard storage r) {
        bytes32 position = REENTRANCY_GUARD_POSITION;
        assembly {
            r.slot := position
        }
    }

    /// @notice Get the main vault storage
    function vaultStorage() internal pure returns (VaultStorage storage vs) {
        bytes32 position = EMBLEM_VAULT_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    // ============ Reentrancy Protection ============

    function nonReentrantBefore() internal {
        ReentrancyGuard storage guard = reentrancyGuard();
        if (guard.entered) revert ReentrantCall();
        guard.entered = true;
    }

    function nonReentrantAfter() internal {
        ReentrancyGuard storage guard = reentrancyGuard();
        guard.entered = false;
    }

    // ============ Access Control ============

    function enforceIsContractOwner() internal view {
        LibDiamond.enforceIsContractOwner();
    }

    function enforceIsWitness(address _witness) internal view {
        if (!vaultStorage().witnesses[_witness]) revert NotWitness();
    }

    function enforceNotUsedNonce(uint256 _nonce) internal view {
        if (vaultStorage().usedNonces[_nonce]) revert NonceAlreadyUsed();
    }

    // ============ Vault Management ============

    function isVaultLocked(address _nftAddress, uint256 _tokenId) internal view returns (bool) {
        return vaultStorage().lockedVaults[_nftAddress][_tokenId];
    }

    function lockVault(address _nftAddress, uint256 _tokenId) internal {
        vaultStorage().lockedVaults[_nftAddress][_tokenId] = true;
    }

    function unlockVault(address _nftAddress, uint256 _tokenId) internal {
        vaultStorage().lockedVaults[_nftAddress][_tokenId] = false;
    }

    // ============ Witness Management ============

    function addWitness(address _witness) internal {
        VaultStorage storage vs = vaultStorage();
        if (!vs.witnesses[_witness]) {
            vs.witnesses[_witness] = true;
            vs.witnessCount++;
        }
    }

    function removeWitness(address _witness) internal {
        VaultStorage storage vs = vaultStorage();
        if (vs.witnesses[_witness]) {
            vs.witnesses[_witness] = false;
            vs.witnessCount--;
        }
    }

    // ============ Nonce Management ============

    function setUsedNonce(uint256 _nonce) internal {
        vaultStorage().usedNonces[_nonce] = true;
    }

    // ============ Configuration Management ============

    function setRecipientAddress(address _recipient) internal {
        if (_recipient == address(0)) revert ZeroAddress();
        vaultStorage().recipientAddress = _recipient;
    }

    function setVaultFactory(address _factory) internal {
        if (_factory == address(0)) revert ZeroAddress();
        vaultStorage().vaultFactory = _factory;
    }

    function setMetadataBaseUri(string memory _uri) internal {
        vaultStorage().metadataBaseUri = _uri;
    }

    // ============ Bypass System ============

    function toggleBypassability() internal {
        VaultStorage storage vs = vaultStorage();
        vs.byPassable = !vs.byPassable;
    }

    function addBypassRule(address who, bytes4 functionSig, uint256 id) internal {
        if (who == address(0)) revert ZeroAddress();
        VaultStorage storage vs = vaultStorage();
        vs.byPassableFunction[who][functionSig] = true;
        if (id != 0) {
            vs.byPassableIds[who][id] = true;
        }
    }

    function removeBypassRule(address who, bytes4 functionSig, uint256 id) internal {
        if (who == address(0)) revert ZeroAddress();
        VaultStorage storage vs = vaultStorage();
        vs.byPassableFunction[who][functionSig] = false;
        if (id != 0) {
            vs.byPassableIds[who][id] = false;
        }
    }

    // ============ Unvault Management ============

    function setUnvaulted(address nft, uint256 id, address unvaulter) internal {
        VaultStorage storage vs = vaultStorage();
        if (!vs.unvaultingEnabled) revert UnvaultingDisabled();
        if (vs.unvaulted[nft][id]) revert AlreadyUnvaulted();

        vs.unvaulted[nft][id] = true;
        vs.unvaulters[nft][id] = unvaulter;
        vs.totalUnvaulted[nft]++;
    }

    function isUnvaulted(address nft, uint256 id) internal view returns (bool) {
        return vaultStorage().unvaulted[nft][id];
    }

    function getUnvaulter(address nft, uint256 id) internal view returns (address) {
        return vaultStorage().unvaulters[nft][id];
    }

    function getUnvaultCount(address nft) internal view returns (uint256) {
        return vaultStorage().totalUnvaulted[nft];
    }

    function setUnvaultingEnabled(bool enabled) internal {
        vaultStorage().unvaultingEnabled = enabled;
    }

    function setBurnAddress(address addr, bool isBurn) internal {
        if (addr == address(0)) revert ZeroAddress();
        vaultStorage().burnAddresses[addr] = isBurn;
    }

    function isBurnAddress(address addr) internal view returns (bool) {
        return vaultStorage().burnAddresses[addr];
    }

    function initializeVaultStorage() internal {
        VaultStorage storage vs = vaultStorage();
        if (vs.initialized) revert AlreadyInitialized();

        vs.metadataBaseUri = "https://v2.emblemvault.io/meta/";
        vs.unvaultingEnabled = true;
        vs.INTERFACE_ID_ERC1155 = 0xd9b67a26;
        vs.INTERFACE_ID_ERC20 = 0x74a1476f;
        vs.INTERFACE_ID_ERC721A = 0xf4a95f26;
        vs.recipientAddress = msg.sender;
        vs.vaultFactory = msg.sender;
        vs.witnessCount = 0;
        vs.initialized = true;
    }
}
