// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155MetadataURI} from
    "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {IIsSerialized} from "./IIsSerialized.sol";
import {IVaultProxy} from "./IVaultProxy.sol";

interface IERC1155Vault is IERC1155, IERC1155MetadataURI, IIsSerialized, IVaultProxy {
    // Minting functionality
    function mintWithSerial(address to, uint256 id, uint256 amount, bytes calldata serialNumberData)
        external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    // URI management
    function setURI(string calldata newuri) external;

    // Serial number management
    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256);
    function getFirstSerialByOwner(address owner, uint256 tokenId)
        external
        view
        returns (uint256);
    function getOwnerOfSerial(uint256 serialNumber) external view returns (address);
    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256);

    // Versioning
    function version() external pure returns (string memory);

    // Diamond integration
    function diamond() external view returns (address);
}
