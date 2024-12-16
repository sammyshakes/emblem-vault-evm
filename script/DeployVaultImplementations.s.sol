// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";

/**
 * @title DeployVaultImplementations
 * @notice Script to deploy and verify vault implementation contracts
 * @dev Run with `forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url <your_rpc_url> --broadcast --verify`
 */
contract DeployVaultImplementations is Script {
    event Deployed(string name, address addr);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Vault Implementations with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy ERC721 Implementation
        ERC721VaultImplementation erc721Implementation = new ERC721VaultImplementation();
        emit Deployed("ERC721VaultImplementation", address(erc721Implementation));
        console.log("ERC721VaultImplementation deployed at:", address(erc721Implementation));

        // Deploy ERC1155 Implementation
        ERC1155VaultImplementation erc1155Implementation = new ERC1155VaultImplementation();
        emit Deployed("ERC1155VaultImplementation", address(erc1155Implementation));
        console.log("ERC1155VaultImplementation deployed at:", address(erc1155Implementation));

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\nImplementation Deployment Summary:");
        console.log("--------------------------------");
        console.log("ERC721 Implementation:", address(erc721Implementation));
        console.log("ERC1155 Implementation:", address(erc1155Implementation));
    }
}
