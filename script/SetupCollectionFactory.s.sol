// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/facets/EmblemVaultCollectionFacet.sol";

/**
 * @title SetupCollectionFactory
 * @notice Script to set the collection factory in the diamond
 * @dev Run with `forge script script/SetupCollectionFactory.s.sol:SetupCollectionFactory --rpc-url $BSC_TESTNET_RPC_URL --broadcast`
 */
contract SetupCollectionFactory is Script {
    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get contract addresses from environment
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        address factoryAddress = vm.envAddress("COLLECTION_FACTORY_ADDRESS");

        console.log("Setting Collection Factory with deployer:", deployer);
        console.log("Diamond Address:", diamondAddress);
        console.log("Factory Address:", factoryAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Set the collection factory
        EmblemVaultCollectionFacet(diamondAddress).setCollectionFactory(factoryAddress);

        vm.stopBroadcast();

        console.log("\nCollection Factory Setup Complete");
        console.log("--------------------------------");
        console.log("Factory set in Diamond at:", diamondAddress);
    }
}
