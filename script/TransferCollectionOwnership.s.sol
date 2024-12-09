// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/factories/VaultCollectionFactory.sol";

/**
 * @title TransferCollectionOwnership
 * @notice Script to transfer collection ownership from factory to diamond
 * @dev Run with `forge script script/TransferCollectionOwnership.s.sol:TransferCollectionOwnership --rpc-url bsc_testnet --broadcast -vvvv`
 */
contract TransferCollectionOwnership is Script {
    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        address factoryAddress = vm.envAddress("COLLECTION_FACTORY_ADDRESS");

        console.log("Transferring Collection Ownership");
        console.log("Deployer:", deployer);
        console.log("Diamond:", diamond);
        console.log("Factory:", factoryAddress);

        // Collections to transfer
        address erc721Collection = 0x7587d6A2e67eD18cA8279820e608894cC5c145A5;
        address erc1155Collection = 0x064724D71E0B3C2bB03384d1188A2F34144a13bd;

        vm.startBroadcast(deployerPrivateKey);

        VaultCollectionFactory factory = VaultCollectionFactory(factoryAddress);

        // Transfer ERC721 collection ownership
        factory.transferCollectionOwnership(erc721Collection, diamond);
        console.log("Transferred ERC721 collection ownership to diamond");

        // Transfer ERC1155 collection ownership
        factory.transferCollectionOwnership(erc1155Collection, diamond);
        console.log("Transferred ERC1155 collection ownership to diamond");

        vm.stopBroadcast();

        console.log("\nOwnership Transfer Complete");
        console.log("--------------------------------");
        console.log("ERC721 Collection:", erc721Collection);
        console.log("ERC1155 Collection:", erc1155Collection);
        console.log("New Owner (Diamond):", diamond);
    }
}
