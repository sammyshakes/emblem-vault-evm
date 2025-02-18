// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";
import "../src/interfaces/IIsSerialized.sol";
import "../src/interfaces/IVaultProxy.sol";

contract ERC1155VaultImplementationTest is Test {
    ERC1155VaultImplementation public implementation;
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    event SerialNumberAssigned(uint256 indexed tokenId, uint256 indexed serialNumber);
    event BatchSerialNumbersAssigned(uint256 indexed tokenId, uint256[] serialNumbers);

    ProxyAdmin public admin;
    address mockDiamond = address(0x1234567890123456789012345678901234567890);

    function setUp() public {
        // Deploy implementation
        ERC1155VaultImplementation impl = new ERC1155VaultImplementation();

        // Deploy proxy admin with test contract as owner
        admin = new ProxyAdmin(address(this));

        // Deploy proxy with implementation
        bytes memory initData = abi.encodeWithSelector(
            ERC1155VaultImplementation.initialize.selector, "https://api.test.com/", mockDiamond
        );

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(impl), address(admin), initData);

        // Set up the implementation interface
        implementation = ERC1155VaultImplementation(address(proxy));

        // Set up prank for Diamond calls
        vm.startPrank(mockDiamond);
    }

    function testInitialState() public view {
        assertTrue(implementation.isSerialized(), "Should be serialized");
        assertEq(implementation.owner(), address(this), "Should be owned by test contract");
        assertTrue(
            implementation.supportsInterface(type(IIsSerialized).interfaceId),
            "Should support IIsSerialized"
        );
        assertTrue(
            implementation.supportsInterface(type(IVaultProxy).interfaceId),
            "Should support IVaultProxy"
        );
    }

    // ------------------------------------------------------------------------
    // EXTERNAL-SERIAL TESTS
    // ------------------------------------------------------------------------

    function testExternalSerialNumberMint() public {
        // Prepare external serial numbers
        uint256[] memory serialNumbers = new uint256[](3);
        serialNumbers[0] = 100;
        serialNumbers[1] = 200;
        serialNumbers[2] = 300;

        // Mint with external serials
        implementation.mintWithSerial(user1, 1, 3, serialNumbers);

        // Verify
        assertEq(implementation.getSerial(1, 0), 100);
        assertEq(implementation.getSerial(1, 1), 200);
        assertEq(implementation.getSerial(1, 2), 300);

        assertEq(implementation.getOwnerOfSerial(100), user1);
        assertEq(implementation.getOwnerOfSerial(200), user1);
        assertEq(implementation.getOwnerOfSerial(300), user1);

        assertEq(implementation.getTokenIdForSerialNumber(100), 1);
        assertEq(implementation.getTokenIdForSerialNumber(200), 1);
        assertEq(implementation.getTokenIdForSerialNumber(300), 1);

        assertEq(implementation.getFirstSerialByOwner(user1, 1), 100);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 1), 200);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 2), 300);
    }

    // ------------------------------------------------------------------------
    // TESTING TRANSFERS WITH EXTERNAL SERIALS
    // We remove toggling to auto mode, so let's supply external serials manually.
    // ------------------------------------------------------------------------

    function testSerialNumberTransfer() public {
        // CHANGED: Instead of toggling to auto, we do external mint
        uint256[] memory serialNumbers = new uint256[](3);
        serialNumbers[0] = 11;
        serialNumbers[1] = 12;
        serialNumbers[2] = 13;

        // Mint 3 tokens with external serials
        implementation.mintWithSerial(user1, 1, 3, serialNumbers);

        // Transfer 2 tokens from user1 to user2
        vm.startPrank(user1);
        implementation.safeTransferFrom(user1, user2, 1, 2, "");
        vm.stopPrank();

        // user1 should have 1 token left
        assertEq(implementation.balanceOf(user1, 1), 1);

        // The first 2 tokens minted were indexes 0 and 1 => serialNumbers 11 and 12
        // But recall our "pop from end" transfer logic means the last minted gets transferred first
        // Actually, let's just read who owns each of the 3 minted serials:
        //   Index in _ownerTokenSerials => [0..2]
        //   The "end" is index=2 => serial=13, that goes first, then index=1 => serial=12, etc.

        // Let's just confirm user1 has exactly 1 of [11,12,13], and user2 has the other 2.
        // user1's first serial:
        uint256 user1Serial = implementation.getFirstSerialByOwner(user1, 1);
        assertEq(implementation.getOwnerOfSerial(user1Serial), user1);

        // user2 should have 2 tokens
        assertEq(implementation.balanceOf(user2, 1), 2);

        // Let's read them from user2
        uint256 user2Serial1 = implementation.getFirstSerialByOwner(user2, 1);
        uint256 user2Serial2 = implementation.getSerialByOwnerAtIndex(user2, 1, 1);
        assertEq(implementation.getOwnerOfSerial(user2Serial1), user2);
        assertEq(implementation.getOwnerOfSerial(user2Serial2), user2);
    }

    function testSerialNumberBurn() public {
        // CHANGED: external mint of 3 tokens
        uint256[] memory serialNumbers = new uint256[](3);
        serialNumbers[0] = 1;
        serialNumbers[1] = 2;
        serialNumbers[2] = 3;

        implementation.mintWithSerial(user1, 1, 3, serialNumbers);

        // The *last* 2 minted are #3 and #2 (pop from end).
        // Burn 2 tokens
        vm.startPrank(user1);
        implementation.burn(user1, 1, 2);
        vm.stopPrank();

        // Check that #2 and #3 are indeed burned => new owner = address(0)
        assertEq(implementation.getOwnerOfSerial(2), address(0));
        assertEq(implementation.getOwnerOfSerial(3), address(0));

        // The only remaining serial is #1
        assertEq(implementation.balanceOf(user1, 1), 1);
        uint256 remainingSerial = implementation.getFirstSerialByOwner(user1, 1);
        assertEq(remainingSerial, 1);
        assertEq(implementation.getOwnerOfSerial(remainingSerial), user1);
    }

    // ------------------------------------------------------------------------
    // DUPLICATE, ZERO, MISMATCH, REUSE, ETC => unchanged
    // because they were already testing external serial reverts.
    // ------------------------------------------------------------------------

    function testRevertDuplicateExternalSerial() public {
        // ...
        uint256[] memory serialNumbers = new uint256[](3);
        serialNumbers[0] = 100;
        serialNumbers[1] = 100; // Duplicate
        serialNumbers[2] = 300;

        vm.expectRevert(abi.encodeWithSignature("SerialNumberAlreadyUsed()"));
        implementation.mintWithSerial(user1, 1, 3, serialNumbers);
    }

    function testRevertZeroSerialNumber() public {
        // ...
        uint256[] memory serialNumbers = new uint256[](3);
        serialNumbers[0] = 100;
        serialNumbers[1] = 0; // Zero
        serialNumbers[2] = 300;

        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumber()"));
        implementation.mintWithSerial(user1, 1, 3, serialNumbers);
    }

    function testRevertMismatchedSerialNumbers() public {
        // ...
        uint256[] memory serialNumbers = new uint256[](2);
        serialNumbers[0] = 100;
        serialNumbers[1] = 200;

        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumbersCount()"));
        implementation.mintWithSerial(user1, 1, 3, serialNumbers);
    }

    function testRevertZeroAmountMint() public {
        uint256[] memory serialNumbers = new uint256[](1);
        serialNumbers[0] = 100;

        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        implementation.mintWithSerial(user1, 1, 0, serialNumbers);
    }

    function testSingleSerialMint() public {
        // Test single serial number
        uint256[] memory serialNumbers = new uint256[](1);
        serialNumbers[0] = 100;
        implementation.mintWithSerial(user1, 1, 1, serialNumbers);
        assertEq(implementation.getFirstSerialByOwner(user1, 1), 100);

        // Test invalid array length
        uint256[] memory invalidSerials = new uint256[](2);
        invalidSerials[0] = 200;
        invalidSerials[1] = 300;
        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumbersCount()"));
        implementation.mintWithSerial(user2, 2, 1, invalidSerials);
    }

    function testRevertReuseSerialAcrossTokens() public {
        // ...
        uint256[] memory serialNumbers1 = new uint256[](1);
        serialNumbers1[0] = 100;
        implementation.mintWithSerial(user1, 1, 1, serialNumbers1);

        uint256[] memory serialNumbers2 = new uint256[](1);
        serialNumbers2[0] = 100; // same
        vm.expectRevert(abi.encodeWithSignature("SerialNumberAlreadyUsed()"));
        implementation.mintWithSerial(user1, 2, 1, serialNumbers2);
    }

    // ------------------------------------------------------------------------
    // BATCH MINT EXTERNAL
    // ------------------------------------------------------------------------

    function testBatchMintWithExternalSerialNumbers() public {
        // ...
        uint256[] memory serialNumbers1 = new uint256[](2);
        serialNumbers1[0] = 100;
        serialNumbers1[1] = 200;

        uint256[] memory serialNumbers2 = new uint256[](3);
        serialNumbers2[0] = 300;
        serialNumbers2[1] = 400;
        serialNumbers2[2] = 500;

        uint256[][] memory serialData = new uint256[][](2);
        serialData[0] = serialNumbers1;
        serialData[1] = serialNumbers2;

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 3;

        // ...
        implementation.mintBatch(user1, ids, amounts, serialData);

        // Check
        assertEq(implementation.getFirstSerialByOwner(user1, 1), 100);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 1), 200);

        assertEq(implementation.getFirstSerialByOwner(user1, 2), 300);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 1), 400);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 2), 500);
    }

    // ------------------------------------------------------------------------
    // BATCH TRANSFERS
    // If you truly never use auto, let's just do external mint
    // and then safeBatchTransferFrom.
    // ------------------------------------------------------------------------

    function testBatchTransferSerialNumbers() public {
        // CHANGED: We'll mint externally
        uint256[] memory serials1 = new uint256[](3);
        serials1[0] = 10;
        serials1[1] = 11;
        serials1[2] = 12;

        uint256[] memory serials2 = new uint256[](2);
        serials2[0] = 20;
        serials2[1] = 21;

        uint256[][] memory allSerials = new uint256[][](2);
        allSerials[0] = serials1;
        allSerials[1] = serials2;

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory mintAmounts = new uint256[](2);
        mintAmounts[0] = 3;
        mintAmounts[1] = 2;

        implementation.mintBatch(user1, ids, mintAmounts, allSerials);

        // Prepare batch transfer
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 2; // Transfer 2 from tokenId=1
        transferAmounts[1] = 1; // Transfer 1 from tokenId=2

        vm.startPrank(user1);
        implementation.safeBatchTransferFrom(user1, user2, ids, transferAmounts, "");
        vm.stopPrank();

        // Check balances after transfer
        assertEq(implementation.balanceOf(user1, 1), 1, "user1 should have 1 token of id 1");
        assertEq(implementation.balanceOf(user1, 2), 1, "user1 should have 1 token of id 2");
        assertEq(implementation.balanceOf(user2, 1), 2, "user2 should have 2 tokens of id 1");
        assertEq(implementation.balanceOf(user2, 2), 1, "user2 should have 1 token of id 2");

        // Verify ownership of user2 tokens
        uint256 user2Serial1 = implementation.getFirstSerialByOwner(user2, 1);
        uint256 user2Serial2 = implementation.getSerialByOwnerAtIndex(user2, 1, 1);
        uint256 user2Serial3 = implementation.getFirstSerialByOwner(user2, 2);

        assertEq(implementation.getOwnerOfSerial(user2Serial1), user2);
        assertEq(implementation.getOwnerOfSerial(user2Serial2), user2);
        assertEq(implementation.getOwnerOfSerial(user2Serial3), user2);
    }

    // ------------------------------------------------------------------------
    // MISC REMAINS THE SAME
    // ------------------------------------------------------------------------

    function testComplexTransferScenario() public {
        // Mint tokens with external serial numbers to user1
        uint256[] memory serialNumbers1 = new uint256[](3);
        serialNumbers1[0] = 100;
        serialNumbers1[1] = 200;
        serialNumbers1[2] = 300;
        implementation.mintWithSerial(user1, 1, 3, serialNumbers1);

        // Transfer some tokens to user2
        vm.startPrank(user1);
        implementation.safeTransferFrom(user1, user2, 1, 2, "");
        vm.stopPrank();

        // Mint more tokens with new serial numbers to user1
        uint256[] memory serialNumbers2 = new uint256[](2);
        serialNumbers2[0] = 400;
        serialNumbers2[1] = 500;

        // Restore Diamond prank context for minting
        vm.startPrank(mockDiamond);
        implementation.mintWithSerial(user1, 1, 2, serialNumbers2);
        vm.stopPrank();

        // Transfer one token from user2 back to user1
        vm.startPrank(user2);
        implementation.safeTransferFrom(user2, user1, 1, 1, "");
        vm.stopPrank();

        // user1 now has 4 total
        assertEq(implementation.balanceOf(user1, 1), 4);
        assertEq(implementation.balanceOf(user2, 1), 1);

        // Spot-check ownership
        // We won't guess exact serial # distribution.
        // Let's just confirm the correct balances + owners.
        for (uint256 i = 0; i < implementation.balanceOf(user1, 1); i++) {
            uint256 s = implementation.getSerialByOwnerAtIndex(user1, 1, i);
            assertEq(implementation.getOwnerOfSerial(s), user1);
        }
        uint256 user2Serial = implementation.getFirstSerialByOwner(user2, 1);
        assertEq(implementation.getOwnerOfSerial(user2Serial), user2);
    }

    function testRevertInvalidBatchSerialData() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 3;

        // Wrong number of serial arrays
        uint256[][] memory serials = new uint256[][](1);
        serials[0] = new uint256[](2);
        serials[0][0] = 100;
        serials[0][1] = 200;

        vm.expectRevert(abi.encodeWithSignature("InvalidSerialArraysLength()"));
        implementation.mintBatch(user1, ids, amounts, serials);

        // Wrong number of serial numbers in array
        serials = new uint256[][](2);
        serials[0] = new uint256[](2);
        serials[0][0] = 100;
        serials[0][1] = 200;
        serials[1] = new uint256[](1);
        serials[1][0] = 300;

        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumbersCount()"));
        implementation.mintBatch(user1, ids, amounts, serials);
    }

    function testComplexBatchMintWithExternalSerials() public {
        // ...
        uint256[] memory ids1 = new uint256[](2);
        ids1[0] = 1;
        ids1[1] = 2;

        uint256[] memory amounts1 = new uint256[](2);
        amounts1[0] = 2;
        amounts1[1] = 1;

        // Prepare serial numbers
        uint256[] memory serialNumbers1 = new uint256[](2);
        serialNumbers1[0] = 100;
        serialNumbers1[1] = 200;
        uint256[] memory serialNumbers2 = new uint256[](1);
        serialNumbers2[0] = 300;

        uint256[][] memory serialData1 = new uint256[][](2);
        serialData1[0] = serialNumbers1;
        serialData1[1] = serialNumbers2;

        implementation.mintBatch(user1, ids1, amounts1, serialData1);

        // Second batch
        uint256[] memory ids2 = new uint256[](2);
        ids2[0] = 2;
        ids2[1] = 3;

        uint256[] memory amounts2 = new uint256[](2);
        amounts2[0] = 2;
        amounts2[1] = 3;

        uint256[] memory serialNumbers3 = new uint256[](2);
        serialNumbers3[0] = 400;
        serialNumbers3[1] = 500;

        uint256[] memory serialNumbers4 = new uint256[](3);
        serialNumbers4[0] = 600;
        serialNumbers4[1] = 700;
        serialNumbers4[2] = 800;

        uint256[][] memory serialData2 = new uint256[][](2);
        serialData2[0] = serialNumbers3;
        serialData2[1] = serialNumbers4;

        implementation.mintBatch(user1, ids2, amounts2, serialData2);

        // Check balances
        assertEq(implementation.balanceOf(user1, 1), 2, "user1 should have 2 tokens of id 1");
        assertEq(implementation.balanceOf(user1, 2), 3, "user1 should have 3 tokens of id 2");
        assertEq(implementation.balanceOf(user1, 3), 3, "user1 should have 3 tokens of id 3");

        // Check serial numbers for token id 1
        assertEq(implementation.getFirstSerialByOwner(user1, 1), 100);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 1), 200);

        // Check serial numbers for token id 2
        // The first minted was 1 => [300], second minted was 2 => [400,500] appended
        // So 2's final array might be [300, 400, 500], in some order
        // We'll just do direct checks:
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 0), 300);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 1), 400);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 2), 500);

        assertEq(implementation.balanceOf(user1, 3), 3);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 3, 0), 600);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 3, 1), 700);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 3, 2), 800);
    }

    function testRevertInvalidSerialQueries() public {
        // Instead of toggling, let's just do a single external mint of 1 token:
        uint256[] memory serialNumbers = new uint256[](1);
        serialNumbers[0] = 999;

        implementation.mintWithSerial(user1, 1, 1, serialNumbers);

        // Try to get non-existent index
        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumber()"));
        implementation.getSerial(1, 1); // we only minted index=0

        // Try to get tokenId=2
        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumber()"));
        implementation.getSerial(2, 0);

        // Try to get first serial for tokenId=2
        vm.expectRevert(abi.encodeWithSignature("NoSerialsFound()"));
        implementation.getFirstSerialByOwner(user1, 2);

        // Try to get serial at invalid index
        vm.expectRevert(abi.encodeWithSignature("InvalidIndex()"));
        implementation.getSerialByOwnerAtIndex(user1, 1, 1);
    }

    receive() external payable {}
}
