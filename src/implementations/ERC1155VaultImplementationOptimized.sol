// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IIsSerialized.sol";
import "../interfaces/IVaultProxy.sol";

/**
 * @title ERC1155VaultImplementationOptimized
 * @notice Implementation of the ERC1155 vault token with targeted gas optimizations
 * @dev Implements ERC1155 with supply tracking and focused optimizations
 */
contract ERC1155VaultImplementationOptimized is
    Initializable,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IIsSerialized,
    IVaultProxy
{
    // Maintain original storage layout for compatibility
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenSerials; // tokenId => index => serialNumber
    mapping(uint256 => uint256) private _serialToTokenId; // serialNumber => tokenId
    mapping(address => mapping(uint256 => uint256[])) private _ownerTokenSerials; // owner => tokenId => serialNumbers[]
    mapping(uint256 => address) private _serialOwners; // serialNumber => owner
    uint256 private _nextSerial;

    // Events
    event SerialNumberAssigned(uint256 indexed tokenId, uint256 indexed serialNumber);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata uri_) public initializer {
        __ERC1155_init(uri_);
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        _nextSerial = 1; // Start serial numbers at 1
    }

    function setURI(string calldata newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external onlyOwner {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._update(from, to, ids, values);

        // Handle minting
        if (from == address(0) && to != address(0)) {
            uint256 idsLength = ids.length;
            for (uint256 i = 0; i < idsLength;) {
                uint256 id = ids[i];
                uint256 amount = values[i];
                uint256[] storage ownerSerials = _ownerTokenSerials[to][id];

                for (uint256 j = 0; j < amount;) {
                    uint256 serialNumber = _nextSerial;
                    unchecked {
                        _nextSerial++;
                    }

                    _tokenSerials[id][j] = serialNumber;
                    _serialToTokenId[serialNumber] = id;
                    ownerSerials.push(serialNumber);
                    _serialOwners[serialNumber] = to;

                    emit SerialNumberAssigned(id, serialNumber);

                    unchecked {
                        ++j;
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }
        // Handle burning
        else if (to == address(0) && from != address(0)) {
            uint256 idsLength = ids.length;
            for (uint256 i = 0; i < idsLength;) {
                uint256[] storage serials = _ownerTokenSerials[from][ids[i]];
                uint256 amount = values[i];
                uint256 serialsLength = serials.length;

                for (uint256 j = 0; j < amount && serialsLength > 0;) {
                    uint256 serialNumber = serials[serialsLength - 1];
                    delete _serialToTokenId[serialNumber];
                    delete _serialOwners[serialNumber];
                    serials.pop();

                    unchecked {
                        ++j;
                        --serialsLength;
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }
        // Handle transfers
        else if (from != address(0) && to != address(0)) {
            uint256 idsLength = ids.length;
            for (uint256 i = 0; i < idsLength;) {
                uint256 id = ids[i];
                uint256[] storage fromSerials = _ownerTokenSerials[from][id];
                uint256[] storage toSerials = _ownerTokenSerials[to][id];
                uint256 amount = values[i];
                uint256 fromLength = fromSerials.length;

                for (uint256 j = 0; j < amount && fromLength > 0;) {
                    uint256 serialNumber = fromSerials[fromLength - 1];
                    fromSerials.pop();
                    toSerials.push(serialNumber);
                    _serialOwners[serialNumber] = to;

                    unchecked {
                        ++j;
                        --fromLength;
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    // IIsSerialized Implementation
    function isSerialized() external pure returns (bool) {
        return true;
    }

    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256) {
        uint256 serial = _tokenSerials[tokenId][index];
        require(serial != 0, "Invalid serial");
        return serial;
    }

    function getFirstSerialByOwner(address owner, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        uint256[] storage serials = _ownerTokenSerials[owner][tokenId];
        require(serials.length > 0, "No serials found");
        return serials[0];
    }

    function getOwnerOfSerial(uint256 serialNumber) external view returns (address) {
        return _serialOwners[serialNumber];
    }

    function getSerialByOwnerAtIndex(address owner, uint256 tokenId, uint256 index)
        external
        view
        returns (uint256)
    {
        uint256[] storage serials = _ownerTokenSerials[owner][tokenId];
        require(index < serials.length, "Invalid index");
        return serials[index];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256) {
        return _serialToTokenId[serialNumber];
    }

    function isOverloadSerial() external pure returns (bool) {
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IIsSerialized).interfaceId
            || interfaceId == type(IVaultProxy).interfaceId || super.supportsInterface(interfaceId);
    }

    function version() external pure returns (string memory) {
        return "2.0.0";
    }

    // IVaultProxy Implementation
    function beacon() external view returns (address) {
        // Get the beacon slot from EIP-1967
        bytes32 slot = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
        address beaconAddress;
        assembly {
            beaconAddress := sload(slot)
        }
        return beaconAddress;
    }

    function implementation() external view returns (address) {
        return address(this);
    }
}
