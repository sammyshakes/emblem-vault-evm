// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/factories/VaultFactory.sol";

/**
 * @title DeployBeaconSystem
 * @notice Script to deploy the complete beacon system for vaults
 * @dev Run with `forge script script/DeployBeaconSystem.s.sol:DeployBeaconSystem --rpc-url <your_rpc_url> --broadcast`
 */
contract DeployBeaconSystem is Script {
    // Events for tracking deployments
    event Deployed(string name, address addr);

    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Beacon System with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Implementations
        ERC721VaultImplementation erc721Implementation = new ERC721VaultImplementation();
        emit Deployed("ERC721VaultImplementation", address(erc721Implementation));
        console.log("ERC721VaultImplementation deployed at:", address(erc721Implementation));

        ERC1155VaultImplementation erc1155Implementation = new ERC1155VaultImplementation();
        emit Deployed("ERC1155VaultImplementation", address(erc1155Implementation));
        console.log("ERC1155VaultImplementation deployed at:", address(erc1155Implementation));

        // 2. Deploy Beacons
        VaultBeacon erc721Beacon = new ERC721VaultBeacon(address(erc721Implementation));
        emit Deployed("ERC721VaultBeacon", address(erc721Beacon));
        console.log("ERC721VaultBeacon deployed at:", address(erc721Beacon));

        VaultBeacon erc1155Beacon = new ERC1155VaultBeacon(address(erc1155Implementation));
        emit Deployed("ERC1155VaultBeacon", address(erc1155Beacon));
        console.log("ERC1155VaultBeacon deployed at:", address(erc1155Beacon));

        // 3. Deploy Factory
        VaultFactory factory = new VaultFactory(address(erc721Beacon), address(erc1155Beacon));
        emit Deployed("VaultFactory", address(factory));
        console.log("VaultFactory deployed at:", address(factory));

        // 4. Deploy test vaults if on testnet
        if (block.chainid != 1) {
            // Not mainnet
            // Deploy test ERC721 vault
            address erc721Vault = factory.createERC721Vault("Test Vault", "TEST");
            emit Deployed("TestERC721Vault", erc721Vault);
            console.log("Test ERC721 Vault deployed at:", erc721Vault);

            // Deploy test ERC1155 vault
            address erc1155Vault = factory.createERC1155Vault("https://test.uri/");
            emit Deployed("TestERC1155Vault", erc1155Vault);
            console.log("Test ERC1155 Vault deployed at:", erc1155Vault);
        }

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\nDeployment Summary:");
        console.log("------------------");
        console.log("ERC721 Implementation:", address(erc721Implementation));
        console.log("ERC1155 Implementation:", address(erc1155Implementation));
        console.log("ERC721 Beacon:", address(erc721Beacon));
        console.log("ERC1155 Beacon:", address(erc1155Beacon));
        console.log("Factory:", address(factory));
    }
}

/**
 * @title UpgradeBeaconSystem
 * @notice Script to upgrade implementations in the beacon system
 * @dev Run with `forge script script/DeployBeaconSystem.s.sol:UpgradeBeaconSystem --rpc-url <your_rpc_url> --broadcast`
 */
contract UpgradeBeaconSystem is Script {
    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get existing beacon addresses from environment
        address erc721Beacon = vm.envAddress("ERC721_BEACON_ADDRESS");
        address erc1155Beacon = vm.envAddress("ERC1155_BEACON_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementations
        ERC721VaultImplementation newErc721Implementation = new ERC721VaultImplementation();
        console.log("New ERC721VaultImplementation deployed at:", address(newErc721Implementation));

        ERC1155VaultImplementation newErc1155Implementation = new ERC1155VaultImplementation();
        console.log("New ERC1155VaultImplementation deployed at:", address(newErc1155Implementation));

        // Upgrade beacons
        VaultBeacon(erc721Beacon).upgrade(address(newErc721Implementation));
        console.log("ERC721 Beacon upgraded to new implementation");

        VaultBeacon(erc1155Beacon).upgrade(address(newErc1155Implementation));
        console.log("ERC1155 Beacon upgraded to new implementation");

        vm.stopBroadcast();

        // Log upgrade summary
        console.log("\nUpgrade Summary:");
        console.log("---------------");
        console.log("New ERC721 Implementation:", address(newErc721Implementation));
        console.log("New ERC1155 Implementation:", address(newErc1155Implementation));
        console.log("ERC721 Beacon:", erc721Beacon);
        console.log("ERC1155 Beacon:", erc1155Beacon);
    }
}
