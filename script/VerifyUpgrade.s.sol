// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultCollectionFacet} from "../src/facets/EmblemVaultCollectionFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";

/**
 * @title VerifyUpgrade
 * @notice Script to verify the diamond upgrade was successful
 * @dev Run with `forge script script/VerifyUpgrade.s.sol:VerifyUpgrade --rpc-url mainnet`
 */
contract VerifyUpgrade is Script {
    function run() external view {
        // Get diamond address
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        console.log("Verifying upgrade for diamond at:", diamond);

        // 1. Verify version functions
        string memory initVersion = EmblemVaultInitFacet(diamond).getInitVersion();
        string memory coreVersion = EmblemVaultCoreFacet(diamond).getCoreVersion();
        string memory mintVersion = EmblemVaultMintFacet(diamond).getMintVersion();
        string memory collectionVersion = EmblemVaultCollectionFacet(diamond).getCollectionVersion();

        console.log("\nVersion Check:");
        console.log("------------");
        console.log("InitFacet Version:", initVersion);
        console.log("CoreFacet Version:", coreVersion);
        console.log("MintFacet Version:", mintVersion);
        console.log("CollectionFacet Version:", collectionVersion);

        // 2. Verify initialization state
        bool isInitialized = EmblemVaultInitFacet(diamond).isInitialized();
        (address owner, bool initialized, uint256 witnessCount) =
            EmblemVaultInitFacet(diamond).getInitializationDetails();

        console.log("\nInitialization Check:");
        console.log("-------------------");
        console.log("Is Initialized:", isInitialized);
        console.log("Owner:", owner);
        console.log("Witness Count:", witnessCount);

        // 3. Verify collection configuration
        address factory = EmblemVaultCollectionFacet(diamond).getCollectionFactory();
        address collectionOwner = EmblemVaultCollectionFacet(diamond).getCollectionOwner();

        console.log("\nCollection Configuration:");
        console.log("-----------------------");
        console.log("Factory:", factory);
        console.log("Collection Owner:", collectionOwner);

        // 4. Verify core configuration
        address vaultFactory = EmblemVaultCoreFacet(diamond).getVaultFactory();
        uint256 witnessCountCore = EmblemVaultCoreFacet(diamond).getWitnessCount();

        console.log("\nCore Configuration:");
        console.log("------------------");
        console.log("Vault Factory:", vaultFactory);
        console.log("Witness Count:", witnessCountCore);

        console.log("\nVerification complete. Check all values match expected state.");
    }
}
