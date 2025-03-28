// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title MockERC721
 * @dev A simple ERC721 implementation for testing purposes
 */
contract MockERC721 is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /**
     * @dev Mints a new token to the specified address
     * @param to The address that will receive the minted token
     * @param tokenId The ID of the token to mint
     */
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    /**
     * @dev Burns a token
     * @param tokenId The ID of the token to burn
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}
