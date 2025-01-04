// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/facets/EmblemVaultCollectionFacet.sol";

/**
 * @title CreateERC721Collection
 * @notice Script to create an ERC721A vault collection
 * @dev Run with `forge script script/CreateERC721Collection.s.sol:CreateERC721Collection --rpc-url mainnet --broadcast -vvvv`
 */
contract CreateERC721Collection is Script {
    // Constant from LibCollectionTypes
    uint8 constant ERC721_TYPE = 1;

    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");

        console.log("Creating ERC721A Collection with deployer:", deployer);
        console.log("Diamond Address:", diamondAddress);

        EmblemVaultCollectionFacet diamond = EmblemVaultCollectionFacet(diamondAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Create ERC721A Collection
        address erc721Collection =
            diamond.createVaultCollection("Diamond Hands Collection", "DHC", ERC721_TYPE);
        console.log("\nERC721A Collection created at:", erc721Collection);

        vm.stopBroadcast();

        // Verify collection was created successfully
        require(diamond.isCollection(erc721Collection), "ERC721A collection not registered");

        console.log("\nERC721A Collection Creation Complete");
        console.log("--------------------------------");
        console.log("ERC721A Collection:", erc721Collection);
        console.log("ERC721A Base URI: https://v2.emblemvault.io/meta/ (default)");
    }
}
