// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IIsSerialized.sol";

/**
 * @title ERC721VaultImplementation
 * @notice Implementation contract for ERC721 vaults with serial number support
 * @dev Implements IERC721, IIsSerialized, and IERC165 interfaces
 */
contract ERC721VaultImplementation {
    // Storage slots follow EIP-1967 pattern to avoid clashes
    bytes32 private constant INITIALIZED_SLOT = keccak256("erc721.vault.initialized");
    bytes32 private constant OWNER_SLOT = keccak256("erc721.vault.owner");

    // String storage
    string private _name;
    string private _symbol;

    // Mappings for ERC721 functionality
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;

    // Mappings for serial number functionality
    mapping(uint256 => uint256) private _tokenIdToSerial;
    mapping(uint256 => uint256) private _serialToTokenId;
    mapping(address => mapping(uint256 => uint256[])) private _ownerTokenSerials;
    mapping(uint256 => address) private _serialOwners;
    uint256 private _nextSerial = 1;

    // Events from IERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Custom events
    event Initialized(string name, string symbol, address owner);

    // Custom errors
    error AlreadyInitialized();
    error NotInitialized();
    error ZeroAddress();
    error NotOwner();
    error NotApproved();
    error TokenNotFound();
    error InvalidSerial();

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
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     */
    function initialize(string memory name_, string memory symbol_) external {
        if (_getInitialized()) revert AlreadyInitialized();

        _name = name_;
        _symbol = symbol_;
        _setOwner(msg.sender);
        _nextSerial = 1; // Ensure serial numbers start at 1
        _setInitialized(true);

        emit Initialized(name_, symbol_, msg.sender);
    }

    /**
     * @notice Get the name of the token
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @notice Get the symbol of the token
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Check if interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IIsSerialized).interfaceId;
    }

    /**
     * @notice Get balance of an address
     */
    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    /**
     * @notice Get owner of a token
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenNotFound();
        return owner;
    }

    /**
     * @notice Approve an address to transfer a token
     */
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (to == owner) revert("ERC721: approval to current owner");
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert NotApproved();
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @notice Get approved address for a token
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @notice Set approval for all tokens
     */
    function setApprovalForAll(address operator, bool approved) external {
        if (operator == msg.sender) revert("ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Check if an operator is approved for all tokens
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @notice Transfer a token
     */
    function transferFrom(address from, address to, uint256 tokenId) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApproved();
        _transfer(from, to, tokenId);
    }

    /**
     * @notice Safely transfer a token
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Safely transfer a token with data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApproved();
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @notice Mint a new token
     * @param to Address to mint to
     * @param tokenId Token ID to mint
     */
    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    /**
     * @notice Burn a token
     * @param tokenId Token ID to burn
     */
    function burn(uint256 tokenId) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApproved();
        _burn(tokenId);
    }

    // IIsSerialized Implementation
    function isSerialized() external pure returns (bool) {
        return true;
    }

    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256) {
        address owner = ownerOf(tokenId);
        if (index >= _ownerTokenSerials[owner][tokenId].length) revert InvalidSerial();
        return _ownerTokenSerials[owner][tokenId][index];
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
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        if (!_exists(tokenId)) revert TokenNotFound();
        return _tokenApprovals[tokenId];
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert("ERC721: transfer to non ERC721Receiver implementer");
        }
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ZeroAddress();
        if (_exists(tokenId)) revert("ERC721: token already minted");

        // Update token ownership
        _balances[to] += 1;
        _owners[tokenId] = to;

        // Create and assign serial number
        uint256 serialNumber = _nextSerial++;
        require(serialNumber != 0, "ERC721: invalid serial");

        // Update serial number mappings
        _tokenIdToSerial[tokenId] = serialNumber;
        _serialToTokenId[serialNumber] = tokenId;
        _serialOwners[serialNumber] = to;
        _ownerTokenSerials[to][tokenId].push(serialNumber);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        _balances[owner] -= 1;
        delete _owners[tokenId];

        // Clear serial number data
        uint256 serialNumber = _tokenIdToSerial[tokenId];
        delete _tokenIdToSerial[tokenId];
        delete _serialToTokenId[serialNumber];
        delete _serialOwners[serialNumber];

        // Remove from owner's serial list
        uint256[] storage serials = _ownerTokenSerials[owner][tokenId];
        for (uint256 i = 0; i < serials.length; i++) {
            if (serials[i] == serialNumber) {
                serials[i] = serials[serials.length - 1];
                serials.pop();
                break;
            }
        }

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        if (ownerOf(tokenId) != from) revert("ERC721: transfer from incorrect owner");
        if (to == address(0)) revert ZeroAddress();

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        // Get the serial number and verify it exists
        uint256 serialNumber = _tokenIdToSerial[tokenId];
        if (serialNumber == 0) revert("ERC721: token has no serial");

        // Update token ownership first
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        // Update serial number ownership
        _serialOwners[serialNumber] = to;

        // Remove serial from previous owner
        uint256[] storage fromSerials = _ownerTokenSerials[from][tokenId];
        for (uint256 i = 0; i < fromSerials.length; i++) {
            if (fromSerials[i] == serialNumber) {
                fromSerials[i] = fromSerials[fromSerials.length - 1];
                fromSerials.pop();
                break;
            }
        }

        // Add serial to new owner
        _ownerTokenSerials[to][tokenId].push(serialNumber);

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert("ERC721: transfer to non ERC721Receiver implementer");
        }
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private
        returns (bool)
    {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

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

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}
