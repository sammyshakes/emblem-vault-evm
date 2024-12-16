// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DeployDiamond (DEPRECATED)
 * @dev This script is deprecated in favor of DeployDiamondSystem.s.sol which provides:
 * - Better deployment tracking through events
 * - Improved console output formatting
 * - More detailed documentation
 * - The same core functionality with better organization
 *
 * Please use `forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url <your_rpc_url> --broadcast`
 * instead of this script.
 */
import "forge-std/Script.sol";
import {DeployDiamondSystem} from "./DeployDiamondSystem.s.sol";

contract DeployDiamond is Script {
    function run() external {
        console.log(
            "\n[DEPRECATED] This script is deprecated. Please use DeployDiamondSystem.s.sol instead."
        );
        console.log(
            "Run: forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url <your_rpc_url> --broadcast"
        );
        console.log("See script/DeployDiamondSystem.s.sol for the new implementation.\n");

        // Forward to the new implementation
        DeployDiamondSystem newImplementation = new DeployDiamondSystem();
        newImplementation.run();
    }
}
