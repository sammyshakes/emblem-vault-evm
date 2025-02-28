// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DiamondVault.t.sol";

contract SerialNumberOverwriteTest is DiamondVaultTest {
    address erc1155Collection;

    function setUp() public override {
        // Call parent setUp
        super.setUp();

        // Create an ERC1155 collection through Diamond
        vm.prank(address(diamond));
        erc1155Collection = factory.createERC1155Collection("https://api.test.com/");

        // Enable unvaulting
        vm.prank(owner);
        EmblemVaultUnvaultFacet(address(diamond)).setUnvaultingEnabled(true);
    }

    function testSerialNumberOverwriteScenario() public {
        // Prepare serial numbers for User1
        uint256[] memory serials1 = new uint256[](2);
        serials1[0] = 100;
        serials1[1] = 200;

        // Create signature for User1's mint
        bytes memory sig1 = createSignature(
            erc1155Collection,
            address(0), // ETH payment
            0.1 ether,
            user1,
            1, // tokenId
            3, // nonce
            2, // amount
            witnessPrivateKey,
            serials1,
            0 // timestamp
        );

        // User1 mints tokenId=1 with serials [100,200]
        vm.prank(user1);
        // Use timestamp 0 for signature verification in tests
        uint256 timestamp = 0;
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 0.1 ether}(
            erc1155Collection,
            address(0),
            0.1 ether,
            user1,
            1, // tokenId
            3, // nonce
            sig1,
            serials1,
            2, // amount
            timestamp
        );

        // Verify User1's initial state
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getSerialByOwnerAtIndex(user1, 1, 0),
            100,
            "First serial should be 100"
        );
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getSerialByOwnerAtIndex(user1, 1, 1),
            200,
            "Second serial should be 200"
        );

        // Prepare serial numbers for User2
        uint256[] memory serials2 = new uint256[](2);
        serials2[0] = 300;
        serials2[1] = 400;

        // Create signature for User2's mint
        bytes memory sig2 = createSignature(
            erc1155Collection,
            address(0), // ETH payment
            0.1 ether,
            user2,
            1, // same tokenId
            4, // nonce
            2, // amount
            witnessPrivateKey,
            serials2,
            0 // timestamp
        );

        // User2 mints same tokenId=1 with different serials [300,400]
        vm.prank(user2);
        // Use timestamp 0 for signature verification in tests
        uint256 timestamp2 = 0;
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 0.1 ether}(
            erc1155Collection,
            address(0),
            0.1 ether,
            user2,
            1, // tokenId
            4, // nonce
            sig2,
            serials2,
            2, // amount
            timestamp2
        );

        // Verify User1's serials are still intact
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getSerialByOwnerAtIndex(user1, 1, 0),
            100,
            "User1's first serial should still be 100"
        );
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getSerialByOwnerAtIndex(user1, 1, 1),
            200,
            "User1's second serial should still be 200"
        );

        // Verify User2's serials are properly stored
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getSerialByOwnerAtIndex(user2, 1, 0),
            300,
            "User2's first serial should be at index 0"
        );
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getSerialByOwnerAtIndex(user2, 1, 1),
            400,
            "User2's second serial should be at index 1"
        );

        // Verify ownership through the implementation
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getOwnerOfSerial(100),
            user1,
            "User1 should own 100"
        );
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getOwnerOfSerial(200),
            user1,
            "User1 should own 200"
        );
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getOwnerOfSerial(300),
            user2,
            "User2 should own 300"
        );
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getOwnerOfSerial(400),
            user2,
            "User2 should own 400"
        );
    }

    function testBurnAndRemintScenario() public {
        // First mint to User1
        uint256[] memory serials1 = new uint256[](2);
        serials1[0] = 100;
        serials1[1] = 200;

        bytes memory sig1 = createSignature(
            erc1155Collection, address(0), 0.1 ether, user1, 1, 3, 2, witnessPrivateKey, serials1, 0
        );

        vm.prank(user1);
        // Use timestamp 0 for signature verification in tests
        uint256 timestamp = 0;
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 0.1 ether}(
            erc1155Collection, address(0), 0.1 ether, user1, 1, 3, sig1, serials1, 2, timestamp
        );

        // User1 approves diamond for unvaulting
        vm.prank(user1);
        ERC1155VaultImplementation(erc1155Collection).setApprovalForAll(address(diamond), true);

        // User1 unvaults one token
        vm.prank(user1);
        EmblemVaultUnvaultFacet(address(diamond)).unvault(erc1155Collection, 1);

        // Verify first serial is still owned but second is unvaulted (LIFO)
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getOwnerOfSerial(100),
            user1,
            "User1 should still own serial 100"
        );

        // Check that serial 200 is unvaulted
        assertTrue(
            EmblemVaultUnvaultFacet(address(diamond)).isTokenUnvaulted(erc1155Collection, 200),
            "Serial 200 should be unvaulted"
        );
        assertEq(
            EmblemVaultUnvaultFacet(address(diamond)).getTokenUnvaulter(erc1155Collection, 200),
            user1,
            "User1 should be the unvaulter of serial 200"
        );

        // User1 unvaults second token
        vm.prank(user1);
        EmblemVaultUnvaultFacet(address(diamond)).unvault(erc1155Collection, 1);

        // Verify both serials are unvaulted
        assertTrue(
            EmblemVaultUnvaultFacet(address(diamond)).isTokenUnvaulted(erc1155Collection, 100),
            "Serial 100 should be unvaulted"
        );
        assertTrue(
            EmblemVaultUnvaultFacet(address(diamond)).isTokenUnvaulted(erc1155Collection, 200),
            "Serial 200 should be unvaulted"
        );
        assertEq(
            EmblemVaultUnvaultFacet(address(diamond)).getTokenUnvaulter(erc1155Collection, 100),
            user1,
            "User1 should be the unvaulter of serial 100"
        );
        assertEq(
            EmblemVaultUnvaultFacet(address(diamond)).getTokenUnvaulter(erc1155Collection, 200),
            user1,
            "User1 should be the unvaulter of serial 200"
        );

        // User2 mints same tokenId
        uint256[] memory serials2 = new uint256[](2);
        serials2[0] = 300;
        serials2[1] = 400;

        bytes memory sig2 = createSignature(
            erc1155Collection, address(0), 0.1 ether, user2, 1, 4, 2, witnessPrivateKey, serials2, 0
        );

        vm.prank(user2);
        // Use timestamp 0 for signature verification in tests
        uint256 timestamp2 = 0;
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 0.1 ether}(
            erc1155Collection, address(0), 0.1 ether, user2, 1, 4, sig2, serials2, 2, timestamp2
        );

        // Verify new serials are properly stored
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getOwnerOfSerial(300),
            user2,
            "User2 should own 300"
        );
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).getOwnerOfSerial(400),
            user2,
            "User2 should own 400"
        );
    }

    function testTransferScenario() public {
        // First mint to User1
        uint256[] memory serials1 = new uint256[](2);
        serials1[0] = 100;
        serials1[1] = 200;

        bytes memory sig1 = createSignature(
            erc1155Collection, address(0), 0.1 ether, user1, 1, 3, 2, witnessPrivateKey, serials1, 0
        );

        vm.prank(user1);
        // Use timestamp 0 for signature verification in tests
        uint256 timestamp = 0;
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 0.1 ether}(
            erc1155Collection, address(0), 0.1 ether, user1, 1, 3, sig1, serials1, 2, timestamp
        );

        // User1 transfers one token to User2
        vm.prank(user1);
        ERC1155VaultImplementation(erc1155Collection).safeTransferFrom(user1, user2, 1, 1, "");

        // User2 mints additional tokens of same ID
        uint256[] memory serials2 = new uint256[](2);
        serials2[0] = 300;
        serials2[1] = 400;

        bytes memory sig2 = createSignature(
            erc1155Collection, address(0), 0.1 ether, user2, 1, 4, 2, witnessPrivateKey, serials2, 0
        );

        vm.prank(user2);
        // Use timestamp 0 for signature verification in tests
        uint256 timestamp2 = 0;
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 0.1 ether}(
            erc1155Collection, address(0), 0.1 ether, user2, 1, 4, sig2, serials2, 2, timestamp2
        );

        // Verify balances
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).balanceOf(user1, 1),
            1,
            "User1 should have 1 token"
        );
        assertEq(
            ERC1155VaultImplementation(erc1155Collection).balanceOf(user2, 1),
            3,
            "User2 should have 3 tokens"
        );

        // Verify serial ownership after transfer and new mint
        uint256 user1Serial =
            ERC1155VaultImplementation(erc1155Collection).getFirstSerialByOwner(user1, 1);
        assertTrue(
            user1Serial == 100 || user1Serial == 200,
            "User1 should still own one of their original serials"
        );

        // Get all of User2's serials
        uint256[] memory user2Serials = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            user2Serials[i] =
                ERC1155VaultImplementation(erc1155Collection).getSerialByOwnerAtIndex(user2, 1, i);
        }

        // Verify User2 has the transferred serial and their new ones
        bool hasTransferredSerial = false;
        bool has300 = false;
        bool has400 = false;

        for (uint256 i = 0; i < 3; i++) {
            if (user2Serials[i] == 100 || user2Serials[i] == 200) hasTransferredSerial = true;
            if (user2Serials[i] == 300) has300 = true;
            if (user2Serials[i] == 400) has400 = true;
        }

        assertTrue(hasTransferredSerial, "User2 should have one of User1's original serials");
        assertTrue(has300, "User2 should have serial 300");
        assertTrue(has400, "User2 should have serial 400");
    }
}
