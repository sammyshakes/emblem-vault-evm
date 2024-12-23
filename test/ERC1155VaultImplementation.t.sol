// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
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

    function setUp() public {
        // Deploy implementation
        ERC1155VaultImplementation impl = new ERC1155VaultImplementation();

        // Deploy proxy admin with test contract as owner
        admin = new ProxyAdmin(address(this));

        // Deploy proxy with implementation
        bytes memory initData = abi.encodeWithSelector(
            ERC1155VaultImplementation.initialize.selector, "https://api.test.com/"
        );

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(impl), address(admin), initData);

        // Set up the implementation interface
        implementation = ERC1155VaultImplementation(address(proxy));
    }

    function testInitialState() public view {
        assertTrue(implementation.isOverloadSerial(), "Should start in external serial mode");
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

    function testAutoSerialNumberMint() public {
        // Test minting with automatic serial numbers
        implementation.toggleOverloadSerial(); // Switch to automatic mode

        vm.expectEmit(true, true, true, true);
        uint256[] memory expectedSerials = new uint256[](3);
        expectedSerials[0] = 1;
        expectedSerials[1] = 2;
        expectedSerials[2] = 3;
        emit BatchSerialNumbersAssigned(1, expectedSerials);

        implementation.mint(user1, 1, 3, "");

        // Verify serial numbers were assigned sequentially
        assertEq(implementation.getSerial(1, 0), 1);
        assertEq(implementation.getSerial(1, 1), 2);
        assertEq(implementation.getSerial(1, 2), 3);

        // Verify ownership tracking
        assertEq(implementation.getOwnerOfSerial(1), user1);
        assertEq(implementation.getOwnerOfSerial(2), user1);
        assertEq(implementation.getOwnerOfSerial(3), user1);

        // Verify token ID mapping
        assertEq(implementation.getTokenIdForSerialNumber(1), 1);
        assertEq(implementation.getTokenIdForSerialNumber(2), 1);
        assertEq(implementation.getTokenIdForSerialNumber(3), 1);

        // Verify owner's serial numbers
        assertEq(implementation.getFirstSerialByOwner(user1, 1), 1);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 1), 2);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 2), 3);
    }

    function testExternalSerialNumberMint() public {
        // Prepare external serial numbers
        uint256[] memory serialNumbers = new uint256[](3);
        serialNumbers[0] = 100;
        serialNumbers[1] = 200;
        serialNumbers[2] = 300;
        bytes memory serialNumberData = abi.encode(serialNumbers);

        // Test minting with external serial numbers
        implementation.mintWithSerial(user1, 1, 3, serialNumberData);

        // Verify provided serial numbers were used
        assertEq(implementation.getSerial(1, 0), 100);
        assertEq(implementation.getSerial(1, 1), 200);
        assertEq(implementation.getSerial(1, 2), 300);

        // Verify ownership tracking
        assertEq(implementation.getOwnerOfSerial(100), user1);
        assertEq(implementation.getOwnerOfSerial(200), user1);
        assertEq(implementation.getOwnerOfSerial(300), user1);

        // Verify token ID mapping
        assertEq(implementation.getTokenIdForSerialNumber(100), 1);
        assertEq(implementation.getTokenIdForSerialNumber(200), 1);
        assertEq(implementation.getTokenIdForSerialNumber(300), 1);

        // Verify owner's serial numbers
        assertEq(implementation.getFirstSerialByOwner(user1, 1), 100);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 1), 200);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 2), 300);
    }

    function testSerialNumberTransfer() public {
        // Mint token with serial numbers
        implementation.toggleOverloadSerial(); // Switch to automatic mode
        implementation.mint(user1, 1, 3, "");

        // Transfer 2 tokens from user1 to user2
        vm.startPrank(user1);
        implementation.safeTransferFrom(user1, user2, 1, 2, "");
        vm.stopPrank();

        // Verify user1's remaining serial number
        assertEq(implementation.balanceOf(user1, 1), 1);
        uint256 user1Serial = implementation.getFirstSerialByOwner(user1, 1);
        assertEq(implementation.getOwnerOfSerial(user1Serial), user1);

        // Verify user2's new serial numbers
        assertEq(implementation.balanceOf(user2, 1), 2);
        uint256 user2Serial1 = implementation.getFirstSerialByOwner(user2, 1);
        uint256 user2Serial2 = implementation.getSerialByOwnerAtIndex(user2, 1, 1);
        assertEq(implementation.getOwnerOfSerial(user2Serial1), user2);
        assertEq(implementation.getOwnerOfSerial(user2Serial2), user2);
    }

    function testSerialNumberBurn() public {
        // mint
        implementation.toggleOverloadSerial(); // Switch to automatic mode
        implementation.mint(user1, 1, 3, "");

        // The *last* 2 minted are #3 and #2
        uint256 serial3 = implementation.getSerialByOwnerAtIndex(user1, 1, 2);
        uint256 serial2 = implementation.getSerialByOwnerAtIndex(user1, 1, 1);

        // Burn 2 tokens
        vm.startPrank(user1);
        implementation.burn(user1, 1, 2);
        vm.stopPrank();

        // Check that #2 and #3 are indeed burned
        assertEq(implementation.getOwnerOfSerial(serial2), address(0));
        assertEq(implementation.getOwnerOfSerial(serial3), address(0));

        // The only remaining serial is #1
        assertEq(implementation.balanceOf(user1, 1), 1);
        uint256 remainingSerial = implementation.getFirstSerialByOwner(user1, 1);
        assertEq(remainingSerial, 1);
        assertEq(implementation.getOwnerOfSerial(remainingSerial), user1);
    }

    function testRevertDuplicateExternalSerial() public {
        // Prepare external serial numbers with a duplicate
        uint256[] memory serialNumbers = new uint256[](3);
        serialNumbers[0] = 100;
        serialNumbers[1] = 100; // Duplicate
        serialNumbers[2] = 300;
        bytes memory serialNumberData = abi.encode(serialNumbers);

        // Attempt to mint with duplicate serial numbers
        vm.expectRevert(abi.encodeWithSignature("SerialNumberDuplicate()"));
        implementation.mintWithSerial(user1, 1, 3, serialNumberData);
    }

    function testRevertInvalidSerialMode() public {
        // Attempt to use regular mint in external serial mode
        vm.expectRevert(abi.encodeWithSignature("UseExternalSerialNumbers()"));
        implementation.mint(user1, 1, 3, "");

        // Switch to automatic mode
        implementation.toggleOverloadSerial();

        // Attempt to use mintWithSerial in automatic mode
        uint256[] memory serialNumbers = new uint256[](1);
        serialNumbers[0] = 100;
        bytes memory serialNumberData = abi.encode(serialNumbers);

        vm.expectRevert(abi.encodeWithSignature("ExternalSerialNumbersDisabled()"));
        implementation.mintWithSerial(user1, 1, 1, serialNumberData);
    }

    function testBatchMintWithExternalSerialNumbers() public {
        // Prepare external serial numbers for two token IDs
        uint256[] memory serialNumbers1 = new uint256[](2);
        serialNumbers1[0] = 100;
        serialNumbers1[1] = 200;

        uint256[] memory serialNumbers2 = new uint256[](3);
        serialNumbers2[0] = 300;
        serialNumbers2[1] = 400;
        serialNumbers2[2] = 500;

        bytes[] memory serialData = new bytes[](2);
        serialData[0] = abi.encode(serialNumbers1);
        serialData[1] = abi.encode(serialNumbers2);

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 3;

        // Encode serial data arrays properly for batch minting
        bytes memory batchData = abi.encode(serialData);
        implementation.mintBatch(user1, ids, amounts, batchData);

        // Verify serial numbers for first token ID
        assertEq(implementation.getFirstSerialByOwner(user1, 1), 100);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 1), 200);

        // Verify serial numbers for second token ID
        assertEq(implementation.getFirstSerialByOwner(user1, 2), 300);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 1), 400);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 2), 500);
    }

    function testBatchMintWithAutomaticSerialNumbers() public {
        // Test batch minting with automatic serial numbers
        implementation.toggleOverloadSerial(); // Switch to automatic mode

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 3;

        // Expect batch events
        vm.expectEmit(true, true, true, true);
        uint256[] memory expectedSerials1 = new uint256[](2);
        expectedSerials1[0] = 1;
        expectedSerials1[1] = 2;
        emit BatchSerialNumbersAssigned(1, expectedSerials1);

        vm.expectEmit(true, true, true, true);
        uint256[] memory expectedSerials2 = new uint256[](3);
        expectedSerials2[0] = 3;
        expectedSerials2[1] = 4;
        expectedSerials2[2] = 5;
        emit BatchSerialNumbersAssigned(2, expectedSerials2);

        implementation.mintBatch(user1, ids, amounts, "");

        // Verify serial numbers for first token ID
        assertEq(implementation.getFirstSerialByOwner(user1, 1), 1);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 1), 2);

        // Verify serial numbers for second token ID
        assertEq(implementation.getFirstSerialByOwner(user1, 2), 3);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 1), 4);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 2), 5);
    }

    function testBatchTransferSerialNumbers() public {
        // Mint tokens with serial numbers
        implementation.toggleOverloadSerial(); // Switch to automatic mode

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory mintAmounts = new uint256[](2);
        mintAmounts[0] = 3;
        mintAmounts[1] = 2;

        implementation.mintBatch(user1, ids, mintAmounts, "");

        // Prepare batch transfer
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 2;
        transferAmounts[1] = 1;

        // Transfer tokens
        vm.startPrank(user1);
        implementation.safeBatchTransferFrom(user1, user2, ids, transferAmounts, "");
        vm.stopPrank();

        // Verify serial numbers for first token ID
        assertEq(implementation.balanceOf(user1, 1), 1);
        assertEq(implementation.balanceOf(user2, 1), 2);

        // Verify serial numbers for second token ID
        assertEq(implementation.balanceOf(user1, 2), 1);
        assertEq(implementation.balanceOf(user2, 2), 1);

        // Verify ownership of transferred serials
        uint256 user2Serial1 = implementation.getFirstSerialByOwner(user2, 1);
        uint256 user2Serial2 = implementation.getSerialByOwnerAtIndex(user2, 1, 1);
        uint256 user2Serial3 = implementation.getFirstSerialByOwner(user2, 2);

        assertEq(implementation.getOwnerOfSerial(user2Serial1), user2);
        assertEq(implementation.getOwnerOfSerial(user2Serial2), user2);
        assertEq(implementation.getOwnerOfSerial(user2Serial3), user2);
    }

    function testRevertZeroSerialNumber() public {
        // Prepare external serial numbers with a zero value
        uint256[] memory serialNumbers = new uint256[](3);
        serialNumbers[0] = 100;
        serialNumbers[1] = 0; // Zero serial number
        serialNumbers[2] = 300;
        bytes memory serialNumberData = abi.encode(serialNumbers);

        // Attempt to mint with zero serial number
        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumber()"));
        implementation.mintWithSerial(user1, 1, 3, serialNumberData);
    }

    function testRevertMismatchedSerialNumbers() public {
        // Prepare external serial numbers with wrong amount
        uint256[] memory serialNumbers = new uint256[](2); // Only 2 numbers for 3 tokens
        serialNumbers[0] = 100;
        serialNumbers[1] = 200;
        bytes memory serialNumberData = abi.encode(serialNumbers);

        // Attempt to mint with mismatched amounts
        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumbersCount()"));
        implementation.mintWithSerial(user1, 1, 3, serialNumberData);
    }

    function testRevertReuseSerialAcrossTokens() public {
        // Mint first token with serial number 100
        uint256[] memory serialNumbers1 = new uint256[](1);
        serialNumbers1[0] = 100;
        bytes memory serialNumberData1 = abi.encode(serialNumbers1);
        implementation.mintWithSerial(user1, 1, 1, serialNumberData1);

        // Attempt to reuse serial number 100 for different token ID
        uint256[] memory serialNumbers2 = new uint256[](1);
        serialNumbers2[0] = 100;
        bytes memory serialNumberData2 = abi.encode(serialNumbers2);
        vm.expectRevert(abi.encodeWithSignature("SerialNumberAlreadyUsed()"));
        implementation.mintWithSerial(user1, 2, 1, serialNumberData2);
    }

    function testComplexTransferScenario() public {
        // Mint tokens with external serial numbers to user1
        uint256[] memory serialNumbers1 = new uint256[](3);
        serialNumbers1[0] = 100;
        serialNumbers1[1] = 200;
        serialNumbers1[2] = 300;
        bytes memory serialNumberData1 = abi.encode(serialNumbers1);
        implementation.mintWithSerial(user1, 1, 3, serialNumberData1);

        // Transfer some tokens to user2
        vm.startPrank(user1);
        implementation.safeTransferFrom(user1, user2, 1, 2, "");
        vm.stopPrank();

        // Mint more tokens with new serial numbers to user1
        uint256[] memory serialNumbers2 = new uint256[](2);
        serialNumbers2[0] = 400;
        serialNumbers2[1] = 500;
        bytes memory serialNumberData2 = abi.encode(serialNumbers2);
        implementation.mintWithSerial(user1, 1, 2, serialNumberData2);

        // Transfer one token from user2 back to user1
        vm.startPrank(user2);
        implementation.safeTransferFrom(user2, user1, 1, 1, "");
        vm.stopPrank();

        // Verify final state
        assertEq(implementation.balanceOf(user1, 1), 4);
        assertEq(implementation.balanceOf(user2, 1), 1);

        // Verify ownership of specific serials
        uint256[] memory user1Serials = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            user1Serials[i] = implementation.getSerialByOwnerAtIndex(user1, 1, i);
            assertEq(implementation.getOwnerOfSerial(user1Serials[i]), user1);
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

        // Test with wrong number of serial arrays
        bytes[] memory serialData = new bytes[](1); // Only one array for two ids
        serialData[0] = abi.encode(new uint256[](2));

        vm.expectRevert(abi.encodeWithSignature("InvalidSerialArraysLength()"));
        implementation.mintBatch(user1, ids, amounts, abi.encode(serialData));

        // Test with wrong number of serial numbers in array
        serialData = new bytes[](2);
        serialData[0] = abi.encode(new uint256[](1)); // Only one number for amount of 2
        serialData[1] = abi.encode(new uint256[](3));

        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumbersCount()"));
        implementation.mintBatch(user1, ids, amounts, abi.encode(serialData));
    }

    function testComplexBatchMintWithExternalSerials() public {
        // First batch mint
        uint256[] memory ids1 = new uint256[](2);
        ids1[0] = 1;
        ids1[1] = 2;

        uint256[] memory amounts1 = new uint256[](2);
        amounts1[0] = 2;
        amounts1[1] = 1;

        // Prepare serial numbers for first batch
        uint256[] memory serialNumbers1 = new uint256[](2);
        serialNumbers1[0] = 100;
        serialNumbers1[1] = 200;
        uint256[] memory serialNumbers2 = new uint256[](1);
        serialNumbers2[0] = 300;

        bytes[] memory serialData1 = new bytes[](2);
        serialData1[0] = abi.encode(serialNumbers1);
        serialData1[1] = abi.encode(serialNumbers2);

        bytes memory batchData1 = abi.encode(serialData1);
        implementation.mintBatch(user1, ids1, amounts1, batchData1);

        // Second batch mint with overlapping token IDs
        uint256[] memory ids2 = new uint256[](2);
        ids2[0] = 2; // Already has token ID 2
        ids2[1] = 3; // New token ID

        uint256[] memory amounts2 = new uint256[](2);
        amounts2[0] = 2;
        amounts2[1] = 3;

        // Prepare serial numbers for second batch
        uint256[] memory serialNumbers3 = new uint256[](2);
        serialNumbers3[0] = 400;
        serialNumbers3[1] = 500;
        uint256[] memory serialNumbers4 = new uint256[](3);
        serialNumbers4[0] = 600;
        serialNumbers4[1] = 700;
        serialNumbers4[2] = 800;

        bytes[] memory serialData2 = new bytes[](2);
        serialData2[0] = abi.encode(serialNumbers3);
        serialData2[1] = abi.encode(serialNumbers4);

        bytes memory batchData2 = abi.encode(serialData2);
        implementation.mintBatch(user1, ids2, amounts2, batchData2);

        // Verify final state for token ID 1
        assertEq(implementation.balanceOf(user1, 1), 2);
        assertEq(implementation.getFirstSerialByOwner(user1, 1), 100);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 1, 1), 200);

        // Verify final state for token ID 2 (combined from both mints)
        assertEq(implementation.balanceOf(user1, 2), 3);
        assertEq(implementation.getFirstSerialByOwner(user1, 2), 300);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 1), 400);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 2, 2), 500);

        // Verify final state for token ID 3
        assertEq(implementation.balanceOf(user1, 3), 3);
        assertEq(implementation.getFirstSerialByOwner(user1, 3), 600);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 3, 1), 700);
        assertEq(implementation.getSerialByOwnerAtIndex(user1, 3, 2), 800);

        // Verify all serial numbers are properly tracked
        for (uint256 i = 100; i <= 800; i += 100) {
            assertEq(implementation.getOwnerOfSerial(i), user1);
            if (i <= 200) {
                assertEq(implementation.getTokenIdForSerialNumber(i), 1);
            } else if (i <= 500) {
                assertEq(implementation.getTokenIdForSerialNumber(i), 2);
            } else {
                assertEq(implementation.getTokenIdForSerialNumber(i), 3);
            }
        }
    }

    function testRevertInvalidSerialQueries() public {
        implementation.toggleOverloadSerial(); // Switch to automatic mode
        implementation.mint(user1, 1, 1, "");

        // Try to get non-existent serial
        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumber()"));
        implementation.getSerial(1, 1);

        // Try to get serial for non-existent token
        vm.expectRevert(abi.encodeWithSignature("InvalidSerialNumber()"));
        implementation.getSerial(2, 0);

        // Try to get first serial for non-existent token
        vm.expectRevert(abi.encodeWithSignature("NoSerialsFound()"));
        implementation.getFirstSerialByOwner(user1, 2);

        // Try to get serial at invalid index
        vm.expectRevert(abi.encodeWithSignature("InvalidIndex()"));
        implementation.getSerialByOwnerAtIndex(user1, 1, 1);
    }

    receive() external payable {}
}
