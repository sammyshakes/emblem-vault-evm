// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../beacon/VaultBeacon.sol";
import "../beacon/VaultProxy.sol";
import "../interfaces/IVaultBeacon.sol";
import "../interfaces/IVaultProxy.sol";

/**
 * @title VaultFactory
 * @notice Factory contract for deploying vault proxies using the beacon pattern
 */
contract VaultFactory {
    // Events
    event ERC721VaultCreated(address indexed vault, string name, string symbol);
    event ERC1155VaultCreated(address indexed vault, string uri);
    event BeaconUpdated(uint8 indexed vaultType, address indexed oldBeacon, address indexed newBeacon);

    // Custom errors
    error InvalidVaultType();
    error ZeroAddress();
    error NotOwner();
    error InitializationFailed();

    // State variables
    address public immutable owner;
    address public erc721Beacon;
    address public erc1155Beacon;

    // Constants
    uint8 public constant ERC721_TYPE = 1;
    uint8 public constant ERC1155_TYPE = 2;

    /**
     * @notice Constructor
     * @param _erc721Beacon Address of the ERC721 beacon
     * @param _erc1155Beacon Address of the ERC1155 beacon
     */
    constructor(address _erc721Beacon, address _erc1155Beacon) {
        if (_erc721Beacon == address(0) || _erc1155Beacon == address(0)) revert ZeroAddress();
        owner = msg.sender;
        erc721Beacon = _erc721Beacon;
        erc1155Beacon = _erc1155Beacon;
    }

    /**
     * @notice Create a new ERC721 vault
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @return vault The address of the new vault
     */
    function createERC721Vault(string memory name, string memory symbol) external returns (address vault) {
        // Deploy proxy
        vault = address(new ERC721VaultProxy(erc721Beacon));

        // Initialize vault
        try IERC721VaultProxy(vault).initialize(name, symbol) {
            emit ERC721VaultCreated(vault, name, symbol);
        } catch {
            revert InitializationFailed();
        }
    }

    /**
     * @notice Create a new ERC1155 vault
     * @param uri The base URI for token metadata
     * @return vault The address of the new vault
     */
    function createERC1155Vault(string memory uri) external returns (address vault) {
        // Deploy proxy
        vault = address(new ERC1155VaultProxy(erc1155Beacon));

        // Initialize vault
        try IERC1155VaultProxy(vault).initialize(uri) {
            emit ERC1155VaultCreated(vault, uri);
        } catch {
            revert InitializationFailed();
        }
    }

    /**
     * @notice Update the beacon for a vault type
     * @param vaultType The type of vault (1 for ERC721, 2 for ERC1155)
     * @param newBeacon The address of the new beacon
     */
    function updateBeacon(uint8 vaultType, address newBeacon) external {
        if (msg.sender != owner) revert NotOwner();
        if (newBeacon == address(0)) revert ZeroAddress();

        address oldBeacon;
        if (vaultType == ERC721_TYPE) {
            oldBeacon = erc721Beacon;
            erc721Beacon = newBeacon;
        } else if (vaultType == ERC1155_TYPE) {
            oldBeacon = erc1155Beacon;
            erc1155Beacon = newBeacon;
        } else {
            revert InvalidVaultType();
        }

        emit BeaconUpdated(vaultType, oldBeacon, newBeacon);
    }

    /**
     * @notice Get the beacon address for a vault type
     * @param vaultType The type of vault (1 for ERC721, 2 for ERC1155)
     * @return The beacon address
     */
    function getBeacon(uint8 vaultType) external view returns (address) {
        if (vaultType == ERC721_TYPE) {
            return erc721Beacon;
        } else if (vaultType == ERC1155_TYPE) {
            return erc1155Beacon;
        } else {
            revert InvalidVaultType();
        }
    }

    /**
     * @notice Get the implementation address for a vault type
     * @param vaultType The type of vault (1 for ERC721, 2 for ERC1155)
     * @return The implementation address
     */
    function getImplementation(uint8 vaultType) external view returns (address) {
        address beacon = vaultType == ERC721_TYPE ? erc721Beacon : erc1155Beacon;
        if (beacon == address(0)) revert InvalidVaultType();
        return IVaultBeacon(beacon).implementation();
    }

    /**
     * @notice Check if an address is a vault created by this factory
     * @param vault The address to check
     * @return bool True if the address is a vault
     */
    function isVault(address vault) external view returns (bool) {
        if (vault.code.length == 0) return false;

        try IVaultProxy(vault).beacon() returns (address beaconAddress) {
            return beaconAddress == erc721Beacon || beaconAddress == erc1155Beacon;
        } catch {
            return false;
        }
    }
}
