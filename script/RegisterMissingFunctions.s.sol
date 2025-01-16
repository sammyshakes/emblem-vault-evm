// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";

/**
 * @title RegisterMissingFunctions
 * @notice Script to register missing function selectors in the diamond contract
 * @dev Run with `forge script script/RegisterMissingFunctions.s.sol:RegisterMissingFunctions --rpc-url <your_rpc_url> --broadcast`
 */
contract RegisterMissingFunctions is Script {
    function run() external {
        // Get deployment private key and diamond address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        address coreFacet = vm.envAddress("CORE_FACET");

        console.log("Registering missing functions for diamond at:", diamond);
        console.log("Using CoreFacet at:", coreFacet);

        vm.startBroadcast(deployerPrivateKey);

        // Create cuts array for the missing functions
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);

        // Add missing CoreFacet selectors
        bytes4[] memory missingCoreSelectors = new bytes4[](5);
        missingCoreSelectors[0] = EmblemVaultCoreFacet.getRecipientAddress.selector;
        missingCoreSelectors[1] = EmblemVaultCoreFacet.getMetadataBaseUri.selector;
        missingCoreSelectors[2] = EmblemVaultCoreFacet.toggleBypassability.selector;
        missingCoreSelectors[3] = EmblemVaultCoreFacet.addBypassRule.selector;
        missingCoreSelectors[4] = EmblemVaultCoreFacet.removeBypassRule.selector;

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: coreFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: missingCoreSelectors
        });

        // Execute the diamond cut
        IDiamondCut(diamond).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        console.log("\nFunction Registration Summary:");
        console.log("--------------------------------");
        console.log("Added CoreFacet functions:");
        console.log("- getRecipientAddress");
        console.log("- getMetadataBaseUri");
        console.log("- toggleBypassability");
        console.log("- addBypassRule");
        console.log("- removeBypassRule");
    }
}
