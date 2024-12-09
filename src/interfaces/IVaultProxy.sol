// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IVaultProxy
 * @notice Interface for vault proxy contracts
 * @dev Must support IERC165 for interface detection
 */
interface IVaultProxy is IERC165 {
    /**
     * @notice Get the current beacon address
     * @dev This is an optional view function that can be exposed
     * @return The address of the current beacon
     */
    function beacon() external view returns (address);

    /**
     * @notice Get the current implementation address
     * @dev This is an optional view function that can be exposed
     * @return The address of the current implementation
     */
    function implementation() external view returns (address);

    /**
     * @dev Custom errors
     */
    error ZeroAddress();
    error InitializationFailed();
    error DelegationFailed();
    error InvalidBeacon();

    /**
     * @notice Emitted when beacon is set
     * @param beacon The address of the beacon contract
     */
    event BeaconSet(address indexed beacon);

    /**
     * @notice Emitted when a call is delegated
     * @param implementation The address of the implementation contract
     * @param success Whether the delegated call was successful
     */
    event DelegatedCall(address indexed implementation, bool indexed success);
}

/**
 * @title IERC721VaultProxy
 * @notice Interface for ERC721-specific vault proxies
 */
interface IERC721VaultProxy is IVaultProxy {
    /**
     * @notice Initialize the ERC721 vault
     * @param name The name of the token
     * @param symbol The symbol of the token
     */
    function initialize(string memory name, string memory symbol) external;
}

/**
 * @title IERC1155VaultProxy
 * @notice Interface for ERC1155-specific vault proxies
 */
interface IERC1155VaultProxy is IVaultProxy {
    /**
     * @notice Initialize the ERC1155 vault
     * @param uri The base URI for token metadata
     */
    function initialize(string memory uri) external;
}
