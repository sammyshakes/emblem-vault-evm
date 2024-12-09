// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";
import "../src/beacon/VaultBeacon.sol";

/**
 * @title UpgradeBeaconImplementations
 * @notice Script to upgrade beacon implementations
 * @dev Run with `forge script script/UpgradeBeaconImplementations.s.sol:UpgradeBeaconImplementations --rpc-url <your_rpc_url> --broadcast`
 *      Set IMPLEMENTATIONS_TO_UPGRADE in .env file to specify which implementations to upgrade:
 *      IMPLEMENTATIONS_TO_UPGRADE=ERC721,ERC1155
 *
 *      Beacon addresses should be in .env.beacon file (created by DeployBeaconSystem.s.sol)
 */
contract UpgradeBeaconImplementations is Script {
    // Events for tracking upgrades
    event ImplementationUpgraded(string name, address indexed beacon, address indexed oldImpl, address indexed newImpl);

    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory implementationsToUpgrade = vm.envString("IMPLEMENTATIONS_TO_UPGRADE");

        // Load beacon addresses from .env.beacon
        address erc721Beacon = vm.envAddress("ERC721_BEACON");
        address erc1155Beacon = vm.envAddress("ERC1155_BEACON");

        console.log("Upgrading Beacon Implementations");
        console.log("Implementations to upgrade:", implementationsToUpgrade);

        vm.startBroadcast(deployerPrivateKey);

        // Parse implementations to upgrade
        string[] memory implNames = _split(implementationsToUpgrade, ",");

        // Deploy and upgrade each implementation
        for (uint256 i = 0; i < implNames.length; i++) {
            string memory implName = implNames[i];

            if (_strEquals(implName, "ERC721")) {
                // Get current implementation
                address oldImpl = VaultBeacon(erc721Beacon).implementation();

                // Deploy new implementation
                ERC721VaultImplementation newImpl = new ERC721VaultImplementation();
                console.log("New ERC721VaultImplementation deployed at:", address(newImpl));

                // Upgrade beacon
                VaultBeacon(erc721Beacon).upgrade(address(newImpl));
                console.log("ERC721 Beacon upgraded from", oldImpl, "to", address(newImpl));

                emit ImplementationUpgraded("ERC721", erc721Beacon, oldImpl, address(newImpl));
            } else if (_strEquals(implName, "ERC1155")) {
                // Get current implementation
                address oldImpl = VaultBeacon(erc1155Beacon).implementation();

                // Deploy new implementation
                ERC1155VaultImplementation newImpl = new ERC1155VaultImplementation();
                console.log("New ERC1155VaultImplementation deployed at:", address(newImpl));

                // Upgrade beacon
                VaultBeacon(erc1155Beacon).upgrade(address(newImpl));
                console.log("ERC1155 Beacon upgraded from", oldImpl, "to", address(newImpl));

                emit ImplementationUpgraded("ERC1155", erc1155Beacon, oldImpl, address(newImpl));
            }
        }

        vm.stopBroadcast();

        // Save new implementation addresses
        string memory deploymentData = string(
            abi.encodePacked(
                "# Updated on ",
                vm.toString(block.timestamp),
                "\n",
                "ERC721_IMPLEMENTATION=",
                vm.toString(VaultBeacon(erc721Beacon).implementation()),
                "\n",
                "ERC1155_IMPLEMENTATION=",
                vm.toString(VaultBeacon(erc1155Beacon).implementation()),
                "\n",
                "ERC721_BEACON=",
                vm.toString(erc721Beacon),
                "\n",
                "ERC1155_BEACON=",
                vm.toString(erc1155Beacon),
                "\n"
            )
        );
        vm.writeFile(".env.beacon", deploymentData);
        console.log("\nNew implementation addresses saved to .env.beacon");
    }

    function _split(string memory str, string memory delimiter) internal pure returns (string[] memory) {
        uint256 count = 1;
        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) count++;
        }

        string[] memory parts = new string[](count);
        uint256 partIndex = 0;
        uint256 start = 0;

        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) {
                parts[partIndex++] = _substring(str, start, i);
                start = i + 1;
            }
        }
        parts[partIndex] = _substring(str, start, bytes(str).length);

        return parts;
    }

    function _substring(string memory str, uint256 startIndex, uint256 endIndex)
        internal
        pure
        returns (string memory)
    {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _strEquals(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
