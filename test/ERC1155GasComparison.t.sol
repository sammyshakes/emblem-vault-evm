// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";
import "../src/implementations/ERC1155VaultImplementationOptimized.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/factories/VaultCollectionFactory.sol";

contract ERC1155GasComparisonTest is Test {
    // Core contracts
    ERC721VaultImplementation public erc721Implementation;
    ERC1155VaultImplementation public originalImpl;
    ERC1155VaultImplementationOptimized public optimizedImpl;
    VaultBeacon public erc721BeaconOriginal;
    VaultBeacon public erc721BeaconOptimized;
    VaultBeacon public originalBeacon;
    VaultBeacon public optimizedBeacon;
    VaultCollectionFactory public originalFactory;
    VaultCollectionFactory public optimizedFactory;

    // Collection addresses
    address public originalCollection;
    address public optimizedCollection;

    // Test addresses
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        // Deploy implementations
        erc721Implementation = new ERC721VaultImplementation();
        originalImpl = new ERC1155VaultImplementation();
        optimizedImpl = new ERC1155VaultImplementationOptimized();

        // Deploy beacons
        erc721BeaconOriginal = new VaultBeacon(address(erc721Implementation));
        erc721BeaconOptimized = new VaultBeacon(address(erc721Implementation));
        originalBeacon = new VaultBeacon(address(originalImpl));
        optimizedBeacon = new VaultBeacon(address(optimizedImpl));

        // Deploy factories with this contract as Diamond
        originalFactory = new VaultCollectionFactory(
            address(erc721BeaconOriginal), address(originalBeacon), address(this)
        );
        optimizedFactory = new VaultCollectionFactory(
            address(erc721BeaconOptimized), address(optimizedBeacon), address(this)
        );

        // Transfer beacon ownership to respective factories
        erc721BeaconOriginal.transferOwnership(address(originalFactory));
        originalBeacon.transferOwnership(address(originalFactory));
        erc721BeaconOptimized.transferOwnership(address(optimizedFactory));
        optimizedBeacon.transferOwnership(address(optimizedFactory));

        // Create collections
        originalCollection = originalFactory.createERC1155Collection("https://api.original.test/");
        optimizedCollection =
            optimizedFactory.createERC1155Collection("https://api.optimized.test/");

        // Setup test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testGasSingleMint() public {
        // Test original implementation
        uint256 gasBefore = gasleft();
        ERC1155VaultImplementation(originalCollection).mint(user1, 1, 1, "");
        uint256 originalGas = gasBefore - gasleft();

        // Test optimized implementation
        gasBefore = gasleft();
        ERC1155VaultImplementationOptimized(optimizedCollection).mint(user1, 1, 1, "");
        uint256 optimizedGas = gasBefore - gasleft();

        console.log("Single Mint Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas > optimizedGas ? originalGas - optimizedGas : 0);
    }

    function testGasBatchMint() public {
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;
        amounts[0] = 5;
        amounts[1] = 3;
        amounts[2] = 2;

        // Test original implementation
        uint256 gasBefore = gasleft();
        ERC1155VaultImplementation(originalCollection).mintBatch(user1, ids, amounts, "");
        uint256 originalGas = gasBefore - gasleft();

        // Test optimized implementation
        gasBefore = gasleft();
        ERC1155VaultImplementationOptimized(optimizedCollection).mintBatch(user1, ids, amounts, "");
        uint256 optimizedGas = gasBefore - gasleft();

        console.log("Batch Mint Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas > optimizedGas ? originalGas - optimizedGas : 0);
    }

    function testGasTransfer() public {
        // Setup: Mint tokens first
        ERC1155VaultImplementation(originalCollection).mint(user1, 1, 5, "");
        ERC1155VaultImplementationOptimized(optimizedCollection).mint(user1, 1, 5, "");

        // Test original implementation transfer
        vm.startPrank(user1);
        uint256 gasBefore = gasleft();
        ERC1155VaultImplementation(originalCollection).safeTransferFrom(user1, user2, 1, 2, "");
        uint256 originalGas = gasBefore - gasleft();
        vm.stopPrank();

        // Test optimized implementation transfer
        vm.startPrank(user1);
        gasBefore = gasleft();
        ERC1155VaultImplementationOptimized(optimizedCollection).safeTransferFrom(
            user1, user2, 1, 2, ""
        );
        uint256 optimizedGas = gasBefore - gasleft();
        vm.stopPrank();

        console.log("Transfer Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas > optimizedGas ? originalGas - optimizedGas : 0);
    }

    function testGasBatchTransfer() public {
        // Setup: Mint batch tokens first
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 5;
        amounts[1] = 3;

        ERC1155VaultImplementation(originalCollection).mintBatch(user1, ids, amounts, "");
        ERC1155VaultImplementationOptimized(optimizedCollection).mintBatch(user1, ids, amounts, "");

        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 2;
        transferAmounts[1] = 1;

        // Test original implementation batch transfer
        vm.startPrank(user1);
        uint256 gasBefore = gasleft();
        ERC1155VaultImplementation(originalCollection).safeBatchTransferFrom(
            user1, user2, ids, transferAmounts, ""
        );
        uint256 originalGas = gasBefore - gasleft();
        vm.stopPrank();

        // Test optimized implementation batch transfer
        vm.startPrank(user1);
        gasBefore = gasleft();
        ERC1155VaultImplementationOptimized(optimizedCollection).safeBatchTransferFrom(
            user1, user2, ids, transferAmounts, ""
        );
        uint256 optimizedGas = gasBefore - gasleft();
        vm.stopPrank();

        console.log("Batch Transfer Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas > optimizedGas ? originalGas - optimizedGas : 0);
    }

    function testGasBurn() public {
        // Setup: Mint tokens first
        ERC1155VaultImplementation(originalCollection).mint(user1, 1, 5, "");
        ERC1155VaultImplementationOptimized(optimizedCollection).mint(user1, 1, 5, "");

        // Test original implementation burn
        vm.startPrank(user1);
        uint256 gasBefore = gasleft();
        ERC1155VaultImplementation(originalCollection).burn(user1, 1, 2);
        uint256 originalGas = gasBefore - gasleft();
        vm.stopPrank();

        // Test optimized implementation burn
        vm.startPrank(user1);
        gasBefore = gasleft();
        ERC1155VaultImplementationOptimized(optimizedCollection).burn(user1, 1, 2);
        uint256 optimizedGas = gasBefore - gasleft();
        vm.stopPrank();

        console.log("Burn Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas > optimizedGas ? originalGas - optimizedGas : 0);
    }

    function testGasSerialQueries() public {
        // Setup: Mint tokens first
        ERC1155VaultImplementation(originalCollection).mint(user1, 1, 3, "");
        ERC1155VaultImplementationOptimized(optimizedCollection).mint(user1, 1, 3, "");

        // Test getSerial
        uint256 gasBefore = gasleft();
        ERC1155VaultImplementation(originalCollection).getSerial(1, 0);
        uint256 originalGas = gasBefore - gasleft();

        gasBefore = gasleft();
        ERC1155VaultImplementationOptimized(optimizedCollection).getSerial(1, 0);
        uint256 optimizedGas = gasBefore - gasleft();

        console.log("Get Serial Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas > optimizedGas ? originalGas - optimizedGas : 0);

        // Test getFirstSerialByOwner
        gasBefore = gasleft();
        ERC1155VaultImplementation(originalCollection).getFirstSerialByOwner(user1, 1);
        originalGas = gasBefore - gasleft();

        gasBefore = gasleft();
        ERC1155VaultImplementationOptimized(optimizedCollection).getFirstSerialByOwner(user1, 1);
        optimizedGas = gasBefore - gasleft();

        console.log("Get First Serial By Owner Gas Comparison:");
        console.log("Original Implementation:", originalGas);
        console.log("Optimized Implementation:", optimizedGas);
        console.log("Gas Saved:", originalGas > optimizedGas ? originalGas - optimizedGas : 0);
    }

    receive() external payable {}
}
