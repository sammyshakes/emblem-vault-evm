// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/facets/EmblemVaultCoreFacet.sol";

contract AddWitness is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diamond = vm.envAddress("DIAMOND_ADDRESS");

        // Server's signing address recovered from signature verification
        address witness = 0xCe42bD06274B6908bd7379bd3ce72D55EB8207B4;

        vm.startBroadcast(deployerPrivateKey);

        // Add witness through CoreFacet
        EmblemVaultCoreFacet(diamond).addWitness(witness);

        vm.stopBroadcast();
    }
}
