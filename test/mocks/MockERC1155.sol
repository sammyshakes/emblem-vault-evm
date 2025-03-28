// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title MockERC1155
 * @dev A simple ERC1155 implementation for testing purposes
 */
contract MockERC1155 is ERC1155 {
    constructor(string memory uri) ERC1155(uri) {}

    /**
     * @dev Mints a new token to the specified address
     * @param to The address that will receive the minted token
     * @param id The ID of the token to mint
     * @param amount The amount of tokens to mint
     * @param data Additional data to pass along with the mint operation
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Mints multiple tokens to the specified address
     * @param to The address that will receive the minted tokens
     * @param ids Array of token IDs to mint
     * @param amounts Array of amounts to mint for each token ID
     * @param data Additional data to pass along with the mint operation
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Burns tokens from the specified address
     * @param from The address to burn tokens from
     * @param id The ID of the token to burn
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 id, uint256 amount) external {
        _burn(from, id, amount);
    }

    /**
     * @dev Burns multiple tokens from the specified address
     * @param from The address to burn tokens from
     * @param ids Array of token IDs to burn
     * @param amounts Array of amounts to burn for each token ID
     */
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external {
        _burnBatch(from, ids, amounts);
    }
}
