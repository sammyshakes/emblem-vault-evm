// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {LibDiamond} from "../src/libraries/LibDiamond.sol";
import {LibInterfaceIds} from "../src/libraries/LibInterfaceIds.sol";

contract DiamondLoupeBatchTest is Test {
    EmblemVaultDiamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet loupe;
    bytes4[] selectors;
    address[] facets;
    bytes4[] interfaceIds;

    function setUp() public {
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        loupe = new DiamondLoupeFacet();

        // Deploy Diamond
        diamond = new EmblemVaultDiamond(address(this), address(diamondCutFacet));

        // Build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        // DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](9);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.getFacetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        // Add batch function selectors
        loupeSelectors[5] = DiamondLoupeFacet.getFacetAddresses.selector;
        loupeSelectors[6] = DiamondLoupeFacet.batchFacetFunctionSelectors.selector;
        loupeSelectors[7] = DiamondLoupeFacet.supportsInterfaces.selector;
        loupeSelectors[8] = DiamondLoupeFacet.batchFacets.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(loupe),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Setup test data
        selectors = loupeSelectors;
        facets = new address[](9);
        for (uint256 i; i < 9; i++) {
            facets[i] = address(loupe);
        }

        // Use diamond interfaces instead of token interfaces
        interfaceIds = new bytes4[](4);
        interfaceIds[0] = LibInterfaceIds.INTERFACE_ID_ERC165; // ERC165
        interfaceIds[1] = LibInterfaceIds.INTERFACE_ID_DIAMOND_CUT; // Diamond Cut
        interfaceIds[2] = LibInterfaceIds.INTERFACE_ID_DIAMOND_LOUPE; // Diamond Loupe
        interfaceIds[3] = LibInterfaceIds.INTERFACE_ID_ERC173; // Ownership
    }

    function testBatchGetFacetAddresses() public view {
        address[] memory addresses =
            DiamondLoupeFacet(address(diamond)).getFacetAddresses(selectors);
        assertEq(addresses.length, selectors.length, "Wrong number of addresses");
        for (uint256 i; i < addresses.length; i++) {
            assertEq(addresses[i], address(loupe), "Incorrect facet address");
        }
    }

    function testBatchFacetFunctionSelectors() public view {
        bytes4[][] memory selectorArrays =
            DiamondLoupeFacet(address(diamond)).batchFacetFunctionSelectors(facets);
        assertEq(selectorArrays.length, facets.length, "Wrong number of selector arrays");
        for (uint256 i; i < selectorArrays.length; i++) {
            assertEq(selectorArrays[i].length, selectors.length, "Wrong number of selectors");
            for (uint256 j; j < selectors.length; j++) {
                assertEq(selectorArrays[i][j], selectors[j], "Wrong selector");
            }
        }
    }

    function testBatchSupportsInterfaces() public view {
        bool[] memory supported =
            DiamondLoupeFacet(address(diamond)).supportsInterfaces(interfaceIds);
        assertEq(supported.length, interfaceIds.length, "Wrong number of interface results");
        for (uint256 i; i < supported.length; i++) {
            assertTrue(supported[i], "Interface should be supported");
        }
    }

    function testBatchFacets() public view {
        DiamondLoupeFacet.Facet[] memory facetInfo =
            DiamondLoupeFacet(address(diamond)).batchFacets(facets);
        assertEq(facetInfo.length, facets.length, "Wrong number of facets");
        for (uint256 i; i < facetInfo.length; i++) {
            assertEq(facetInfo[i].facetAddress, facets[i], "Wrong facet address");
            assertEq(
                facetInfo[i].functionSelectors.length, selectors.length, "Wrong number of selectors"
            );
            for (uint256 j; j < selectors.length; j++) {
                assertEq(facetInfo[i].functionSelectors[j], selectors[j], "Wrong selector");
            }
        }
    }

    function testEmptyArrays() public view {
        // Test with empty arrays
        address[] memory emptyAddresses = new address[](0);
        bytes4[] memory emptySelectors = new bytes4[](0);

        bytes4[][] memory emptySelectorArrays =
            DiamondLoupeFacet(address(diamond)).batchFacetFunctionSelectors(emptyAddresses);
        assertEq(emptySelectorArrays.length, 0, "Empty selector arrays");

        address[] memory emptyFacets =
            DiamondLoupeFacet(address(diamond)).getFacetAddresses(emptySelectors);
        assertEq(emptyFacets.length, 0, "Empty facets");

        bool[] memory emptySupported =
            DiamondLoupeFacet(address(diamond)).supportsInterfaces(emptySelectors);
        assertEq(emptySupported.length, 0, "Empty interface results");

        DiamondLoupeFacet.Facet[] memory emptyFacetInfo =
            DiamondLoupeFacet(address(diamond)).batchFacets(emptyAddresses);
        assertEq(emptyFacetInfo.length, 0, "Empty facet info");
    }

    function testGasComparison() public {
        // Single calls
        uint256 gasSingleTotal;
        for (uint256 i; i < selectors.length; i++) {
            uint256 gasStartSingle = gasleft();
            DiamondLoupeFacet(address(diamond)).getFacetAddress(selectors[i]);
            gasSingleTotal += gasStartSingle - gasleft();
        }

        // Batch call
        uint256 gasStartBatch = gasleft();
        DiamondLoupeFacet(address(diamond)).getFacetAddresses(selectors);
        uint256 gasBatch = gasStartBatch - gasleft();

        emit log_named_uint("Gas used (single calls)", gasSingleTotal);
        emit log_named_uint("Gas used (batch call)", gasBatch);
        assertTrue(gasBatch < gasSingleTotal, "Batch call should use less gas");
    }
}
