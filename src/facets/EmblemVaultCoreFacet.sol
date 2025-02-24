/*
███████╗███╗   ███╗██████╗ ██╗     ███████╗███╗   ███╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
██╔════╝████╗ ████║██╔══██╗██║     ██╔════╝████╗ ████║    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
█████╗  ██╔████╔██║██████╔╝██║     █████╗  ██╔████╔██║    ██║   ██║███████║██║   ██║██║     ██║   
██╔══╝  ██║╚██╔╝██║██╔══██╗██║     ██╔══╝  ██║╚██╔╝██║    ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║   
███████╗██║ ╚═╝ ██║██████╔╝███████╗███████╗██║ ╚═╝ ██║     ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║   
╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝      ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝   
 ██████╗ ██████╗ ██████╗ ███████╗
██╔════╝██╔═══██╗██╔══██╗██╔════╝
██║     ██║   ██║██████╔╝█████╗  
██║     ██║   ██║██╔══██╗██╔══╝  
╚██████╗╚██████╔╝██║  ██║███████╗
 ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";
import "../libraries/LibErrors.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IVaultCollectionFactory.sol";

/// @title EmblemVaultCoreFacet
/// @notice Core functionality for the Emblem Vault system
/// @dev Manages vault locking, witnesses, and system configuration
contract EmblemVaultCoreFacet {
    // Events
    event VaultLocked(address indexed nftAddress, uint256 indexed tokenId, address indexed owner);
    event VaultUnlocked(address indexed nftAddress, uint256 indexed tokenId, address indexed owner);
    event RecipientAddressChanged(address indexed oldRecipient, address indexed newRecipient);
    event MetadataBaseUriChanged(string oldUri, string newUri);
    event WitnessAdded(address indexed witness, uint256 newCount);
    event WitnessRemoved(address indexed witness, uint256 newCount);
    event BypassRuleAdded(address indexed who, bytes4 indexed functionSig, uint256 indexed id);
    event BypassRuleRemoved(address indexed who, bytes4 indexed functionSig, uint256 indexed id);
    event BypassabilityToggled(bool newState);
    event VaultFactorySet(address indexed oldFactory, address indexed newFactory);

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyValidCollection(address collection) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);
        LibErrors.revertIfInvalidCollection(
            collection, IVaultCollectionFactory(vs.vaultFactory).isCollection(collection)
        );
        _;
    }

    /// @notice Lock a vault to prevent operations
    /// @param collection The collection address
    /// @param tokenId The token ID to lock
    function lockVault(address collection, uint256 tokenId)
        external
        onlyOwner
        onlyValidCollection(collection)
    {
        LibErrors.revertIfAlreadyLocked(
            collection, tokenId, LibEmblemVaultStorage.isVaultLocked(collection, tokenId)
        );
        LibEmblemVaultStorage.lockVault(collection, tokenId);
        emit VaultLocked(collection, tokenId, msg.sender);
    }

    /// @notice Unlock a previously locked vault
    /// @param collection The collection address
    /// @param tokenId The token ID to unlock
    function unlockVault(address collection, uint256 tokenId)
        external
        onlyOwner
        onlyValidCollection(collection)
    {
        LibErrors.revertIfNotLocked(
            collection, tokenId, LibEmblemVaultStorage.isVaultLocked(collection, tokenId)
        );
        LibEmblemVaultStorage.unlockVault(collection, tokenId);
        emit VaultUnlocked(collection, tokenId, msg.sender);
    }

    /// @notice Check if a vault is locked
    /// @param collection The collection address
    /// @param tokenId The token ID to check
    /// @return True if the vault is locked
    function isVaultLocked(address collection, uint256 tokenId) external view returns (bool) {
        return LibEmblemVaultStorage.isVaultLocked(collection, tokenId);
    }

    // ============ Witness Management ============

    /// @notice Add a new witness
    /// @param _witness Address of the witness to add
    function addWitness(address _witness) external onlyOwner {
        LibErrors.revertIfZeroAddress(_witness);

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.witnesses[_witness]) revert LibErrors.WitnessAlreadyExists(_witness);

        LibEmblemVaultStorage.addWitness(_witness);
        emit WitnessAdded(_witness, vs.witnessCount);
    }

    /// @notice Remove a witness
    /// @param _witness Address of the witness to remove
    function removeWitness(address _witness) external onlyOwner {
        LibErrors.revertIfZeroAddress(_witness);

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (!vs.witnesses[_witness]) revert LibErrors.WitnessDoesNotExist(_witness);
        if (vs.witnessCount <= 1) revert LibErrors.NoWitnessesRemaining();

        LibEmblemVaultStorage.removeWitness(_witness);
        emit WitnessRemoved(_witness, vs.witnessCount);
    }

    /// @notice Check if an address is a witness
    /// @param _witness Address to check
    /// @return True if the address is a witness
    function isWitness(address _witness) external view returns (bool) {
        return LibEmblemVaultStorage.vaultStorage().witnesses[_witness];
    }

    /// @notice Get the current number of witnesses
    /// @return The number of active witnesses
    function getWitnessCount() external view returns (uint256) {
        return LibEmblemVaultStorage.vaultStorage().witnessCount;
    }

    // ============ System Configuration ============

    /// @notice Set the vault factory address
    /// @param _factory New factory address
    function setVaultFactory(address _factory) external onlyOwner {
        LibErrors.revertIfZeroAddress(_factory);
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        address oldFactory = vs.vaultFactory;
        LibEmblemVaultStorage.setVaultFactory(_factory);
        emit VaultFactorySet(oldFactory, _factory);
    }

    /// @notice Set the recipient address for payments
    /// @param _recipient New recipient address
    function setRecipientAddress(address _recipient) external onlyOwner {
        LibErrors.revertIfZeroAddress(_recipient);
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        address oldRecipient = vs.recipientAddress;
        LibEmblemVaultStorage.setRecipientAddress(_recipient);
        emit RecipientAddressChanged(oldRecipient, _recipient);
    }

    /// @notice Set the base URI for metadata
    /// @param _uri New base URI
    function setMetadataBaseUri(string calldata _uri) external onlyOwner {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        string memory oldUri = vs.metadataBaseUri;
        LibEmblemVaultStorage.setMetadataBaseUri(_uri);
        emit MetadataBaseUriChanged(oldUri, _uri);
    }

    // ============ Bypass Rules ============

    /// @notice Toggle the bypassability state
    function toggleBypassability() external onlyOwner {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibEmblemVaultStorage.toggleBypassability();
        emit BypassabilityToggled(vs.byPassable);
    }

    /// @notice Add a bypass rule
    /// @param who Address to add the rule for
    /// @param functionSig Function signature to bypass
    /// @param id Token ID for the rule (0 for all tokens)
    function addBypassRule(address who, bytes4 functionSig, uint256 id) external onlyOwner {
        LibErrors.revertIfZeroAddress(who);
        if (functionSig == bytes4(0)) revert LibErrors.InvalidInitialization();
        LibEmblemVaultStorage.addBypassRule(who, functionSig, id);
        emit BypassRuleAdded(who, functionSig, id);
    }

    /// @notice Remove a bypass rule
    /// @param who Address to remove the rule for
    /// @param functionSig Function signature to remove bypass for
    /// @param id Token ID for the rule
    function removeBypassRule(address who, bytes4 functionSig, uint256 id) external onlyOwner {
        LibErrors.revertIfZeroAddress(who);
        if (functionSig == bytes4(0)) revert LibErrors.InvalidInitialization();
        LibEmblemVaultStorage.removeBypassRule(who, functionSig, id);
        emit BypassRuleRemoved(who, functionSig, id);
    }

    // ============ Getters ============

    /// @notice Get the current recipient address
    /// @return The recipient address
    function getRecipientAddress() external view returns (address) {
        return LibEmblemVaultStorage.vaultStorage().recipientAddress;
    }

    /// @notice Get the current metadata base URI
    /// @return The base URI string
    function getMetadataBaseUri() external view returns (string memory) {
        return LibEmblemVaultStorage.vaultStorage().metadataBaseUri;
    }

    /// @notice Get the current vault factory
    /// @return The vault factory address
    function getVaultFactory() external view returns (address) {
        return LibEmblemVaultStorage.vaultStorage().vaultFactory;
    }

    /// @notice Get the core facet version
    /// @return The version string
    function getCoreVersion() external pure returns (string memory) {
        return "0.1.0";
    }
}
