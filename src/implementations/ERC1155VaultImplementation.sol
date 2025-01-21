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
 * @title  ERC1155VaultImplementation
 * @notice An upgradeable ERC1155-based vault contract that supports token "serial numbers."
 * @dev    Integrates with a Diamond proxy architecture, restricting certain calls to the diamond address.
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
    /// @notice Thrown when attempting to mint or manage a token without providing or using valid external serial numbers.
    error UseExternalSerialNumbers();
    /// @notice Thrown if a provided serial number is zero or otherwise invalid.
    error InvalidSerialNumber();
    /// @notice Thrown when attempting to mint with a serial number that is already assigned to another token.
    error SerialNumberAlreadyUsed();
    /// @notice Thrown if a duplicate serial number appears in a single minting or batch process.
    error SerialNumberDuplicate();
    /// @notice Thrown if the length of serial arrays doesn't match the length of token IDs or amounts.
    error InvalidSerialArraysLength();
    /// @notice Thrown if the number of serial numbers provided does not match the intended mint amount.
    error InvalidSerialNumbersCount();
    /// @notice Thrown if the user attempts to burn or transfer more tokens than they have serials for.
    error InsufficientSerialNumbers();
    /// @notice Thrown if no serials are found when at least one is expected.
    error NoSerialsFound();
    /// @notice Thrown if an index is out of bounds in an array-based lookup.
    error InvalidIndex();
    /// @notice Thrown when a function that must be called by the diamond is called by a non-diamond address.
    error NotDiamond();

    // ------------------------------------------------------------------------
    // Storage
    // ------------------------------------------------------------------------

    /// @notice The address of the diamond contract (must pass `onlyDiamond` checks).
    address private _diamondAddress;

    /// @dev Modifier restricting calls to only the diamond address.
    modifier onlyDiamond() {
        if (msg.sender != _diamondAddress) {
            revert NotDiamond();
        }
        _;
    }

    /**
     * @dev Maps a token ID to another mapping of (index => serialNumber).
     *      This allows retrieval of serials belonging to a specific token ID.
     */
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenSerials;

    /**
     * @dev Maps a serial number to the token ID that holds it.
     */
    mapping(uint256 => uint256) private _serialToTokenId;

    /**
     * @dev Maps an owner address + token ID to an array of serial numbers owned by that address.
     *      Each token ID can have multiple serial numbers under the same owner.
     */
    mapping(address => mapping(uint256 => uint256[])) private _ownerTokenSerials;

    /**
     * @dev Maps a serial number to its current owner address.
     */
    mapping(uint256 => address) private _serialOwners;

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------
    /**
     * @notice Emitted when a new serial number is assigned to a token.
     * @param tokenId The ID of the token to which the serial is assigned.
     * @param serialNumber The assigned serial number.
     */
    event SerialNumberAssigned(uint256 indexed tokenId, uint256 indexed serialNumber);

    /**
     * @notice Emitted when multiple serial numbers are assigned in one batch operation.
     * @param tokenId The ID of the token that the batch of serial numbers belongs to.
     * @param serialNumbers The array of serial numbers that were assigned.
     */
    event BatchSerialNumbersAssigned(uint256 indexed tokenId, uint256[] serialNumbers);

    // ------------------------------------------------------------------------
    // Constructor (Disabled Initializers)
    // ------------------------------------------------------------------------
    /**
     * @notice Disables initializers on deployment to prevent misuse.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ------------------------------------------------------------------------
    // Initialization
    // ------------------------------------------------------------------------
    /**
     * @notice Initializes the upgradable ERC1155 vault contract.
     * @dev    Must only be called once. Invokes ERC1155, Burnable, Supply, and Ownable initializers.
     *         Sets the diamond address for restricted calls.
     * @param uri_ The base URI for all token IDs in this ERC1155 contract.
     * @param diamondAddress The diamond contract address for privileged calls.
     */
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
    /**
     * @notice Updates the base URI for the ERC1155 tokens.
     * @dev    Only callable by the diamond address.
     * @param newuri The new base URI to set.
     */
    function setURI(string calldata newuri) public onlyDiamond {
        _setURI(newuri);
    }

    /**
     * @notice Returns the metadata URI for a given token ID.
     * @dev    Appends the `tokenId` to the base URI. Can be overridden to customize the behavior.
     * @param tokenId The token ID to retrieve the URI for.
     * @return A string representing the full token metadata URI.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(tokenId);
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // ------------------------------------------------------------------------
    // Minting
    // ------------------------------------------------------------------------
    /**
     * @notice Mints a specified amount of `id` tokens to address `to`, with externally supplied serial numbers.
     * @dev    If `amount` > 1, `serialNumberData` should be an encoded array of serials. If `amount` == 1, `serialNumberData`
     *         should be a single serial number.
     *         - Reverts with `InvalidSerialNumbersCount()` if the provided serials array length doesn't match `amount`.
     *         - Reverts with `InvalidSerialNumber()` if a serial is 0.
     *         - Reverts with `SerialNumberAlreadyUsed()` if any serial is already owned.
     * @param to The address receiving the minted tokens.
     * @param id The token ID to mint.
     * @param amount The quantity of tokens to mint.
     * @param serialNumberData Encoded serial number(s) matching the `amount`.
     */
    function mintWithSerial(address to, uint256 id, uint256 amount, bytes calldata serialNumberData)
        external
        onlyDiamond
    {
        if (amount > 1) {
            // Decode an array of serials
            uint256[] memory serialNumbers = abi.decode(serialNumberData, (uint256[]));
            if (serialNumbers.length != amount) revert InvalidSerialNumbersCount();
            _mintWithSerials(to, id, amount, serialNumbers);
        } else {
            // Decode a single serial
            uint256 serialNumber = abi.decode(serialNumberData, (uint256));
            if (serialNumber == 0) revert InvalidSerialNumber();

            uint256[] memory singleton = new uint256[](1);
            singleton[0] = serialNumber;
            _mintWithSerials(to, id, 1, singleton);
        }
    }

    /**
     * @notice Internal function that assigns a set of serial numbers to a given address + tokenId, then mints the tokens.
     * @dev    Iterates over the provided `serialNumbers` and links each to `to`.
     *         - Reverts with `InvalidSerialNumber()` if any serial is 0.
     *         - Reverts with `SerialNumberAlreadyUsed()` if any serial is already owned.
     * @param to The address receiving the minted tokens.
     * @param id The token ID being minted.
     * @param amount The quantity to mint.
     * @param serialNumbers The array of serial numbers to assign.
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

            emit SerialNumberAssigned(id, serial);

            unchecked {
                ++i;
            }
        }

        // Actually mint the tokens
        _mint(to, id, amount, "");
    }

    /**
     * @notice Batch-mints multiple token IDs in one transaction, each with a set of serial numbers.
     * @dev    For each token ID in `ids`, there is a corresponding `amount` and a corresponding set
     *         of serials in `data`. Each set of serials must match its respective amount.
     * @param to The address receiving the minted tokens.
     * @param ids An array of token IDs to mint.
     * @param amounts An array of amounts corresponding to each token ID.
     * @param data Encoded data (bytes[]) where each entry in the array is itself an encoded array of serials.
     *
     * Reverts:
     * - `InvalidSerialArraysLength()` if `serialArrays.length != ids.length`.
     * - `InvalidSerialNumbersCount()` if the number of serials doesn’t match the amount for that token ID.
     * - `InvalidSerialNumber()` if any serial is 0.
     * - `SerialNumberAlreadyUsed()` if any serial is already owned.
     */
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
    /**
     * @notice Internal hook from ERC1155 and ERC1155Supply to handle updates when tokens are minted, burned, or transferred.
     * @dev    After calling super, it detects if the update is a burn (`to == address(0)`) or a transfer (both `from` and `to` non-zero).
     * @param from The address sending tokens (or zero address if minting).
     * @param to The address receiving tokens (or zero address if burning).
     * @param ids The token IDs involved in this operation.
     * @param values The amounts of each token ID being updated.
     */
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
     * @notice Handles the removal of serials when a burn operation is detected.
     * @dev    It removes the last serial numbers from the owner’s array.
     *         - Reverts with `InsufficientSerialNumbers()` if the user doesn’t have enough serials.
     * @param from The address from which tokens are being burned.
     * @param ids The token IDs being burned.
     * @param values The amounts of each token ID being burned.
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
     * @notice Handles updating serial ownership on a transfer operation.
     * @dev    Pops serials from `from`’s array and pushes them to `to`’s array.
     *         - Reverts with `InsufficientSerialNumbers()` if the user doesn’t have enough serials.
     * @param from The address sending the tokens.
     * @param to The address receiving the tokens.
     * @param ids The token IDs being transferred.
     * @param values The amounts of each token ID being transferred.
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
    /**
     * @notice Indicates this contract is serialized (i.e., supports tracking individual serials).
     * @return True, indicating serialization is used.
     */
    function isSerialized() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Retrieves a specific serial number from `_tokenSerials[tokenId][index]`.
     * @dev    Reverts if the serial number is zero.
     * @param tokenId The token ID that owns the serial.
     * @param index The index of the serial within that token ID’s serial mapping.
     * @return The serial number found at the given index.
     *
     * Reverts:
     * - `InvalidSerialNumber()` if the serial at that index is zero.
     */
    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256) {
        uint256 serial = _tokenSerials[tokenId][index];
        if (serial == 0) revert InvalidSerialNumber();
        return serial;
    }

    /**
     * @notice Retrieves the first serial number owned by `owner` for a given `tokenId`.
     * @dev    Useful for quick lookups when an owner might have multiple serials.
     * @param owner The address whose serial is being queried.
     * @param tokenId The token ID for which to retrieve the first serial.
     * @return The first serial number found in the owner's array for the given token ID.
     *
     * Reverts:
     * - `NoSerialsFound()` if the owner has zero serials for that token ID.
     */
    function getFirstSerialByOwner(address owner, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        uint256[] storage serials = _ownerTokenSerials[owner][tokenId];
        if (serials.length == 0) revert NoSerialsFound();
        return serials[0];
    }

    /**
     * @notice Retrieves the owner address of a specific serial number.
     * @param serialNumber The serial number to lookup.
     * @return The address that currently owns the given serial number.
     */
    function getOwnerOfSerial(uint256 serialNumber) external view returns (address) {
        return _serialOwners[serialNumber];
    }

    /**
     * @notice Retrieves a serial number by index from the array of serials owned by `owner` for `tokenId`.
     * @dev    Reverts if `index` is out of bounds.
     * @param owner The address that should own the serials.
     * @param tokenId The token ID of which we want to retrieve a serial.
     * @param index The index within the array of serials.
     * @return The serial number at the specified index.
     *
     * Reverts:
     * - `InvalidIndex()` if `index >= serials.length`.
     */
    function getSerialByOwnerAtIndex(address owner, uint256 tokenId, uint256 index)
        external
        view
        returns (uint256)
    {
        uint256[] storage serials = _ownerTokenSerials[owner][tokenId];
        if (index >= serials.length) revert InvalidIndex();
        return serials[index];
    }

    /**
     * @notice Retrieves the token ID associated with a given serial number.
     * @param serialNumber The serial number to lookup.
     * @return The token ID that the serial number is mapped to (or 0 if not mapped).
     */
    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256) {
        return _serialToTokenId[serialNumber];
    }

    // ------------------------------------------------------------------------
    // IERC165
    // ------------------------------------------------------------------------
    /**
     * @notice Indicates which interfaces this contract supports.
     * @dev    Combines ERC1155, IIsSerialized, IVaultProxy, and inherited supportsInterface.
     * @param interfaceId The interface ID to check.
     * @return True if the contract supports `interfaceId`, otherwise false.
     */
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
    /**
     * @notice Returns the current version string of this implementation.
     * @return A string representing the version, e.g. "1".
     */
    function version() external pure returns (string memory) {
        return "1";
    }

    // ------------------------------------------------------------------------
    // Diamond
    // ------------------------------------------------------------------------
    /**
     * @notice Returns the diamond address that has privileged access to certain functions.
     * @return The diamond contract address.
     */
    function diamond() external view returns (address) {
        return _diamondAddress;
    }

    // ------------------------------------------------------------------------
    // IVaultProxy Implementation
    // ------------------------------------------------------------------------
    /**
     * @notice Retrieves the beacon address from the known EIP-1967 beacon storage slot.
     * @return beaconAddress The address stored in the beacon slot.
     */
    function beacon() external view returns (address) {
        // EIP-1967 beacon slot
        bytes32 slot = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
        address beaconAddress;
        assembly {
            beaconAddress := sload(slot)
        }
        return beaconAddress;
    }

    /**
     * @notice Returns the current implementation address (this contract).
     * @return The address of this contract (the active implementation).
     */
    function implementation() external view returns (address) {
        return address(this);
    }
}
