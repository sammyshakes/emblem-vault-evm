// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./VaultBeacon.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title VaultProxy
 * @notice Proxy contract that delegates calls to implementation from beacon
 * @dev Follows EIP-1967 proxy pattern
 */
contract VaultProxy is IERC165 {
    // Beacon slot follows EIP-1967
    bytes32 private constant BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    // Events
    event BeaconSet(address indexed beacon);

    // Custom errors
    error ZeroAddress();
    error InitializationFailed();
    error DelegationFailed();

    /**
     * @notice Constructor
     * @param _beacon Address of the beacon contract
     */
    constructor(address _beacon) {
        if (_beacon == address(0)) revert ZeroAddress();
        _setBeacon(_beacon);
    }

    /**
     * @notice Get the current beacon address
     * @return beacon The beacon address
     */
    function _getBeacon() internal view returns (address beacon) {
        bytes32 slot = BEACON_SLOT;
        assembly {
            beacon := sload(slot)
        }
    }

    /**
     * @notice Set the beacon address
     * @param _beacon New beacon address
     */
    function _setBeacon(address _beacon) internal {
        bytes32 slot = BEACON_SLOT;
        assembly {
            sstore(slot, _beacon)
        }
        emit BeaconSet(_beacon);
    }

    /**
     * @notice Get the current implementation address
     * @return The implementation address from the beacon
     */
    function _implementation() internal view returns (address) {
        return VaultBeacon(_getBeacon()).implementation();
    }

    /**
     * @notice Interface support check
     * @param interfaceId Interface identifier
     * @return bool True if interface is supported
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Check implementation for interface support
        return IERC165(_implementation()).supportsInterface(interfaceId);
    }

    /**
     * @notice Fallback function that delegates calls to the implementation
     */
    fallback() external payable virtual {
        address implementation = _implementation();

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Delegate call to the implementation
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data
            returndatacopy(0, 0, returndatasize())

            switch result
            // Delegation failed
            case 0 { revert(0, returndatasize()) }
            // Delegation succeeded
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @notice Receive function to accept ETH
     */
    receive() external payable virtual {}
}

/**
 * @title ERC721VaultProxy
 * @notice Proxy specifically for ERC721 vaults
 */
contract ERC721VaultProxy is VaultProxy {
    constructor(address _beacon) VaultProxy(_beacon) {}
}

/**
 * @title ERC1155VaultProxy
 * @notice Proxy specifically for ERC1155 vaults
 */
contract ERC1155VaultProxy is VaultProxy {
    constructor(address _beacon) VaultProxy(_beacon) {}
}
