// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultCollectionFacet} from "../src/facets/EmblemVaultCollectionFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";

/**
 * @title UpdateDeploymentReport
 * @notice Script to update deployment report after upgrade
 * @dev Run with `forge script script/UpdateDeploymentReport.s.sol:UpdateDeploymentReport --rpc-url mainnet`
 */
contract UpdateDeploymentReport is Script {
    function run() external {
        // Get diamond address and upgrade tx hash
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        string memory upgradeTx = vm.envString("UPGRADE_TX");

        // Get facet versions
        string memory initVersion = EmblemVaultInitFacet(diamond).getInitVersion();
        string memory coreVersion = EmblemVaultCoreFacet(diamond).getCoreVersion();
        string memory mintVersion = EmblemVaultMintFacet(diamond).getMintVersion();
        string memory collectionVersion = EmblemVaultCollectionFacet(diamond).getCollectionVersion();

        // Generate report content
        string memory report = string.concat(
            "# Diamond Upgrade Summary\n\n",
            "## Upgrade Details\n",
            "- Diamond Address: `",
            vm.toString(diamond),
            "`\n",
            "- Upgrade Transaction: `",
            upgradeTx,
            "`\n\n",
            "## Facet Versions\n",
            "- InitFacet: ",
            initVersion,
            "\n",
            "- CoreFacet: ",
            coreVersion,
            "\n",
            "- MintFacet: ",
            mintVersion,
            "\n",
            "- CollectionFacet: ",
            collectionVersion,
            "\n\n",
            "## Configuration\n",
            "- Collection Factory: `",
            vm.toString(EmblemVaultCollectionFacet(diamond).getCollectionFactory()),
            "`\n",
            "- Collection Owner: `",
            vm.toString(EmblemVaultCollectionFacet(diamond).getCollectionOwner()),
            "`\n",
            "- Vault Factory: `",
            vm.toString(EmblemVaultCoreFacet(diamond).getVaultFactory()),
            "`\n",
            "- Witness Count: ",
            vm.toString(EmblemVaultCoreFacet(diamond).getWitnessCount()),
            "\n\n",
            "## New Functions Added\n",
            "- `getInitVersion()` - Returns InitFacet version\n",
            "- `getCoreVersion()` - Returns CoreFacet version\n",
            "- `getMintVersion()` - Returns MintFacet version\n",
            "- `getCollectionVersion()` - Returns CollectionFacet version\n",
            "- `getCollectionType()` - Returns collection type\n",
            "- `setCollectionOwner()` - Sets collection owner\n",
            "- `getCollectionOwner()` - Returns collection owner\n"
        );

        // Write to file
        vm.writeFile("UPGRADE_REPORT.md", report);
        console.log("Upgrade report written to UPGRADE_REPORT.md");
    }
}
