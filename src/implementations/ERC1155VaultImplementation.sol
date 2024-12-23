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
 * @notice Implementation of the ERC1155 vault token with optimized serial number tracking
 * @dev Implements ERC1155 with supply tracking and gas optimizations
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
    error ExternalSerialNumbersDisabled();
    error UseExternalSerialNumbers();
    error InvalidSerialNumber();
    error SerialNumberAlreadyUsed();
    error SerialNumberDuplicate();
    error InvalidSerialArraysLength();
    error InvalidSerialNumbersCount();
    error InsufficientSerialNumbers();
    error NoSerialsFound();
    error InvalidIndex();

    // ------------------------------------------------------------------------
    // Storage
    // ------------------------------------------------------------------------
    bool public overloadSerial;
    uint256 private _nextSerial;

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
    function initialize(string calldata uri_) public initializer {
        __ERC1155_init(uri_);
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __Ownable_init(msg.sender);

        _nextSerial = 1; // Start serial numbers at 1
        overloadSerial = true; // Default to external serial numbers
    }

    function setURI(string calldata newuri) public onlyOwner {
        _setURI(newuri);
    }

    // ------------------------------------------------------------------------
    // Minting (Auto vs. External Serial)
    // ------------------------------------------------------------------------
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external onlyOwner {
        // If we're in "external" serial mode, revert
        if (overloadSerial) {
            revert UseExternalSerialNumbers();
        }
        // This just does a normal ERC1155 mint (auto-serials handled in _updateMint)
        _mint(to, id, amount, data);
    }

    function mintWithSerial(address to, uint256 id, uint256 amount, bytes calldata serialNumberData)
        external
        onlyOwner
    {
        // Must be in external mode
        if (!overloadSerial) revert ExternalSerialNumbersDisabled();

        // Decode and validate
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

    function _mintWithSerials(
        address to,
        uint256 id,
        uint256 amount,
        uint256[] memory serialNumbers
    ) internal {
        // 1) Validate each serial (nonzero, not used)
        // 2) Sort them in ascending order
        // 3) Check adjacent duplicates
        // 4) Assign

        // 1) Basic checks
        for (uint256 i = 0; i < amount;) {
            uint256 serial = serialNumbers[i];
            if (serial == 0) revert InvalidSerialNumber();
            if (_serialOwners[serial] != address(0)) revert SerialNumberAlreadyUsed();
            unchecked {
                ++i;
            }
        }

        // 2) Sort: You can implement a small in-memory sort (e.g., quicksort or insertion sort).
        // For brevity, here's an insertion sort. If your arrays are large, consider a more efficient approach.
        for (uint256 i = 1; i < amount;) {
            uint256 key = serialNumbers[i];
            uint256 j = i;
            while (j > 0 && serialNumbers[j - 1] > key) {
                serialNumbers[j] = serialNumbers[j - 1];
                unchecked {
                    --j;
                }
            }
            serialNumbers[j] = key;
            unchecked {
                ++i;
            }
        }

        // 3) Check adjacent duplicates
        for (uint256 i = 1; i < amount;) {
            if (serialNumbers[i] == serialNumbers[i - 1]) revert SerialNumberDuplicate();
            unchecked {
                ++i;
            }
        }

        // 4) Commit to storage
        uint256[] storage ownerSerials = _ownerTokenSerials[to][id];
        uint256 startIndex = ownerSerials.length;

        for (uint256 i = 0; i < amount;) {
            uint256 serialNumber = serialNumbers[i];
            _tokenSerials[id][startIndex + i] = serialNumber;
            _serialToTokenId[serialNumber] = id;
            _serialOwners[serialNumber] = to;
            ownerSerials.push(serialNumber);

            emit SerialNumberAssigned(id, serialNumber);
            unchecked {
                ++i;
            }
        }

        // Finally do ERC1155 mint
        _mint(to, id, amount, "");
    }

    // ------------------------------------------------------------------------
    // Batch Minting
    // ------------------------------------------------------------------------
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyOwner {
        // If "external" mode is off, just do normal ERC1155 mintBatch
        if (!overloadSerial) {
            _mintBatch(to, ids, amounts, data);
            return;
        }

        // data => array of bytes => each bytes decodes to array of uint256 serialNumbers
        bytes[] memory serialArrays = abi.decode(data, (bytes[]));
        if (serialArrays.length != ids.length) revert InvalidSerialArraysLength();

        // 1) Read all serials into memory, check usage & zero
        // 2) Flatten them into single array, sort, check cross-duplicates
        // 3) Assign each batch
        uint256[][] memory allSerialNumbers = new uint256[][](ids.length);
        uint256 totalSerials;

        // Step 1: decode each batch, quick check
        for (uint256 i = 0; i < ids.length;) {
            allSerialNumbers[i] = abi.decode(serialArrays[i], (uint256[]));
            if (allSerialNumbers[i].length != amounts[i]) revert InvalidSerialNumbersCount();
            totalSerials += amounts[i];
            unchecked {
                ++i;
            }
        }

        // We'll gather everything into a single array for cross-duplicate checks
        uint256[] memory allSerialsFlat = new uint256[](totalSerials);
        uint256 currentIndex;

        // Step 2a: check zero or used
        for (uint256 i = 0; i < ids.length;) {
            uint256[] memory batchSerials = allSerialNumbers[i];
            uint256 amt = amounts[i];

            for (uint256 j = 0; j < amt;) {
                uint256 serial = batchSerials[j];
                if (serial == 0) revert InvalidSerialNumber();
                if (_serialOwners[serial] != address(0)) revert SerialNumberAlreadyUsed();

                // Insert into flat array
                allSerialsFlat[currentIndex] = serial;
                unchecked {
                    ++currentIndex;
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        // Step 2b: Sort the entire array of all serials
        // For large arrays, consider a more efficient sort.
        // This is an insertion sort for brevity.
        for (uint256 i = 1; i < totalSerials;) {
            uint256 key = allSerialsFlat[i];
            uint256 j = i;
            while (j > 0 && allSerialsFlat[j - 1] > key) {
                allSerialsFlat[j] = allSerialsFlat[j - 1];
                unchecked {
                    --j;
                }
            }
            allSerialsFlat[j] = key;
            unchecked {
                ++i;
            }
        }

        // Step 2c: Check cross duplicates
        for (uint256 i = 1; i < totalSerials;) {
            if (allSerialsFlat[i] == allSerialsFlat[i - 1]) revert SerialNumberDuplicate();
            unchecked {
                ++i;
            }
        }

        // Step 3: Assign serials to storage & actually mint
        for (uint256 i = 0; i < ids.length;) {
            uint256 id = ids[i];
            uint256 amt = amounts[i];
            uint256[] memory batchSerials = allSerialNumbers[i];

            uint256[] storage ownerSerials = _ownerTokenSerials[to][id];
            uint256 startIdx = ownerSerials.length;

            // No need to re-sort each batch here, we only care about final assignment
            for (uint256 j = 0; j < amt;) {
                uint256 serialNumber = batchSerials[j];
                _tokenSerials[id][startIdx + j] = serialNumber;
                _serialToTokenId[serialNumber] = id;
                _serialOwners[serialNumber] = to;
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

        // Perform the actual minting after all serial numbers are assigned
        _mintBatch(to, ids, amounts, "");
    }

    // ------------------------------------------------------------------------
    // Overridden _update => splitted into _updateMint, _updateBurn, _updateTransfer
    // ------------------------------------------------------------------------
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._update(from, to, ids, values);

        // If "auto" mode mint => from=0, not external
        if (from == address(0) && to != address(0) && !overloadSerial) {
            _updateMint(to, ids, values);
        }
        // If burn => to=0
        else if (to == address(0) && from != address(0)) {
            _updateBurn(from, ids, values);
        }
        // If transfer => both non-zero
        else if (from != address(0) && to != address(0)) {
            _updateTransfer(from, to, ids, values);
        }
    }

    function _updateMint(address to, uint256[] memory ids, uint256[] memory values) private {
        // Automatic (internal) serial assignment
        uint256 len = ids.length;
        for (uint256 i = 0; i < len;) {
            uint256 id = ids[i];
            uint256 amount = values[i];

            uint256[] storage ownerSerials = _ownerTokenSerials[to][id];
            uint256 startIndex = ownerSerials.length;

            uint256[] memory newSerials = new uint256[](amount);
            for (uint256 j = 0; j < amount;) {
                uint256 serialNumber = _nextSerial;
                unchecked {
                    ++_nextSerial;
                }

                newSerials[j] = serialNumber;
                _tokenSerials[id][startIndex + j] = serialNumber;
                _serialToTokenId[serialNumber] = id;
                _serialOwners[serialNumber] = to;
                ownerSerials.push(serialNumber);

                unchecked {
                    ++j;
                }
            }
            emit BatchSerialNumbersAssigned(id, newSerials);
            unchecked {
                ++i;
            }
        }
    }

    function _updateBurn(address from, uint256[] memory ids, uint256[] memory values) private {
        // Burn from the END of the array (swap-and-pop style) to avoid shifting costs.
        uint256 len = ids.length;
        for (uint256 i = 0; i < len;) {
            uint256 id = ids[i];
            uint256 amount = values[i];

            uint256[] storage serials = _ownerTokenSerials[from][id];
            uint256 serialCount = serials.length;

            if (serialCount < amount) revert InsufficientSerialNumbers();

            for (uint256 j = 0; j < amount;) {
                // Take last index
                uint256 idx = serials.length - 1;
                uint256 serialNumber = serials[idx];

                // Delete from storage
                delete _serialOwners[serialNumber];
                delete _serialToTokenId[serialNumber];
                delete _tokenSerials[id][idx];

                serials.pop(); // Remove from array end
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

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

            // Move from end of "fromSerials" to "toSerials"
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
    // URI
    // ------------------------------------------------------------------------
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(tokenId);
        return string(abi.encodePacked(baseURI, tokenId.toString()));
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

    function isOverloadSerial() external view returns (bool) {
        return overloadSerial;
    }

    function toggleOverloadSerial() external onlyOwner {
        overloadSerial = !overloadSerial;
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
        return "2.0.0";
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
