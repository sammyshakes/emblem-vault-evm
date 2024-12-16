// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/EmblemVaultDiamond.sol";
import "../src/EmblemVaultDiamondOptimized.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/EmblemVaultCoreFacet.sol";
import "../src/libraries/LibDiamond.sol";

contract DiamondGasComparisonTest is Test {
    EmblemVaultDiamond public diamond;
    EmblemVaultDiamondOptimized public optimizedDiamond;
    DiamondCutFacet public cutFacet;
    DiamondLoupeFacet public loupeFacet;
    EmblemVaultCoreFacet public coreFacet;

    // Events for verification
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        // Deploy facets
        cutFacet = new DiamondCutFacet();
        loupeFacet = new DiamondLoupeFacet();
        coreFacet = new EmblemVaultCoreFacet();

        // Deploy diamonds
        vm.recordLogs();
        diamond = new EmblemVaultDiamond(address(this), address(cutFacet));
        optimizedDiamond = new EmblemVaultDiamondOptimized(address(this), address(cutFacet));

        // Add facets to both diamonds
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](2);

        // Add loupe facet
        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.getFacetAddress.selector;

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(loupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Add core facet
        bytes4[] memory coreSelectors = new bytes4[](2);
        coreSelectors[0] = EmblemVaultCoreFacet.setMetadataBaseUri.selector;
        coreSelectors[1] = EmblemVaultCoreFacet.setRecipientAddress.selector;

        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(coreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: coreSelectors
        });

        // Add facets to both diamonds
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), new bytes(0));
        IDiamondCut(address(optimizedDiamond)).diamondCut(cuts, address(0), new bytes(0));
    }

    function testDeploymentGas() public {
        // Deploy new instances to measure deployment gas
        vm.pauseGasMetering();
        address cutFacetAddr = address(cutFacet);
        vm.resumeGasMetering();

        uint256 gasBefore = gasleft();
        new EmblemVaultDiamond(address(this), cutFacetAddr);
        uint256 originalGas = gasBefore - gasleft();

        gasBefore = gasleft();
        new EmblemVaultDiamondOptimized(address(this), cutFacetAddr);
        uint256 optimizedGas = gasBefore - gasleft();

        console.log("Deployment Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas - optimizedGas);
    }

    function testFacetCallGas() public {
        string memory baseURI = "https://api.test.com/";

        // Test core facet call
        uint256 gasBefore = gasleft();
        EmblemVaultCoreFacet(address(diamond)).setMetadataBaseUri(baseURI);
        uint256 originalGas = gasBefore - gasleft();

        gasBefore = gasleft();
        EmblemVaultCoreFacet(address(optimizedDiamond)).setMetadataBaseUri(baseURI);
        uint256 optimizedGas = gasBefore - gasleft();

        console.log("Facet Call Gas Comparison (setMetadataBaseUri):");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas - optimizedGas);
    }

    function testDiamondCutGas() public {
        // Prepare a new facet cut
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = bytes4(keccak256("test()"));

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(0x123),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        // Test diamond cut
        uint256 gasBefore = gasleft();
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), new bytes(0));
        uint256 originalGas = gasBefore - gasleft();

        gasBefore = gasleft();
        IDiamondCut(address(optimizedDiamond)).diamondCut(cuts, address(0), new bytes(0));
        uint256 optimizedGas = gasBefore - gasleft();

        console.log("Diamond Cut Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas - optimizedGas);
    }

    function testMultipleCallsGas() public {
        string memory baseURI = "https://api.test.com/";
        address recipient = address(0x123);

        // Test multiple facet calls
        uint256 gasBefore = gasleft();
        EmblemVaultCoreFacet(address(diamond)).setMetadataBaseUri(baseURI);
        EmblemVaultCoreFacet(address(diamond)).setRecipientAddress(recipient);
        DiamondLoupeFacet(address(diamond)).facets();
        uint256 originalGas = gasBefore - gasleft();

        gasBefore = gasleft();
        EmblemVaultCoreFacet(address(optimizedDiamond)).setMetadataBaseUri(baseURI);
        EmblemVaultCoreFacet(address(optimizedDiamond)).setRecipientAddress(recipient);
        DiamondLoupeFacet(address(optimizedDiamond)).facets();
        uint256 optimizedGas = gasBefore - gasleft();

        console.log("Multiple Facet Calls Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas - optimizedGas);
    }

    receive() external payable {}
}
