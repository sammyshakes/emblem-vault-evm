// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";

interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function facets() external view returns (Facet[] memory facets_);
}

contract DisableDiamondScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Address of the diamond to disable
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");

        // Get all facets
        IDiamondLoupe.Facet[] memory facets = IDiamondLoupe(diamondAddress).facets();

        // Create cut to remove all facets except DiamondCutFacet
        // We need to keep DiamondCutFacet to be able to add facets back if needed
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](facets.length - 1);

        uint256 cutIndex = 0;
        for (uint256 i = 0; i < facets.length; i++) {
            // Skip DiamondCutFacet
            bytes4[] memory selectors = facets[i].functionSelectors;
            bool isDiamondCutFacet = false;

            // Check if this facet contains the diamondCut function selector
            for (uint256 j = 0; j < selectors.length; j++) {
                if (selectors[j] == IDiamondCut.diamondCut.selector) {
                    isDiamondCutFacet = true;
                    break;
                }
            }

            if (!isDiamondCutFacet) {
                cut[cutIndex] = IDiamondCut.FacetCut({
                    facetAddress: address(0), // Remove facet
                    action: IDiamondCut.FacetCutAction.Remove,
                    functionSelectors: selectors
                });
                cutIndex++;
            }
        }

        // Perform the cut
        IDiamondCut(diamondAddress).diamondCut(cut, address(0), "");

        console2.log("Diamond at %s has been disabled", diamondAddress);
        console2.log("All facets have been removed except DiamondCutFacet");

        vm.stopBroadcast();
    }
}
