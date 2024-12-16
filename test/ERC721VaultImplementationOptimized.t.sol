// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/beacon/VaultProxy.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/implementations/ERC721VaultImplementationOptimized.sol";

contract ERC721VaultImplementationOptimizedTest is Test {
    VaultBeacon beaconOriginal;
    VaultBeacon beaconOptimized;
    ERC721VaultProxy proxyOriginal;
    ERC721VaultProxy proxyOptimized;
    ERC721VaultImplementation original;
    ERC721VaultImplementationOptimized optimized;

    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy implementations
        original = new ERC721VaultImplementation();
        optimized = new ERC721VaultImplementationOptimized();

        // Deploy beacons
        beaconOriginal = new VaultBeacon(address(original));
        beaconOptimized = new VaultBeacon(address(optimized));

        // Deploy proxies
        proxyOriginal = new ERC721VaultProxy(address(beaconOriginal));
        proxyOptimized = new ERC721VaultProxy(address(beaconOptimized));

        // Initialize proxies
        ERC721VaultImplementation(address(proxyOriginal)).initialize("Original", "ORG");
        ERC721VaultImplementationOptimized(address(proxyOptimized)).initialize("Optimized", "OPT");

        // Fund test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testGasComparisonSingleMint() public {
        // Original
        uint256 gasStartOriginal = gasleft();
        ERC721VaultImplementation(address(proxyOriginal)).mint(user1, 1);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        ERC721VaultImplementationOptimized(address(proxyOptimized)).mint(user1, 2);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original mint)", gasOriginal);
        emit log_named_uint("Gas used (optimized mint)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonBatchMint() public {
        address[] memory users = new address[](5);
        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            users[i] = address(uint160(i + 1));
            tokenIds[i] = i + 1;
        }

        // Original
        uint256 gasStartOriginal = gasleft();
        ERC721VaultImplementation(address(proxyOriginal)).mintMany(users, tokenIds);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Update tokenIds for optimized test
        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = i + 6;
        }

        // Optimized
        uint256 gasStartOptimized = gasleft();
        ERC721VaultImplementationOptimized(address(proxyOptimized)).mintMany(users, tokenIds);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original batch mint)", gasOriginal);
        emit log_named_uint("Gas used (optimized batch mint)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonBurn() public {
        // Setup
        ERC721VaultImplementation(address(proxyOriginal)).mint(user1, 1);
        ERC721VaultImplementationOptimized(address(proxyOptimized)).mint(user1, 2);

        vm.startPrank(user1);

        // Original
        uint256 gasStartOriginal = gasleft();
        ERC721VaultImplementation(address(proxyOriginal)).burn(1);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        ERC721VaultImplementationOptimized(address(proxyOptimized)).burn(1);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        vm.stopPrank();

        emit log_named_uint("Gas used (original burn)", gasOriginal);
        emit log_named_uint("Gas used (optimized burn)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonSetBaseURI() public {
        string memory newURI = "https://api.example.com/token/";

        // Original
        uint256 gasStartOriginal = gasleft();
        ERC721VaultImplementation(address(proxyOriginal)).setBaseURI(newURI);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        ERC721VaultImplementationOptimized(address(proxyOptimized)).setBaseURI(newURI);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original setBaseURI)", gasOriginal);
        emit log_named_uint("Gas used (optimized setBaseURI)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonSetDetails() public {
        string memory newName = "Updated Name";
        string memory newSymbol = "UPD";

        // Original
        uint256 gasStartOriginal = gasleft();
        ERC721VaultImplementation(address(proxyOriginal)).setDetails(newName, newSymbol);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        ERC721VaultImplementationOptimized(address(proxyOptimized)).setDetails(newName, newSymbol);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original setDetails)", gasOriginal);
        emit log_named_uint("Gas used (optimized setDetails)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonMintWithData() public {
        bytes memory data = abi.encode("test data");

        // Original
        uint256 gasStartOriginal = gasleft();
        ERC721VaultImplementation(address(proxyOriginal)).mintWithData(user1, 1, data);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        ERC721VaultImplementationOptimized(address(proxyOptimized)).mintWithData(user1, 2, data);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        emit log_named_uint("Gas used (original mintWithData)", gasOriginal);
        emit log_named_uint("Gas used (optimized mintWithData)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }

    function testGasComparisonBurnWithData() public {
        bytes memory data = abi.encode("test data");

        // Setup
        ERC721VaultImplementation(address(proxyOriginal)).mint(user1, 1);
        ERC721VaultImplementationOptimized(address(proxyOptimized)).mint(user1, 2);

        vm.startPrank(user1);

        // Original
        uint256 gasStartOriginal = gasleft();
        ERC721VaultImplementation(address(proxyOriginal)).burnWithData(1, data);
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized
        uint256 gasStartOptimized = gasleft();
        ERC721VaultImplementationOptimized(address(proxyOptimized)).burnWithData(1, data);
        uint256 gasOptimized = gasStartOptimized - gasleft();

        vm.stopPrank();

        emit log_named_uint("Gas used (original burnWithData)", gasOriginal);
        emit log_named_uint("Gas used (optimized burnWithData)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");
    }
}
