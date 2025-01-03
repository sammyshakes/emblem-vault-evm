// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/beacon/VaultProxy.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/interfaces/IVaultBeacon.sol";
import "../src/interfaces/IVaultProxy.sol";
import "../src/libraries/LibErrors.sol";
import "../src/EmblemVaultDiamond.sol";

// Simple contract without implementation() function for testing
contract NonBeaconContract {
    function initialize(string memory, string memory) external pure {}
}

contract BeaconVaultTest is Test {
    VaultBeacon public beacon;
    ERC721VaultProxy public proxy;
    ERC721VaultImplementation public implementation;
    ERC721VaultImplementation public implementationV2;
    NonBeaconContract public nonBeacon;
    EmblemVaultDiamond public diamond;

    address owner = address(this);
    address user = address(0x1);
    address newOwner = address(0x2);

    // Events
    event ImplementationUpgraded(
        address indexed oldImplementation, address indexed newImplementation
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BeaconSet(address indexed beacon);

    function setUp() public {
        // Deploy implementation
        implementation = new ERC721VaultImplementation();

        // Deploy beacon
        beacon = new VaultBeacon(address(implementation));

        // Deploy proxy
        proxy = new ERC721VaultProxy(address(beacon));

        // Deploy non-beacon contract
        nonBeacon = new NonBeaconContract();

        // Deploy diamond
        diamond = new EmblemVaultDiamond(owner, address(5));

        // Initialize the proxy
        ERC721VaultImplementation(address(proxy)).initialize("TestVault", "TEST", address(diamond));
    }

    // ============ Initial Setup Tests ============

    function testInitialSetup() public view {
        assertEq(beacon.implementation(), address(implementation));
        assertEq(beacon.owner(), owner);
        assertEq(address(IVaultProxy(address(proxy)).beacon()), address(beacon));

        // Check initialization worked
        assertEq(ERC721VaultImplementation(address(proxy)).name(), "TestVault");
        assertEq(ERC721VaultImplementation(address(proxy)).symbol(), "TEST");
    }

    function testProxyDelegation() public {
        // Test minting through proxy
        vm.prank(address(diamond));
        ERC721VaultImplementation(address(proxy)).mint(user, 1);
        assertEq(ERC721VaultImplementation(address(proxy)).ownerOf(1), user);
        assertEq(ERC721VaultImplementation(address(proxy)).getInternalTokenId(1), 1);
    }

    // ============ Upgrade Tests ============

    function testUpgrade() public {
        // Deploy new implementation
        implementationV2 = new ERC721VaultImplementation();

        // Mint a token before upgrade
        vm.prank(address(diamond));
        ERC721VaultImplementation(address(proxy)).mint(user, 1);

        // Upgrade beacon
        vm.expectEmit(true, true, true, true);
        emit ImplementationUpgraded(address(implementation), address(implementationV2));
        vm.prank(owner);
        beacon.upgrade(address(implementationV2));

        // Check new implementation
        assertEq(beacon.implementation(), address(implementationV2));

        // Verify state persisted through upgrade
        assertEq(ERC721VaultImplementation(address(proxy)).ownerOf(1), user);
        assertEq(ERC721VaultImplementation(address(proxy)).getInternalTokenId(1), 1);
    }

    function testRevertUpgradeUnauthorized() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, user));
        beacon.upgrade(address(0));
        vm.stopPrank();
    }

    function testRevertUpgradeToZeroAddress() public {
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        beacon.upgrade(address(0));
    }

    // ============ Ownership Tests ============

    function testTransferOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(owner, newOwner);
        beacon.transferOwnership(newOwner);
        assertEq(beacon.owner(), newOwner);

        // Verify new owner can upgrade implementation
        vm.startPrank(newOwner);
        implementationV2 = new ERC721VaultImplementation();
        beacon.upgrade(address(implementationV2));
        vm.stopPrank();
    }

    function testRevertTransferOwnershipUnauthorized() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, user));
        beacon.transferOwnership(newOwner);
        vm.stopPrank();
    }

    function testRevertTransferOwnershipToZeroAddress() public {
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        beacon.transferOwnership(address(0));
    }

    // ============ Multiple Proxies Tests ============

    function testMultipleProxies() public {
        // Deploy second proxy
        ERC721VaultProxy proxy2 = new ERC721VaultProxy(address(beacon));
        ERC721VaultImplementation(address(proxy2)).initialize(
            "TestVault2", "TEST2", address(diamond)
        );

        // Mint tokens on both proxies
        vm.startPrank(address(diamond));
        ERC721VaultImplementation(address(proxy)).mint(user, 1);
        ERC721VaultImplementation(address(proxy2)).mint(user, 2);
        vm.stopPrank();

        // Verify independent state
        assertEq(ERC721VaultImplementation(address(proxy)).name(), "TestVault");
        assertEq(ERC721VaultImplementation(address(proxy2)).name(), "TestVault2");
        assertEq(ERC721VaultImplementation(address(proxy)).ownerOf(1), user);
        assertEq(ERC721VaultImplementation(address(proxy2)).ownerOf(1), user);

        // Upgrade implementation
        implementationV2 = new ERC721VaultImplementation();
        vm.expectEmit(true, true, true, true);
        emit ImplementationUpgraded(address(implementation), address(implementationV2));
        beacon.upgrade(address(implementationV2));

        // Verify state persisted in both proxies
        assertEq(ERC721VaultImplementation(address(proxy)).ownerOf(1), user);
        assertEq(ERC721VaultImplementation(address(proxy2)).ownerOf(1), user);
        assertEq(ERC721VaultImplementation(address(proxy)).name(), "TestVault");
        assertEq(ERC721VaultImplementation(address(proxy2)).name(), "TestVault2");
    }

    // ============ Failure Tests ============

    function testRevertDoubleInitialization() public {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        ERC721VaultImplementation(address(proxy)).initialize(
            "TestVault2", "TEST2", address(diamond)
        );
    }

    function testRevertUpgradeAfterOwnershipTransfer() public {
        // Transfer ownership
        beacon.transferOwnership(newOwner);

        // Try to upgrade with old owner
        vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, address(this)));
        beacon.upgrade(address(0));
    }

    // ============ Proxy Initialization Tests ============

    function testRevertProxyWithZeroBeacon() public {
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        new ERC721VaultProxy(address(0));
    }

    function testRevertProxyWithNonContractBeacon() public {
        // Create proxy with EOA as beacon
        ERC721VaultProxy invalidProxy = new ERC721VaultProxy(user);

        // First call should fail since EOA can't respond to implementation()
        vm.expectRevert();
        ERC721VaultImplementation(address(invalidProxy)).initialize("Test", "TST", address(diamond));
    }

    function testRevertProxyWithNonBeaconContract() public {
        // Create proxy with non-beacon contract
        ERC721VaultProxy invalidProxy = new ERC721VaultProxy(address(nonBeacon));

        // First call should fail since contract doesn't have implementation()
        vm.expectRevert();
        ERC721VaultImplementation(address(invalidProxy)).initialize("Test", "TST", address(diamond));
    }
}
