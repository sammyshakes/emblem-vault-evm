// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./DiamondVault.t.sol";
import "../src/interfaces/IERC1155.sol";
import "../src/libraries/LibEmblemVaultStorage.sol";
import "../src/libraries/LibErrors.sol";

contract ClaimTrackingTest is DiamondVaultTest {
    // Events
    event ClaimingEnabled(bool enabled);
    event BurnAddressUpdated(address indexed addr, bool isBurn);

    error TokenMappingNotFound();

    function setUp() public override {
        super.setUp();
    }

    function testClaimingEnabledByDefault() public {
        // Create signature for minting
        bytes memory signature = createSignature(
            nftCollection,
            address(0),
            1 ether,
            tokenHolder,
            2, // new token ID
            2, // new nonce
            1,
            witnessPrivateKey
        );

        // Mint token through diamond
        vm.deal(tokenHolder, 1 ether);
        vm.startPrank(tokenHolder);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, signature, "", 1
        );

        // Approve diamond
        ERC721VaultImplementation(nftCollection).setApprovalForAll(address(diamond), true);

        EmblemVaultClaimFacet(address(diamond)).claim(nftCollection, 2);
        vm.stopPrank();

        // Verify token was burned
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        ERC721VaultImplementation(nftCollection).ownerOf(2);
    }

    function testDisableClaiming() public {
        // Disable claiming
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit ClaimingEnabled(false);
        EmblemVaultClaimFacet(address(diamond)).setClaimingEnabled(false);
        vm.stopPrank();

        // Create signature for minting
        bytes memory signature = createSignature(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, 1, witnessPrivateKey
        );

        // Mint token through diamond
        vm.deal(tokenHolder, 1 ether);
        vm.startPrank(tokenHolder);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, signature, "", 1
        );

        // Approve diamond to manage tokens
        ERC721VaultImplementation(nftCollection).setApprovalForAll(address(diamond), true);

        vm.expectRevert(LibEmblemVaultStorage.ClaimingDisabled.selector);
        EmblemVaultClaimFacet(address(diamond)).claim(nftCollection, 2);
        vm.stopPrank();
    }

    function testPreventDoubleClaim() public {
        // Create signature for minting
        bytes memory signature = createSignature(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, 1, witnessPrivateKey
        );

        // Mint token through diamond
        vm.deal(tokenHolder, 1 ether);
        vm.startPrank(tokenHolder);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, signature, "", 1
        );

        // Approve for all to diamond
        ERC721VaultImplementation(nftCollection).setApprovalForAll(address(diamond), true);

        EmblemVaultClaimFacet(address(diamond)).claim(nftCollection, 2);

        // Second claim should fail with TokenMappingNotFound since the token was burned
        vm.expectRevert(TokenMappingNotFound.selector);
        EmblemVaultClaimFacet(address(diamond)).claim(nftCollection, 2);
        vm.stopPrank();
    }

    function testBurnAddressManagement() public {
        address burnAddr = address(0x123);

        // Add burn address
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit BurnAddressUpdated(burnAddr, true);
        EmblemVaultClaimFacet(address(diamond)).setBurnAddress(burnAddr, true);

        // Remove burn address
        vm.expectEmit(true, true, true, true);
        emit BurnAddressUpdated(burnAddr, false);
        EmblemVaultClaimFacet(address(diamond)).setBurnAddress(burnAddr, false);
        vm.stopPrank();
    }

    function testRevertSetBurnAddressNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, user1));
        EmblemVaultClaimFacet(address(diamond)).setBurnAddress(address(0x123), true);
        vm.stopPrank();
    }

    function testRevertSetClaimingEnabledNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, user1));
        EmblemVaultClaimFacet(address(diamond)).setClaimingEnabled(false);
        vm.stopPrank();
    }

    function testClaimStatusTracking() public {
        // Create signature for minting
        bytes memory signature = createSignature(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, 1, witnessPrivateKey
        );

        // Mint token through diamond
        vm.deal(tokenHolder, 1 ether);
        vm.startPrank(tokenHolder);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, signature, "", 1
        );

        // Approve diamond
        ERC721VaultImplementation(nftCollection).setApprovalForAll(address(diamond), true);

        // Check initial claim status
        assertFalse(EmblemVaultClaimFacet(address(diamond)).isTokenClaimed(nftCollection, 2));

        // Claim token
        EmblemVaultClaimFacet(address(diamond)).claim(nftCollection, 2);
        vm.stopPrank();

        // Verify claim status and claimer
        assertTrue(EmblemVaultClaimFacet(address(diamond)).isTokenClaimed(nftCollection, 2));
        assertEq(
            EmblemVaultClaimFacet(address(diamond)).getTokenClaimer(nftCollection, 2), tokenHolder
        );
    }

    function testERC1155ClaimWithSerialNumber() public {
        // Create ERC1155 collection through the factory
        vm.startPrank(owner);
        EmblemVaultCollectionFacet(address(diamond)).setCollectionFactory(address(factory));
        vm.stopPrank();

        vm.prank(address(diamond));
        address erc1155Collection = factory.createERC1155Collection("testuri.com/");

        // Create signature for minting with serial number
        uint256 serialNumber = 12_345;
        bytes memory serialData = abi.encode(serialNumber);
        bytes memory signature = createSignature(
            erc1155Collection, address(0), 1 ether, tokenHolder, 1, 100, 1, witnessPrivateKey
        );

        // Mint token through diamond
        vm.deal(tokenHolder, 1 ether);
        vm.startPrank(tokenHolder);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            erc1155Collection, address(0), 1 ether, tokenHolder, 1, 100, signature, serialData, 1
        );

        // Approve diamond to burn tokens
        IERC1155(erc1155Collection).setApprovalForAll(address(diamond), true);

        // Check initial claim status
        assertFalse(
            EmblemVaultClaimFacet(address(diamond)).isTokenClaimed(erc1155Collection, serialNumber)
        );

        // Claim token
        EmblemVaultClaimFacet(address(diamond)).claim(erc1155Collection, 1);
        vm.stopPrank();

        // Verify claim status and claimer
        assertTrue(
            EmblemVaultClaimFacet(address(diamond)).isTokenClaimed(erc1155Collection, serialNumber)
        );
        assertEq(
            EmblemVaultClaimFacet(address(diamond)).getTokenClaimer(erc1155Collection, serialNumber),
            tokenHolder
        );
    }

    function testClaimWithSignedPriceWhenDisabled() public {
        // Disable claiming
        vm.startPrank(owner);
        EmblemVaultClaimFacet(address(diamond)).setClaimingEnabled(false);
        vm.stopPrank();

        // Create signature for minting
        bytes memory signature = createSignature(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, 1, witnessPrivateKey
        );

        // Mint token through diamond
        vm.deal(tokenHolder, 1 ether);
        vm.startPrank(tokenHolder);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, signature, "", 1
        );

        // Approve and transfer to diamond
        ERC721VaultImplementation(nftCollection).approve(address(diamond), 2);
        ERC721VaultImplementation(nftCollection).transferFrom(tokenHolder, address(diamond), 2);
        vm.stopPrank();

        // Create claim signature
        bytes memory claimSignature =
            createSignature(nftCollection, address(0), 1 ether, user1, 2, 3, 1, witnessPrivateKey);

        // Should revert when trying to claim with signed price
        vm.startPrank(user1);
        vm.expectRevert(LibEmblemVaultStorage.ClaimingDisabled.selector);
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice{value: 1 ether}(
            nftCollection, 2, 3, address(0), 1 ether, claimSignature
        );
        vm.stopPrank();
    }

    function testClaimWithLockedVault() public {
        // Create signature for minting
        bytes memory signature = createSignature(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, 1, witnessPrivateKey
        );

        // Mint token through diamond
        vm.deal(tokenHolder, 2 ether); // Add extra ETH
        vm.startPrank(tokenHolder);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, signature, "", 1
        );

        // Approve diamond
        ERC721VaultImplementation(nftCollection).setApprovalForAll(address(diamond), true);
        vm.stopPrank();

        //deal eth to owner
        vm.deal(owner, 1 ether);

        // Lock the vault
        vm.startPrank(owner);
        EmblemVaultCoreFacet(address(diamond)).lockVault(nftCollection, 2);
        vm.stopPrank();

        // Create claim signature with lock acknowledgement
        bytes memory claimSignature = createSignatureWithLock(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 3, 1, witnessPrivateKey
        );

        // Verify balances before claim
        uint256 userBalanceBefore = tokenHolder.balance;

        // Claim with signed price
        vm.startPrank(tokenHolder);

        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice{value: 1 ether}(
            nftCollection, 2, 3, address(0), 1 ether, claimSignature
        );

        // Verify balances after claim
        uint256 userBalanceAfter = tokenHolder.balance;

        assertEq(userBalanceAfter, userBalanceBefore - 1 ether, "User balance incorrect");
        vm.stopPrank();

        // Verify claim status
        assertTrue(EmblemVaultClaimFacet(address(diamond)).isTokenClaimed(nftCollection, 2));
        assertEq(
            EmblemVaultClaimFacet(address(diamond)).getTokenClaimer(nftCollection, 2), tokenHolder
        );
    }

    function testBurnAddressWithClaim() public {
        address burnAddr = address(0x123);

        // Add burn address
        vm.startPrank(owner);
        EmblemVaultClaimFacet(address(diamond)).setBurnAddress(burnAddr, true);
        vm.stopPrank();

        // Create signature for minting
        bytes memory signature = createSignature(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, 1, witnessPrivateKey
        );

        // Mint token through diamond
        vm.deal(tokenHolder, 1 ether);
        vm.startPrank(tokenHolder);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection, address(0), 1 ether, tokenHolder, 2, 2, signature, "", 1
        );

        // Approve diamond
        ERC721VaultImplementation(nftCollection).setApprovalForAll(address(diamond), true);

        // Claim
        EmblemVaultClaimFacet(address(diamond)).claim(nftCollection, 2);
        vm.stopPrank();

        // Verify claim status
        assertTrue(EmblemVaultClaimFacet(address(diamond)).isTokenClaimed(nftCollection, 2));
        assertEq(
            EmblemVaultClaimFacet(address(diamond)).getTokenClaimer(nftCollection, 2), tokenHolder
        );
    }

    function testClaimHistory() public {
        // Create multiple tokens and claim them
        for (uint256 i = 2; i <= 4; i++) {
            // Create signature for minting
            bytes memory signature = createSignature(
                nftCollection, address(0), 1 ether, tokenHolder, i, i, 1, witnessPrivateKey
            );

            // Mint token through diamond
            vm.deal(tokenHolder, 1 ether);
            vm.startPrank(tokenHolder);
            EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
                nftCollection, address(0), 1 ether, tokenHolder, i, i, signature, "", 1
            );

            // Approve  diamond
            ERC721VaultImplementation(nftCollection).setApprovalForAll(address(diamond), true);

            // Claim token
            EmblemVaultClaimFacet(address(diamond)).claim(nftCollection, i);
            vm.stopPrank();
        }

        // Verify total claims
        assertEq(EmblemVaultClaimFacet(address(diamond)).getCollectionClaimCount(nftCollection), 3);

        // Verify each claim individually
        for (uint256 i = 2; i <= 4; i++) {
            assertTrue(EmblemVaultClaimFacet(address(diamond)).isTokenClaimed(nftCollection, i));
            assertEq(
                EmblemVaultClaimFacet(address(diamond)).getTokenClaimer(nftCollection, i),
                tokenHolder
            );
        }
    }
}
