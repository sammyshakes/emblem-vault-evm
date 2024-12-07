// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibVaultStorage.sol";
import "../interfaces/IHandlerCallback.sol";

contract InitializationFacet {
    event VaultInitialized(address indexed owner, string metadataBaseUri);
    event InterfaceIdSet(bytes4 indexed interfaceId, string name);

    function initialize(address _owner) external {
        require(_owner != address(0), "InitializationFacet: Owner cannot be zero address");
        require(msg.sender == LibDiamond.contractOwner(), "InitializationFacet: Not contract owner");

        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        require(!vs.initialized, "InitializationFacet: Already initialized");

        // Set initial configuration
        vs.metadataBaseUri = "https://v2.emblemvault.io/meta/";
        vs.recipientAddress = _owner;
        vs.allowCallbacks = true;

        // Set interface IDs
        vs.INTERFACE_ID_ERC1155 = 0xd9b67a26;
        vs.INTERFACE_ID_ERC20 = 0x74a1476f;
        vs.INTERFACE_ID_ERC721 = 0x80ac58cd;
        vs.INTERFACE_ID_ERC721A = 0xf4a95f26;

        // Add owner as initial witness
        vs.witnesses[_owner] = true;

        // Mark as initialized
        vs.initialized = true;

        // Emit events
        emit VaultInitialized(_owner, vs.metadataBaseUri);
        emit InterfaceIdSet(vs.INTERFACE_ID_ERC1155, "ERC1155");
        emit InterfaceIdSet(vs.INTERFACE_ID_ERC20, "ERC20");
        emit InterfaceIdSet(vs.INTERFACE_ID_ERC721, "ERC721");
        emit InterfaceIdSet(vs.INTERFACE_ID_ERC721A, "ERC721A");
    }

    function isInitialized() external view returns (bool) {
        return LibVaultStorage.vaultStorage().initialized;
    }

    function getInterfaceIds() external view returns (bytes4 erc1155, bytes4 erc20, bytes4 erc721, bytes4 erc721a) {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        return (vs.INTERFACE_ID_ERC1155, vs.INTERFACE_ID_ERC20, vs.INTERFACE_ID_ERC721, vs.INTERFACE_ID_ERC721A);
    }

    function getConfiguration()
        external
        view
        returns (
            string memory metadataBaseUri,
            address recipientAddress,
            address quoteContract,
            bool allowCallbacks,
            bool byPassable
        )
    {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        return (vs.metadataBaseUri, vs.recipientAddress, vs.quoteContract, vs.allowCallbacks, vs.byPassable);
    }

    function version() external pure returns (string memory) {
        return "3.0.0";
    }
}
