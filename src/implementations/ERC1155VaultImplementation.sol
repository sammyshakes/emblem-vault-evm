// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IIsSerialized.sol";
import "../interfaces/IVaultProxy.sol";

/**
 * @title ERC1155VaultImplementation
 * @notice Implementation of the ERC1155 vault token
 */
contract ERC1155VaultImplementation is
    Initializable,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    OwnableUpgradeable,
    IIsSerialized,
    IVaultProxy
{
    using Strings for uint256;

    // ------------------------------------------------------------------------
    // Custom Errors
    // ------------------------------------------------------------------------
    error UseExternalSerialNumbers();
    error InvalidSerialNumber();
    error SerialNumberAlreadyUsed();
    error SerialNumberDuplicate();
    error InvalidSerialArraysLength();
    error InvalidSerialNumbersCount();
    error InsufficientSerialNumbers();

    error NoSerialsFound();
    error InvalidIndex();
    error NotDiamond();

    // ------------------------------------------------------------------------
    // Storage
    // ------------------------------------------------------------------------
    address private _diamondAddress;

    modifier onlyDiamond() {
        if (msg.sender != _diamondAddress) {
            revert NotDiamond();
        }
        _;
    }

    mapping(uint256 => mapping(uint256 => uint256)) private _tokenSerials; // tokenId => index => serialNumber
    mapping(uint256 => uint256) private _serialToTokenId; // serialNumber => tokenId
    mapping(address => mapping(uint256 => uint256[])) private _ownerTokenSerials; // owner => tokenId => serialNumbers[]
    mapping(uint256 => address) private _serialOwners; // serialNumber => owner

    // Events
    event SerialNumberAssigned(uint256 indexed tokenId, uint256 indexed serialNumber);
    event BatchSerialNumbersAssigned(uint256 indexed tokenId, uint256[] serialNumbers);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ------------------------------------------------------------------------
    // Initialization
    // ------------------------------------------------------------------------
    function initialize(string calldata uri_, address diamondAddress) public initializer {
        __ERC1155_init(uri_);
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __Ownable_init(msg.sender);
        _diamondAddress = diamondAddress;
    }

    // ------------------------------------------------------------------------
    // URI
    // ------------------------------------------------------------------------
    function setURI(string calldata newuri) public onlyDiamond {
        _setURI(newuri);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(tokenId);
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // ------------------------------------------------------------------------
    // Minting
    // ------------------------------------------------------------------------
    /**
     * @dev The function to mint tokens with externally supplied serial numbers
     *      - Single serial (amount=1) or array of serials (amount>1).
     */
    function mintWithSerial(address to, uint256 id, uint256 amount, bytes calldata serialNumberData)
        external
        onlyDiamond
    {
        if (amount > 1) {
            uint256[] memory serialNumbers = abi.decode(serialNumberData, (uint256[]));
            if (serialNumbers.length != amount) revert InvalidSerialNumbersCount();
            _mintWithSerials(to, id, amount, serialNumbers);
        } else {
            // Single-serial mint
            uint256 serialNumber = abi.decode(serialNumberData, (uint256));
            if (serialNumber == 0) revert InvalidSerialNumber();

            uint256[] memory singleton = new uint256[](1);
            singleton[0] = serialNumber;
            _mintWithSerials(to, id, 1, singleton);
        }
    }

    /**
     * @dev A single-pass approach that writes each serial to storage immediately.
     *      If a duplicate is encountered, the second pass will revert with SerialNumberAlreadyUsed().
     */
    function _mintWithSerials(
        address to,
        uint256 id,
        uint256 amount,
        uint256[] memory serialNumbers
    ) internal {
        uint256[] storage ownerSerials = _ownerTokenSerials[to][id];
        uint256 startIndex = ownerSerials.length;

        for (uint256 i = 0; i < amount;) {
            uint256 serial = serialNumbers[i];
            if (serial == 0) revert InvalidSerialNumber();
            if (_serialOwners[serial] != address(0)) revert SerialNumberAlreadyUsed();

            // Mark ownership
            _serialOwners[serial] = to;
            _serialToTokenId[serial] = id;
            _tokenSerials[id][startIndex + i] = serial;
            ownerSerials.push(serial);

            // emit SerialNumberAssigned(id, serial);
            unchecked {
                ++i;
            }
        }

        // Actually mint the tokens
        _mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyDiamond {
        bytes[] memory serialArrays = abi.decode(data, (bytes[]));
        if (serialArrays.length != ids.length) revert InvalidSerialArraysLength();

        for (uint256 i = 0; i < ids.length;) {
            uint256 id = ids[i];
            uint256 amt = amounts[i];
            uint256[] memory batchSerials = abi.decode(serialArrays[i], (uint256[]));

            if (batchSerials.length != amt) revert InvalidSerialNumbersCount();

            uint256[] storage ownerSerials = _ownerTokenSerials[to][id];
            uint256 startIdx = ownerSerials.length;

            for (uint256 j = 0; j < amt;) {
                uint256 serialNumber = batchSerials[j];
                if (serialNumber == 0) revert InvalidSerialNumber();
                if (_serialOwners[serialNumber] != address(0)) revert SerialNumberAlreadyUsed();

                // Mark ownership
                _serialOwners[serialNumber] = to;
                _serialToTokenId[serialNumber] = id;
                _tokenSerials[id][startIdx + j] = serialNumber;
                ownerSerials.push(serialNumber);

                emit SerialNumberAssigned(id, serialNumber);
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Perform actual mint
        _mintBatch(to, ids, amounts, "");
    }

    // ------------------------------------------------------------------------
    // Overridden _update => Burn / Transfer
    // ------------------------------------------------------------------------
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._update(from, to, ids, values);

        // Burn => to == address(0)
        if (to == address(0) && from != address(0)) {
            _updateBurn(from, ids, values);
        }
        // Transfer => both non-zero
        else if (from != address(0) && to != address(0)) {
            _updateTransfer(from, to, ids, values);
        }
    }

    /**
     * @dev Burn logic: remove serials from the end of the array
     */
    function _updateBurn(address from, uint256[] memory ids, uint256[] memory values) private {
        uint256 len = ids.length;
        for (uint256 i = 0; i < len;) {
            uint256 id = ids[i];
            uint256 amount = values[i];

            uint256[] storage serials = _ownerTokenSerials[from][id];
            uint256 serialCount = serials.length;

            if (serialCount < amount) revert InsufficientSerialNumbers();

            for (uint256 j = 0; j < amount;) {
                uint256 idx = serials.length - 1;
                uint256 serialNumber = serials[idx];

                // Delete from storage
                delete _serialOwners[serialNumber];
                delete _serialToTokenId[serialNumber];
                delete _tokenSerials[id][idx];

                serials.pop();
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Transfer logic: move serial from `from` to `to` by pop/push on their arrays
     */
    function _updateTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) private {
        uint256 len = ids.length;
        for (uint256 i = 0; i < len;) {
            uint256 id = ids[i];
            uint256 amount = values[i];

            uint256[] storage fromSerials = _ownerTokenSerials[from][id];
            uint256[] storage toSerials = _ownerTokenSerials[to][id];
            uint256 fromLength = fromSerials.length;

            if (fromLength < amount) revert InsufficientSerialNumbers();

            for (uint256 j = 0; j < amount;) {
                uint256 idx = fromSerials.length - 1;
                uint256 serialNumber = fromSerials[idx];
                fromSerials.pop();
                toSerials.push(serialNumber);
                _serialOwners[serialNumber] = to;

                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    // ------------------------------------------------------------------------
    // IIsSerialized Implementation
    // ------------------------------------------------------------------------
    function isSerialized() external pure returns (bool) {
        return true;
    }

    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256) {
        uint256 serial = _tokenSerials[tokenId][index];
        if (serial == 0) revert InvalidSerialNumber();
        return serial;
    }

    function getFirstSerialByOwner(address owner, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        uint256[] storage serials = _ownerTokenSerials[owner][tokenId];
        if (serials.length == 0) revert NoSerialsFound();
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
        if (index >= serials.length) revert InvalidIndex();
        return serials[index];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256) {
        return _serialToTokenId[serialNumber];
    }

    // ------------------------------------------------------------------------
    // IERC165
    // ------------------------------------------------------------------------
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

    // ------------------------------------------------------------------------
    // Version
    // ------------------------------------------------------------------------
    function version() external pure returns (string memory) {
        return "1";
    }

    // ------------------------------------------------------------------------
    // Diamond
    // ------------------------------------------------------------------------
    function diamond() external view returns (address) {
        return _diamondAddress;
    }

    // ------------------------------------------------------------------------
    // IVaultProxy Implementation
    // ------------------------------------------------------------------------
    function beacon() external view returns (address) {
        // EIP-1967 beacon slot
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
