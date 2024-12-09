// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/beacon/VaultProxy.sol";
import "../src/interfaces/IVaultBeacon.sol";
import "../src/interfaces/IVaultProxy.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// Mock implementation for testing
contract MockImplementation is IERC165 {
    bool public initialized;
    string public name;
    string public symbol;

    function initialize(string memory _name, string memory _symbol) external {
        require(!initialized, "Already initialized");
        name = _name;
        symbol = _symbol;
        initialized = true;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// Updated implementation for testing upgrades
contract MockImplementationV2 is IERC165 {
    bool public initialized;
    string public name;
    string public symbol;
    uint256 public constant version = 2;

    function initialize(string memory _name, string memory _symbol) external {
        require(!initialized, "Already initialized");
        name = _name;
        symbol = _symbol;
        initialized = true;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract BeaconVaultTest is Test {
    VaultBeacon public beacon;
    VaultProxy public proxy;
    MockImplementation public implementation;
    MockImplementationV2 public implementationV2;

    address owner = address(this);
    address user = address(0x1);

    function setUp() public {
        // Deploy implementation
        implementation = new MockImplementation();

        // Deploy beacon
        beacon = new VaultBeacon(address(implementation));

        // Deploy proxy
        proxy = new VaultProxy(address(beacon));
    }

    function testInitialSetup() public view {
        assertEq(beacon.implementation(), address(implementation));
        assertEq(beacon.owner(), owner);
    }

    function testProxyDelegation() public {
        // Initialize through proxy
        MockImplementation(address(proxy)).initialize("Test", "TST");

        // Check values through proxy
        assertEq(MockImplementation(address(proxy)).name(), "Test");
        assertEq(MockImplementation(address(proxy)).symbol(), "TST");
        assertTrue(MockImplementation(address(proxy)).initialized());
    }

    function testUpgrade() public {
        // Deploy new implementation
        implementationV2 = new MockImplementationV2();

        // Initialize first version
        MockImplementation(address(proxy)).initialize("Test", "TST");

        // Upgrade beacon
        beacon.upgrade(address(implementationV2));

        // Check new implementation
        assertEq(beacon.implementation(), address(implementationV2));

        // Check version through proxy (should be 2 without re-initialization)
        assertEq(MockImplementationV2(address(proxy)).version(), 2);
    }

    function testFailUpgradeUnauthorized() public {
        vm.prank(user);
        beacon.upgrade(address(implementationV2));
    }

    function testFailUpgradeToZeroAddress() public {
        beacon.upgrade(address(0));
    }

    function testFailUpgradeToInvalidImplementation() public {
        // Deploy invalid implementation (doesn't support IERC165)
        InvalidImplementation invalid = new InvalidImplementation();
        beacon.upgrade(address(invalid));
    }

    function testTransferOwnership() public {
        beacon.transferOwnership(user);
        assertEq(beacon.owner(), user);
    }

    function testFailTransferOwnershipUnauthorized() public {
        vm.prank(user);
        beacon.transferOwnership(user);
    }

    function testFailTransferOwnershipToZeroAddress() public {
        beacon.transferOwnership(address(0));
    }

    function testMultipleProxies() public {
        // Deploy second proxy
        VaultProxy proxy2 = new VaultProxy(address(beacon));

        // Initialize both proxies
        MockImplementation(address(proxy)).initialize("Test1", "TST1");
        MockImplementation(address(proxy2)).initialize("Test2", "TST2");

        // Check values
        assertEq(MockImplementation(address(proxy)).name(), "Test1");
        assertEq(MockImplementation(address(proxy2)).name(), "Test2");

        // Upgrade implementation
        implementationV2 = new MockImplementationV2();
        beacon.upgrade(address(implementationV2));

        // Both proxies should now use new implementation and have version 2
        assertEq(MockImplementationV2(address(proxy)).version(), 2);
        assertEq(MockImplementationV2(address(proxy2)).version(), 2);
    }
}

// Invalid implementation for testing
contract InvalidImplementation {
    function initialize(string memory, string memory) external pure {}
}
