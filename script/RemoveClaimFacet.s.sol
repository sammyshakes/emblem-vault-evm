// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";

contract RemoveClaimFacet is Script {
    function run() external {
        // Get deployment private key and diamond address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diamond = vm.envAddress("DIAMOND_ADDRESS");

        console.log("Removing ClaimFacet functions from diamond at:", diamond);

        vm.startBroadcast(deployerPrivateKey);

        // Create cut array with ClaimFacet function selectors to remove
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = bytes4(0xaad3ec96); // claim(uint256,bytes)
        selectors[1] = bytes4(0x6bb25d13); // claimWithSignedPrice(uint256,uint256,bytes)
        selectors[2] = bytes4(0xa4700096); // isTokenClaimed(uint256)

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), // Remove functions
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectors
        });

        // Perform diamond cut to remove functions
        IDiamondCut(diamond).diamondCut(cut, address(0), "");

        vm.stopBroadcast();

        console.log("\nClaimFacet Removal Summary:");
        console.log("--------------------------------");
        console.log("Diamond:", diamond);
        console.log("Functions removed:", "claim, claimWithSignedPrice, isTokenClaimed");
    }
}
