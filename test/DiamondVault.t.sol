// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/facets/VaultFacet.sol";
import "../src/interfaces/IDiamondCut.sol";

contract DiamondVaultTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    VaultFacet vaultFacet;

    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        vaultFacet = new VaultFacet();

        // Deploy Diamond
        diamond = new Diamond(owner, address(diamondCutFacet));

        // Build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);

        // DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.getFacetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // OwnershipFacet
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipFacet.owner.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // VaultFacet
        bytes4[] memory vaultSelectors = new bytes4[](8);
        vaultSelectors[0] = VaultFacet.lockToken.selector;
        vaultSelectors[1] = VaultFacet.unlockToken.selector;
        vaultSelectors[2] = VaultFacet.updateTokenURI.selector;
        vaultSelectors[3] = VaultFacet.isTokenLocked.selector;
        vaultSelectors[4] = VaultFacet.tokenOwner.selector;
        vaultSelectors[5] = VaultFacet.getTokenURI.selector;
        vaultSelectors[6] = VaultFacet.balanceOf.selector;
        vaultSelectors[7] = VaultFacet.totalSupply.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(vaultFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: vaultSelectors
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function testLockToken() public {
        VaultFacet(address(diamond)).lockToken(1, "ipfs://token1");

        assertTrue(VaultFacet(address(diamond)).isTokenLocked(1));
        assertEq(VaultFacet(address(diamond)).tokenOwner(1), address(this));
        assertEq(VaultFacet(address(diamond)).getTokenURI(1), "ipfs://token1");
        assertEq(VaultFacet(address(diamond)).balanceOf(address(this)), 1);
        assertEq(VaultFacet(address(diamond)).totalSupply(), 1);
    }

    function testUnlockToken() public {
        VaultFacet(address(diamond)).lockToken(1, "ipfs://token1");
        VaultFacet(address(diamond)).unlockToken(1);

        assertFalse(VaultFacet(address(diamond)).isTokenLocked(1));
        assertEq(VaultFacet(address(diamond)).tokenOwner(1), address(0));
        assertEq(VaultFacet(address(diamond)).balanceOf(address(this)), 0);
        assertEq(VaultFacet(address(diamond)).totalSupply(), 0);
    }

    function testUpdateTokenURI() public {
        VaultFacet(address(diamond)).lockToken(1, "ipfs://token1");
        VaultFacet(address(diamond)).updateTokenURI(1, "ipfs://token1-updated");

        assertEq(VaultFacet(address(diamond)).getTokenURI(1), "ipfs://token1-updated");
    }

    function testFailUnlockTokenNotOwner() public {
        VaultFacet(address(diamond)).lockToken(1, "ipfs://token1");

        vm.prank(user1);
        VaultFacet(address(diamond)).unlockToken(1);
    }

    function testFailLockTokenTwice() public {
        VaultFacet(address(diamond)).lockToken(1, "ipfs://token1");
        VaultFacet(address(diamond)).lockToken(1, "ipfs://token1");
    }

    function testFailUpdateTokenURINotOwner() public {
        VaultFacet(address(diamond)).lockToken(1, "ipfs://token1");

        vm.prank(user1);
        VaultFacet(address(diamond)).updateTokenURI(1, "ipfs://token1-updated");
    }

    function testOwnership() public {
        assertEq(OwnershipFacet(address(diamond)).owner(), address(this));

        OwnershipFacet(address(diamond)).transferOwnership(user1);
        assertEq(OwnershipFacet(address(diamond)).owner(), user1);
    }

    function testDiamondCut() public view {
        // Test that all facets were properly added
        address[] memory facetAddresses = DiamondLoupeFacet(address(diamond)).facetAddresses();
        assertEq(facetAddresses.length, 4); // DiamondCut, DiamondLoupe, Ownership, and Vault facets

        // Verify DiamondCutFacet functions
        assertEq(
            DiamondLoupeFacet(address(diamond)).getFacetAddress(DiamondCutFacet.diamondCut.selector),
            address(diamondCutFacet)
        );

        // Verify DiamondLoupeFacet functions
        assertEq(
            DiamondLoupeFacet(address(diamond)).getFacetAddress(DiamondLoupeFacet.facets.selector),
            address(diamondLoupeFacet)
        );

        // Verify OwnershipFacet functions
        assertEq(
            DiamondLoupeFacet(address(diamond)).getFacetAddress(OwnershipFacet.owner.selector), address(ownershipFacet)
        );

        // Verify VaultFacet functions
        assertEq(
            DiamondLoupeFacet(address(diamond)).getFacetAddress(VaultFacet.lockToken.selector), address(vaultFacet)
        );
    }
}
