// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./LibDiamond.sol";
import "../interfaces/IHandlerCallback.sol";

library LibEmblemVaultStorage {
    bytes32 constant EMBLEM_VAULT_STORAGE_POSITION = keccak256("emblem.vault.storage");
    bytes32 constant REENTRANCY_GUARD_POSITION = keccak256("emblem.vault.reentrancy.guard");

    struct ReentrancyGuard {
        bool entered;
    }

    struct VaultStorage {
        // Core storage
        mapping(address => mapping(uint256 => bool)) lockedVaults;
        mapping(address => bool) witnesses;
        mapping(uint256 => bool) usedNonces;
        // Configuration
        string metadataBaseUri;
        address recipientAddress;
        address quoteContract;
        address vaultFactory; // Added for beacon pattern integration
        bool initialized;
        bool shouldBurn;
        bool allowCallbacks;
        bool byPassable;
        // Interface IDs
        bytes4 INTERFACE_ID_ERC1155;
        bytes4 INTERFACE_ID_ERC20;
        bytes4 INTERFACE_ID_ERC721;
        bytes4 INTERFACE_ID_ERC721A;
        // Registration storage
        mapping(address => uint256) registeredContracts;
        mapping(uint256 => address[]) registeredOfType;
        // Callback storage
        mapping(address => mapping(uint256 => mapping(IHandlerCallback.CallbackType => IHandlerCallback.Callback[])))
            registeredCallbacks;
        mapping(address => mapping(IHandlerCallback.CallbackType => IHandlerCallback.Callback[]))
            registeredWildcardCallbacks;
        // Bypass storage
        mapping(address => mapping(bytes4 => bool)) byPassableFunction;
        mapping(address => mapping(uint256 => bool)) byPassableIds;
    }

    function reentrancyGuard() internal pure returns (ReentrancyGuard storage r) {
        bytes32 position = REENTRANCY_GUARD_POSITION;
        assembly {
            r.slot := position
        }
    }

    function vaultStorage() internal pure returns (VaultStorage storage vs) {
        bytes32 position = EMBLEM_VAULT_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    function nonReentrantBefore() internal {
        ReentrancyGuard storage guard = reentrancyGuard();
        require(!guard.entered, "ReentrancyGuard: reentrant call");
        guard.entered = true;
    }

    function nonReentrantAfter() internal {
        ReentrancyGuard storage guard = reentrancyGuard();
        guard.entered = false;
    }

    function enforceIsContractOwner() internal view {
        LibDiamond.enforceIsContractOwner();
    }

    function enforceIsRegisteredContract(address _contract) internal view {
        VaultStorage storage vs = vaultStorage();
        require(vs.registeredContracts[_contract] > 0, "LibEmblemVaultStorage: Contract is not registered");
    }

    function enforceIsWitness(address _witness) internal view {
        VaultStorage storage vs = vaultStorage();
        require(vs.witnesses[_witness], "LibEmblemVaultStorage: Not a witness");
    }

    function enforceNotUsedNonce(uint256 _nonce) internal view {
        VaultStorage storage vs = vaultStorage();
        require(!vs.usedNonces[_nonce], "LibEmblemVaultStorage: Nonce already used");
    }

    function setUsedNonce(uint256 _nonce) internal {
        VaultStorage storage vs = vaultStorage();
        vs.usedNonces[_nonce] = true;
    }

    function isVaultLocked(address _nftAddress, uint256 _tokenId) internal view returns (bool) {
        return vaultStorage().lockedVaults[_nftAddress][_tokenId];
    }

    function lockVault(address _nftAddress, uint256 _tokenId) internal {
        vaultStorage().lockedVaults[_nftAddress][_tokenId] = true;
    }

    function unlockVault(address _nftAddress, uint256 _tokenId) internal {
        vaultStorage().lockedVaults[_nftAddress][_tokenId] = false;
    }

    function addWitness(address _witness) internal {
        vaultStorage().witnesses[_witness] = true;
    }

    function removeWitness(address _witness) internal {
        vaultStorage().witnesses[_witness] = false;
    }

    function setRecipientAddress(address _recipient) internal {
        vaultStorage().recipientAddress = _recipient;
    }

    function setQuoteContract(address _quoteContract) internal {
        vaultStorage().quoteContract = _quoteContract;
    }

    function setVaultFactory(address _factory) internal {
        vaultStorage().vaultFactory = _factory;
    }

    function setMetadataBaseUri(string memory _uri) internal {
        vaultStorage().metadataBaseUri = _uri;
    }

    function toggleAllowCallbacks() internal {
        VaultStorage storage vs = vaultStorage();
        vs.allowCallbacks = !vs.allowCallbacks;
    }

    function toggleBypassability() internal {
        VaultStorage storage vs = vaultStorage();
        vs.byPassable = !vs.byPassable;
    }

    function addBypassRule(address who, bytes4 functionSig, uint256 id) internal {
        VaultStorage storage vs = vaultStorage();
        vs.byPassableFunction[who][functionSig] = true;
        if (id != 0) {
            vs.byPassableIds[who][id] = true;
        }
    }

    function removeBypassRule(address who, bytes4 functionSig, uint256 id) internal {
        VaultStorage storage vs = vaultStorage();
        vs.byPassableFunction[who][functionSig] = false;
        if (id != 0) {
            vs.byPassableIds[who][id] = false;
        }
    }

    function registerContract(address _contract, uint256 _type) internal {
        VaultStorage storage vs = vaultStorage();
        vs.registeredContracts[_contract] = _type;
        vs.registeredOfType[_type].push(_contract);
    }

    function unregisterContract(address _contract, uint256 index) internal {
        VaultStorage storage vs = vaultStorage();
        address[] storage arr = vs.registeredOfType[vs.registeredContracts[_contract]];
        arr[index] = arr[arr.length - 1];
        arr.pop();
        delete vs.registeredContracts[_contract];
    }

    function initializeVaultStorage() internal {
        VaultStorage storage vs = vaultStorage();
        require(!vs.initialized, "LibEmblemVaultStorage: Already initialized");

        vs.metadataBaseUri = "https://v2.emblemvault.io/meta/";
        vs.INTERFACE_ID_ERC1155 = 0xd9b67a26;
        vs.INTERFACE_ID_ERC20 = 0x74a1476f;
        vs.INTERFACE_ID_ERC721 = 0x80ac58cd;
        vs.INTERFACE_ID_ERC721A = 0xf4a95f26;
        vs.recipientAddress = msg.sender;
        vs.vaultFactory = msg.sender;
        vs.allowCallbacks = true;
        vs.initialized = true;
    }
}
