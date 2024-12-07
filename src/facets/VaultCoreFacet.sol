// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibVaultStorage.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";

interface IERC721A {
    function mint(address _to, uint256 _tokenId) external;
    function mintMany(address[] memory to, uint256[] memory externalTokenId) external;
    function getInternalTokenId(uint256 tokenId) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function burn(uint256 tokenId) external;
}

contract VaultCoreFacet {
    event VaultLocked(address indexed nftAddress, uint256 indexed tokenId, address indexed owner);
    event VaultUnlocked(address indexed nftAddress, uint256 indexed tokenId, address indexed owner);
    event RecipientAddressChanged(address indexed oldRecipient, address indexed newRecipient);
    event QuoteContractChanged(address indexed oldQuoteContract, address indexed newQuoteContract);
    event MetadataBaseUriChanged(string oldUri, string newUri);
    event WitnessAdded(address indexed witness);
    event WitnessRemoved(address indexed witness);
    event ContractRegistered(address indexed contractAddress, uint256 indexed contractType);
    event ContractUnregistered(address indexed contractAddress, uint256 indexed contractType);

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier isRegisteredContract(address _contract) {
        LibVaultStorage.enforceIsRegisteredContract(_contract);
        _;
    }

    function lockVault(address _nftAddress, uint256 tokenId) external onlyOwner isRegisteredContract(_nftAddress) {
        require(!LibVaultStorage.isVaultLocked(_nftAddress, tokenId), "VaultCoreFacet: Vault is already locked");
        LibVaultStorage.lockVault(_nftAddress, tokenId);
        emit VaultLocked(_nftAddress, tokenId, msg.sender);
    }

    function unlockVault(address _nftAddress, uint256 tokenId) external onlyOwner isRegisteredContract(_nftAddress) {
        require(LibVaultStorage.isVaultLocked(_nftAddress, tokenId), "VaultCoreFacet: Vault is not locked");
        LibVaultStorage.unlockVault(_nftAddress, tokenId);
        emit VaultUnlocked(_nftAddress, tokenId, msg.sender);
    }

    function isVaultLocked(address _nftAddress, uint256 tokenId) external view returns (bool) {
        return LibVaultStorage.isVaultLocked(_nftAddress, tokenId);
    }

    function addWitness(address _witness) external onlyOwner {
        require(_witness != address(0), "VaultCoreFacet: Cannot add zero address as witness");
        LibVaultStorage.addWitness(_witness);
        emit WitnessAdded(_witness);
    }

    function removeWitness(address _witness) external onlyOwner {
        require(_witness != address(0), "VaultCoreFacet: Cannot remove zero address as witness");
        LibVaultStorage.removeWitness(_witness);
        emit WitnessRemoved(_witness);
    }

    function setRecipientAddress(address _recipient) external onlyOwner {
        require(_recipient != address(0), "VaultCoreFacet: Cannot set zero address as recipient");
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        address oldRecipient = vs.recipientAddress;
        LibVaultStorage.setRecipientAddress(_recipient);
        emit RecipientAddressChanged(oldRecipient, _recipient);
    }

    function setQuoteContract(address _quoteContract) external onlyOwner {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        address oldQuoteContract = vs.quoteContract;
        LibVaultStorage.setQuoteContract(_quoteContract);
        emit QuoteContractChanged(oldQuoteContract, _quoteContract);
    }

    function setMetadataBaseUri(string calldata _uri) external onlyOwner {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        string memory oldUri = vs.metadataBaseUri;
        LibVaultStorage.setMetadataBaseUri(_uri);
        emit MetadataBaseUriChanged(oldUri, _uri);
    }

    function registerContract(address _contract, uint256 _type) external onlyOwner {
        require(_contract != address(0), "VaultCoreFacet: Cannot register zero address");
        require(_type > 0, "VaultCoreFacet: Invalid contract type");
        LibVaultStorage.registerContract(_contract, _type);
        emit ContractRegistered(_contract, _type);
    }

    function unregisterContract(address _contract, uint256 index) external onlyOwner {
        require(_contract != address(0), "VaultCoreFacet: Cannot unregister zero address");
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        uint256 contractType = vs.registeredContracts[_contract];
        LibVaultStorage.unregisterContract(_contract, index);
        emit ContractUnregistered(_contract, contractType);
    }

    function toggleAllowCallbacks() external onlyOwner {
        LibVaultStorage.toggleAllowCallbacks();
    }

    function toggleBypassability() external onlyOwner {
        LibVaultStorage.toggleBypassability();
    }

    function addBypassRule(address who, bytes4 functionSig, uint256 id) external onlyOwner {
        require(who != address(0), "VaultCoreFacet: Cannot add bypass rule for zero address");
        LibVaultStorage.addBypassRule(who, functionSig, id);
    }

    function removeBypassRule(address who, bytes4 functionSig, uint256 id) external onlyOwner {
        require(who != address(0), "VaultCoreFacet: Cannot remove bypass rule for zero address");
        LibVaultStorage.removeBypassRule(who, functionSig, id);
    }

    function getRegisteredContractsOfType(uint256 _type) external view returns (address[] memory) {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        return vs.registeredOfType[_type];
    }

    function isRegistered(address _contract, uint256 _type) external view returns (bool) {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        return vs.registeredContracts[_contract] == _type;
    }

    function version() external pure returns (string memory) {
        return "3.0.0";
    }
}
