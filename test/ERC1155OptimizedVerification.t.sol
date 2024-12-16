// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/implementations/ERC1155VaultImplementationOptimized.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/beacon/VaultProxy.sol";
import "../src/factories/VaultCollectionFactory.sol";
import "../src/libraries/LibErrors.sol";

contract ERC1155OptimizedVerificationTest is Test {
    // Core contracts
    ERC1155VaultImplementationOptimized public implementation;
    VaultBeacon public beacon;
    VaultCollectionFactory public factory;
    address public collection;

    // Test addresses
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    // Events
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event SerialNumberAssigned(uint256 indexed tokenId, uint256 indexed serialNumber);

    function setUp() public {
        // Deploy implementation and beacon
        implementation = new ERC1155VaultImplementationOptimized();
        beacon = new VaultBeacon(address(implementation));

        // Deploy factory (with dummy ERC721 beacon)
        factory = new VaultCollectionFactory(
            address(0x1), // dummy ERC721 beacon
            address(beacon),
            address(this)
        );

        // Transfer beacon ownership
        beacon.transferOwnership(address(factory));

        // Create test collection
        collection = factory.createERC1155Collection("https://test.uri/");

        // Setup test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testInitialization() public {
        assertEq(ERC1155VaultImplementationOptimized(collection).uri(0), "https://test.uri/");
        assertTrue(factory.isCollection(collection));
        assertEq(factory.getCollectionType(collection), 2); // ERC1155_TYPE
        assertEq(OwnableUpgradeable(collection).owner(), address(this));
    }

    function testSingleMint() public {
        // Test minting
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), address(0), user1, 1, 1);
        ERC1155VaultImplementationOptimized(collection).mint(user1, 1, 1, "");

        // Verify balance and serial number
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user1, 1), 1);
        uint256 serial =
            ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(user1, 1);
        assertEq(ERC1155VaultImplementationOptimized(collection).getOwnerOfSerial(serial), user1);
    }

    function testBatchMint() public {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 3;
        amounts[1] = 2;

        ERC1155VaultImplementationOptimized(collection).mintBatch(user1, ids, amounts, "");

        // Verify balances
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user1, 1), 3);
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user1, 2), 2);

        // Verify serial numbers
        uint256 serial1 =
            ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(user1, 1);
        uint256 serial2 =
            ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(user1, 2);
        assertEq(
            ERC1155VaultImplementationOptimized(collection).getTokenIdForSerialNumber(serial1), 1
        );
        assertEq(
            ERC1155VaultImplementationOptimized(collection).getTokenIdForSerialNumber(serial2), 2
        );
    }

    function testTransfer() public {
        // Setup: Mint token
        ERC1155VaultImplementationOptimized(collection).mint(user1, 1, 5, "");
        uint256 serial =
            ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(user1, 1);

        // Test transfer
        vm.startPrank(user1);
        ERC1155VaultImplementationOptimized(collection).safeTransferFrom(user1, user2, 1, 2, "");
        vm.stopPrank();

        // Verify balances
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user1, 1), 3);
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user2, 1), 2);

        // Verify serial number ownership
        uint256 user2Serial =
            ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(user2, 1);
        assertEq(
            ERC1155VaultImplementationOptimized(collection).getOwnerOfSerial(user2Serial), user2
        );
    }

    function testBatchTransfer() public {
        // Setup: Mint tokens
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 5;
        amounts[1] = 3;
        ERC1155VaultImplementationOptimized(collection).mintBatch(user1, ids, amounts, "");

        // Test batch transfer
        vm.startPrank(user1);
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 2;
        transferAmounts[1] = 1;
        ERC1155VaultImplementationOptimized(collection).safeBatchTransferFrom(
            user1, user2, ids, transferAmounts, ""
        );
        vm.stopPrank();

        // Verify balances
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user1, 1), 3);
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user1, 2), 2);
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user2, 1), 2);
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user2, 2), 1);

        // Verify serial numbers
        uint256 user2Serial1 =
            ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(user2, 1);
        uint256 user2Serial2 =
            ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(user2, 2);
        assertEq(
            ERC1155VaultImplementationOptimized(collection).getOwnerOfSerial(user2Serial1), user2
        );
        assertEq(
            ERC1155VaultImplementationOptimized(collection).getOwnerOfSerial(user2Serial2), user2
        );
    }

    function testBurn() public {
        // Setup: Mint tokens
        ERC1155VaultImplementationOptimized(collection).mint(user1, 1, 5, "");
        uint256 serial =
            ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(user1, 1);

        // Test burn
        vm.startPrank(user1);
        ERC1155VaultImplementationOptimized(collection).burn(user1, 1, 2);
        vm.stopPrank();

        // Verify balance
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user1, 1), 3);

        // Verify serial numbers were properly cleaned up
        vm.expectRevert("No serials found");
        ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(address(0), 1);
    }

    function testUpgrade() public {
        // Setup: Mint tokens
        ERC1155VaultImplementationOptimized(collection).mint(user1, 1, 5, "");
        uint256 serial =
            ERC1155VaultImplementationOptimized(collection).getFirstSerialByOwner(user1, 1);

        // Deploy new implementation
        ERC1155VaultImplementationOptimized newImplementation =
            new ERC1155VaultImplementationOptimized();

        // Upgrade
        factory.updateBeacon(2, address(newImplementation));

        // Verify state persisted
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user1, 1), 5);
        assertEq(ERC1155VaultImplementationOptimized(collection).getOwnerOfSerial(serial), user1);

        // Verify new functionality works
        ERC1155VaultImplementationOptimized(collection).mint(user2, 2, 3, "");
        assertEq(ERC1155VaultImplementationOptimized(collection).balanceOf(user2, 2), 3);
    }

    function testAccessControl() public {
        // Test unauthorized mint
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        ERC1155VaultImplementationOptimized(collection).mint(user1, 1, 1, "");
        vm.stopPrank();

        // Test unauthorized URI update
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        ERC1155VaultImplementationOptimized(collection).setURI("new-uri");
        vm.stopPrank();
    }

    function testSerialNumberTracking() public {
        // Mint tokens
        ERC1155VaultImplementationOptimized(collection).mint(user1, 1, 3, "");

        // Test serial number queries
        uint256 serial1 = ERC1155VaultImplementationOptimized(collection).getSerial(1, 0);
        uint256 serial2 = ERC1155VaultImplementationOptimized(collection).getSerial(1, 1);
        uint256 serial3 = ERC1155VaultImplementationOptimized(collection).getSerial(1, 2);

        // Verify serial numbers are unique
        assertTrue(serial1 != serial2 && serial2 != serial3 && serial1 != serial3);

        // Verify ownership
        assertEq(ERC1155VaultImplementationOptimized(collection).getOwnerOfSerial(serial1), user1);
        assertEq(ERC1155VaultImplementationOptimized(collection).getOwnerOfSerial(serial2), user1);
        assertEq(ERC1155VaultImplementationOptimized(collection).getOwnerOfSerial(serial3), user1);

        // Verify token IDs
        assertEq(
            ERC1155VaultImplementationOptimized(collection).getTokenIdForSerialNumber(serial1), 1
        );
        assertEq(
            ERC1155VaultImplementationOptimized(collection).getTokenIdForSerialNumber(serial2), 1
        );
        assertEq(
            ERC1155VaultImplementationOptimized(collection).getTokenIdForSerialNumber(serial3), 1
        );
    }
}
