// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/facets/EmblemVaultCollectionFacet.sol";

/**
 * @title CreateERC1155Collection
 * @notice Script to create an ERC1155 vault collection
 * @dev Run with `forge script script/CreateERC1155Collection.s.sol:CreateERC1155Collection --rpc-url mainnet --broadcast -vvvv`
 */
contract CreateERC1155Collection is Script {
    // Constant from LibCollectionTypes
    uint8 constant ERC1155_TYPE = 2;

    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");

        console.log("Creating ERC1155 Collection with deployer:", deployer);
        console.log("Diamond Address:", diamondAddress);

        EmblemVaultCollectionFacet diamond = EmblemVaultCollectionFacet(diamondAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Create ERC1155 Collection
        // Note: For ERC1155, the second parameter is used as the URI instead of a symbol
        address erc1155Collection = diamond.createVaultCollection(
            "Diamond Hands Multi Collection",
            "https://api.emblem.finance/erc1155/metadata/{id}.json",
            ERC1155_TYPE
        );
        console.log("\nERC1155 Collection created at:", erc1155Collection);

        vm.stopBroadcast();

        // Verify collection was created successfully
        require(diamond.isCollection(erc1155Collection), "ERC1155 collection not registered");

        console.log("\nERC1155 Collection Creation Complete");
        console.log("--------------------------------");
        console.log("ERC1155 Collection:", erc1155Collection);
        console.log("ERC1155 URI: https://api.emblem.finance/erc1155/metadata/{id}.json");
    }
}
