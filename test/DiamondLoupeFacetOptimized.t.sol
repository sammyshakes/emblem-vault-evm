// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {DiamondLoupeFacetOptimized} from "../src/facets/DiamondLoupeFacetOptimized.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {LibDiamond} from "../src/libraries/LibDiamond.sol";
import {LibInterfaceIds} from "../src/libraries/LibInterfaceIds.sol";

contract DiamondLoupeFacetOptimizedTest is Test {
    EmblemVaultDiamond diamondOriginal;
    EmblemVaultDiamond diamondOptimized;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet loupeOriginal;
    DiamondLoupeFacetOptimized loupeOptimized;
    bytes4[] selectors;
    address[] facets;
    bytes4[] interfaceIds;

    function setUp() public {
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        loupeOriginal = new DiamondLoupeFacet();
        loupeOptimized = new DiamondLoupeFacetOptimized();

        // Deploy Diamonds
        diamondOriginal = new EmblemVaultDiamond(address(this), address(diamondCutFacet));
        diamondOptimized = new EmblemVaultDiamond(address(this), address(diamondCutFacet));

        // Build cut struct for original
        IDiamondCut.FacetCut[] memory cutOriginal = new IDiamondCut.FacetCut[](1);
        bytes4[] memory loupeSelectors = new bytes4[](9);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.getFacetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        loupeSelectors[5] = DiamondLoupeFacet.getFacetAddresses.selector;
        loupeSelectors[6] = DiamondLoupeFacet.batchFacetFunctionSelectors.selector;
        loupeSelectors[7] = DiamondLoupeFacet.supportsInterfaces.selector;
        loupeSelectors[8] = DiamondLoupeFacet.batchFacets.selector;

        cutOriginal[0] = IDiamondCut.FacetCut({
            facetAddress: address(loupeOriginal),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Build cut struct for optimized
        IDiamondCut.FacetCut[] memory cutOptimized = new IDiamondCut.FacetCut[](1);
        cutOptimized[0] = IDiamondCut.FacetCut({
            facetAddress: address(loupeOptimized),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Add facets to diamonds
        IDiamondCut(address(diamondOriginal)).diamondCut(cutOriginal, address(0), "");
        IDiamondCut(address(diamondOptimized)).diamondCut(cutOptimized, address(0), "");

        // Setup test data
        selectors = loupeSelectors;
        facets = new address[](9);
        for (uint256 i; i < 9; i++) {
            facets[i] = address(loupeOriginal);
        }

        interfaceIds = new bytes4[](4);
        interfaceIds[0] = LibInterfaceIds.INTERFACE_ID_ERC165;
        interfaceIds[1] = LibInterfaceIds.INTERFACE_ID_DIAMOND_CUT;
        interfaceIds[2] = LibInterfaceIds.INTERFACE_ID_DIAMOND_LOUPE;
        interfaceIds[3] = LibInterfaceIds.INTERFACE_ID_ERC173;
    }

    function testGasComparisonFacets() public {
        // Original
        uint256 gasStartOriginal = gasleft();
        DiamondLoupeFacet(address(diamondOriginal)).facets();
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        DiamondLoupeFacetOptimized(address(diamondOptimized)).facets();
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original facets)", gasOriginal);
        emit log_named_uint("Gas used (optimized facets)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonBatchFacets() public {
        // Original
        uint256 gasStartOriginal = gasleft();
        DiamondLoupeFacet(address(diamondOriginal)).batchFacets(facets);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        DiamondLoupeFacetOptimized(address(diamondOptimized)).batchFacets(facets);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original batchFacets)", gasOriginal);
        emit log_named_uint("Gas used (optimized batchFacets)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonBatchSelectors() public {
        // Original
        uint256 gasStartOriginal = gasleft();
        DiamondLoupeFacet(address(diamondOriginal)).batchFacetFunctionSelectors(facets);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        DiamondLoupeFacetOptimized(address(diamondOptimized)).batchFacetFunctionSelectors(facets);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original batchSelectors)", gasOriginal);
        emit log_named_uint("Gas used (optimized batchSelectors)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonSupportsInterfaces() public {
        // Original
        uint256 gasStartOriginal = gasleft();
        DiamondLoupeFacet(address(diamondOriginal)).supportsInterfaces(interfaceIds);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        DiamondLoupeFacetOptimized(address(diamondOptimized)).supportsInterfaces(interfaceIds);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original supportsInterfaces)", gasOriginal);
        emit log_named_uint("Gas used (optimized supportsInterfaces)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonGetFacetAddresses() public {
        // Original
        uint256 gasStartOriginal = gasleft();
        DiamondLoupeFacet(address(diamondOriginal)).getFacetAddresses(selectors);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        DiamondLoupeFacetOptimized(address(diamondOptimized)).getFacetAddresses(selectors);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original getFacetAddresses)", gasOriginal);
        emit log_named_uint("Gas used (optimized getFacetAddresses)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }
}
