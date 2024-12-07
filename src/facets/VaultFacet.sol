// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract VaultFacet {
    bytes32 constant VAULT_STORAGE_POSITION = keccak256("diamond.standard.vault.storage");

    struct VaultStorage {
        // Mapping from token ID to owner address
        mapping(uint256 => address) tokenOwners;
        // Mapping from token ID to locked status
        mapping(uint256 => bool) lockedTokens;
        // Mapping from token ID to token URI
        mapping(uint256 => string) tokenURIs;
        // Mapping from owner to token count
        mapping(address => uint256) balances;
        // Total number of tokens locked
        uint256 totalSupply;
    }

    function vaultStorage() internal pure returns (VaultStorage storage vs) {
        bytes32 position = VAULT_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    event TokenLocked(uint256 indexed tokenId, address indexed owner, string tokenURI);
    event TokenUnlocked(uint256 indexed tokenId, address indexed owner);
    event TokenURIUpdated(uint256 indexed tokenId, string newTokenURI);

    modifier onlyTokenOwner(uint256 tokenId) {
        require(vaultStorage().tokenOwners[tokenId] == msg.sender, "VaultFacet: Not token owner");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(vaultStorage().tokenOwners[tokenId] != address(0), "VaultFacet: Token does not exist");
        _;
    }

    function lockToken(uint256 tokenId, string calldata _tokenURI) external {
        VaultStorage storage vs = vaultStorage();
        require(vs.tokenOwners[tokenId] == address(0), "VaultFacet: Token already exists");
        require(bytes(_tokenURI).length > 0, "VaultFacet: Token URI is required");

        vs.tokenOwners[tokenId] = msg.sender;
        vs.lockedTokens[tokenId] = true;
        vs.tokenURIs[tokenId] = _tokenURI;
        vs.balances[msg.sender] += 1;
        vs.totalSupply += 1;

        emit TokenLocked(tokenId, msg.sender, _tokenURI);
    }

    function unlockToken(uint256 tokenId) external onlyTokenOwner(tokenId) {
        VaultStorage storage vs = vaultStorage();
        require(vs.lockedTokens[tokenId], "VaultFacet: Token is not locked");

        address owner = vs.tokenOwners[tokenId];
        delete vs.tokenOwners[tokenId];
        delete vs.lockedTokens[tokenId];
        delete vs.tokenURIs[tokenId];
        vs.balances[owner] -= 1;
        vs.totalSupply -= 1;

        emit TokenUnlocked(tokenId, owner);
    }

    function updateTokenURI(uint256 tokenId, string calldata newTokenURI) external onlyTokenOwner(tokenId) {
        require(bytes(newTokenURI).length > 0, "VaultFacet: Token URI is required");
        VaultStorage storage vs = vaultStorage();
        vs.tokenURIs[tokenId] = newTokenURI;
        emit TokenURIUpdated(tokenId, newTokenURI);
    }

    function getTokenURI(uint256 tokenId) external view tokenExists(tokenId) returns (string memory) {
        return vaultStorage().tokenURIs[tokenId];
    }

    function isTokenLocked(uint256 tokenId) external view returns (bool) {
        return vaultStorage().lockedTokens[tokenId];
    }

    function tokenOwner(uint256 tokenId) external view returns (address) {
        return vaultStorage().tokenOwners[tokenId];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return vaultStorage().balances[owner];
    }

    function totalSupply() external view returns (uint256) {
        return vaultStorage().totalSupply;
    }
}
