// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IERC1155.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IIsSerialized.sol";

/**
 * @title ERC1155VaultImplementation
 * @notice Implementation contract for ERC1155 vaults with serial number support
 * @dev Implements IERC1155, IIsSerialized, and IERC165 interfaces
 */
contract ERC1155VaultImplementation {
    // Storage slots follow EIP-1967 pattern to avoid clashes
    bytes32 private constant INITIALIZED_SLOT = keccak256("erc1155.vault.initialized");
    bytes32 private constant OWNER_SLOT = keccak256("erc1155.vault.owner");

    // String storage
    string private _uri;

    // Mappings for ERC1155 functionality
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mappings for serial number functionality
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenSerials; // tokenId => index => serialNumber
    mapping(uint256 => uint256) private _serialToTokenId; // serialNumber => tokenId
    mapping(address => mapping(uint256 => uint256[])) private _ownerTokenSerials; // owner => tokenId => serialNumbers[]
    mapping(uint256 => address) private _serialOwners; // serialNumber => owner
    uint256 private _nextSerial = 1;

    // Events
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    event Initialized(string uri, address owner);

    // Custom errors
    error AlreadyInitialized();
    error NotInitialized();
    error ZeroAddress();
    error NotOwner();
    error NotApproved();
    error InvalidBalance();
    error InvalidSerial();
    error LengthMismatch();

    modifier onlyInitialized() {
        if (!_getInitialized()) revert NotInitialized();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != _getOwner()) revert NotOwner();
        _;
    }

    /**
     * @notice Get the beacon address
     * @return The address of the beacon contract
     */
    function beacon() external view returns (address) {
        // This is called through the proxy, so we need to get the beacon from the proxy's storage
        // The proxy stores the beacon address in a specific slot defined by EIP-1967
        bytes32 slot = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
        address beaconAddress;
        assembly {
            beaconAddress := sload(slot)
        }
        return beaconAddress;
    }

    /**
     * @notice Initialize the vault
     * @param uri_ The base URI for token metadata
     */
    function initialize(string memory uri_) external {
        if (_getInitialized()) revert AlreadyInitialized();

        _uri = uri_;
        _setOwner(msg.sender);
        _setInitialized(true);

        emit Initialized(uri_, msg.sender);
    }

    /**
     * @notice Get the base URI
     */
    function uri(uint256) external view returns (string memory) {
        return _uri;
    }

    /**
     * @notice Check if interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC1155).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IIsSerialized).interfaceId;
    }

    /**
     * @notice Get balance of token for address
     */
    function balanceOf(address account, uint256 id) external view returns (uint256) {
        if (account == address(0)) revert ZeroAddress();
        return _balances[id][account];
    }

    /**
     * @notice Get balances for multiple token ids and addresses
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length) revert LengthMismatch();

        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = this.balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @notice Set approval for all tokens
     */
    function setApprovalForAll(address operator, bool approved) external {
        if (operator == msg.sender) revert("ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Check if operator is approved for all tokens
     */
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @notice Safe transfer of tokens
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert NotApproved();
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Safe batch transfer of tokens
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert NotApproved();
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice Mint tokens
     * @param to Address to mint to
     * @param id Token ID to mint
     * @param amount Amount to mint
     */
    function mint(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, "");
    }

    /**
     * @notice Batch mint tokens
     * @param to Address to mint to
     * @param ids Token IDs to mint
     * @param amounts Amounts to mint
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    /**
     * @notice Burn tokens
     * @param from Address to burn from
     * @param id Token ID to burn
     * @param amount Amount to burn
     */
    function burn(address from, uint256 id, uint256 amount) external {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert NotApproved();
        _burn(from, id, amount);
    }

    /**
     * @notice Batch burn tokens
     * @param from Address to burn from
     * @param ids Token IDs to burn
     * @param amounts Amounts to burn
     */
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert NotApproved();
        _burnBatch(from, ids, amounts);
    }

    // IIsSerialized Implementation
    function isSerialized() external pure returns (bool) {
        return true;
    }

    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256) {
        if (_tokenSerials[tokenId][index] == 0) revert InvalidSerial();
        return _tokenSerials[tokenId][index];
    }

    function getFirstSerialByOwner(address owner, uint256 tokenId) external view returns (uint256) {
        if (_ownerTokenSerials[owner][tokenId].length == 0) revert InvalidSerial();
        return _ownerTokenSerials[owner][tokenId][0];
    }

    function getOwnerOfSerial(uint256 serialNumber) external view returns (address) {
        return _serialOwners[serialNumber];
    }

    function getSerialByOwnerAtIndex(address owner, uint256 tokenId, uint256 index) external view returns (uint256) {
        if (index >= _ownerTokenSerials[owner][tokenId].length) revert InvalidSerial();
        return _ownerTokenSerials[owner][tokenId][index];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256) {
        return _serialToTokenId[serialNumber];
    }

    function isOverloadSerial() external pure returns (bool) {
        return false;
    }

    // Internal functions
    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal {
        if (to == address(0)) revert ZeroAddress();

        address operator = msg.sender;
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = id;
        amounts[0] = amount;

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) revert InvalidBalance();
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        // Transfer serial numbers
        uint256[] storage fromSerials = _ownerTokenSerials[from][id];
        for (uint256 i = 0; i < amount && fromSerials.length > 0; i++) {
            uint256 serialNumber = fromSerials[fromSerials.length - 1];
            fromSerials.pop();
            _ownerTokenSerials[to][id].push(serialNumber);
            _serialOwners[serialNumber] = to;
        }

        emit TransferSingle(operator, from, to, id, amount);
        _afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (ids.length != amounts.length) revert LengthMismatch();
        if (to == address(0)) revert ZeroAddress();

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) revert InvalidBalance();
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;

            // Transfer serial numbers
            uint256[] storage fromSerials = _ownerTokenSerials[from][id];
            for (uint256 j = 0; j < amount && fromSerials.length > 0; j++) {
                uint256 serialNumber = fromSerials[fromSerials.length - 1];
                fromSerials.pop();
                _ownerTokenSerials[to][id].push(serialNumber);
                _serialOwners[serialNumber] = to;
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        _afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
        if (to == address(0)) revert ZeroAddress();

        address operator = msg.sender;
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = id;
        amounts[0] = amount;

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;

        // Create serial numbers
        for (uint256 i = 0; i < amount; i++) {
            uint256 serialNumber = _nextSerial++;
            _tokenSerials[id][i] = serialNumber;
            _serialToTokenId[serialNumber] = id;
            _ownerTokenSerials[to][id].push(serialNumber);
            _serialOwners[serialNumber] = to;
        }

        emit TransferSingle(operator, address(0), to, id, amount);
        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
        if (to == address(0)) revert ZeroAddress();
        if (ids.length != amounts.length) revert LengthMismatch();

        address operator = msg.sender;

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];

            // Create serial numbers
            for (uint256 j = 0; j < amounts[i]; j++) {
                uint256 serialNumber = _nextSerial++;
                _tokenSerials[ids[i]][j] = serialNumber;
                _serialToTokenId[serialNumber] = ids[i];
                _ownerTokenSerials[to][ids[i]].push(serialNumber);
                _serialOwners[serialNumber] = to;
            }
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
    }

    function _burn(address from, uint256 id, uint256 amount) internal {
        if (from == address(0)) revert ZeroAddress();

        address operator = msg.sender;
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = id;
        amounts[0] = amount;

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) revert InvalidBalance();
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        // Remove serial numbers
        uint256[] storage serials = _ownerTokenSerials[from][id];
        for (uint256 i = 0; i < amount && serials.length > 0; i++) {
            uint256 serialNumber = serials[serials.length - 1];
            delete _serialToTokenId[serialNumber];
            delete _serialOwners[serialNumber];
            serials.pop();
        }

        emit TransferSingle(operator, from, address(0), id, amount);
        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal {
        if (from == address(0)) revert ZeroAddress();
        if (ids.length != amounts.length) revert LengthMismatch();

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) revert InvalidBalance();
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }

            // Remove serial numbers
            uint256[] storage serials = _ownerTokenSerials[from][id];
            for (uint256 j = 0; j < amount && serials.length > 0; j++) {
                uint256 serialNumber = serials[serials.length - 1];
                delete _serialToTokenId[serialNumber];
                delete _serialOwners[serialNumber];
                serials.pop();
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    // Storage getters and setters
    function _getInitialized() internal view returns (bool initialized_) {
        bytes32 slot = INITIALIZED_SLOT;
        assembly {
            initialized_ := sload(slot)
        }
    }

    function _setInitialized(bool initialized_) internal {
        bytes32 slot = INITIALIZED_SLOT;
        assembly {
            sstore(slot, initialized_)
        }
    }

    function _getOwner() internal view returns (address owner_) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            owner_ := sload(slot)
        }
    }

    function _setOwner(address owner_) internal {
        bytes32 slot = OWNER_SLOT;
        assembly {
            sstore(slot, owner_)
        }
    }
}
