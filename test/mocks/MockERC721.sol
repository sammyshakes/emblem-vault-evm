// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/IERC721.sol";
import "../../src/interfaces/IERC165.sol";
import "../../src/interfaces/IIsSerialized.sol";

contract MockERC721 is IERC165, IERC721, IIsSerialized {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;

    // Serial number mappings
    mapping(uint256 => uint256) private _tokenIdToSerial;
    mapping(uint256 => uint256) private _serialToTokenId;
    mapping(address => mapping(uint256 => uint256[])) private _ownerTokenSerials;
    mapping(uint256 => address) private _serialOwners;
    uint256 private _nextSerial = 1;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IIsSerialized).interfaceId || interfaceId == 0x80ac58cd; // ERC721 interface ID
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not token owner or approved for all"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(msg.sender != operator, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function mint(address to, uint256 tokenId, string calldata uri, string calldata) external override {
        _mint(to, tokenId);
        _tokenURIs[tokenId] = uri;

        // Create serial number
        uint256 serialNumber = _nextSerial++;
        _tokenIdToSerial[tokenId] = serialNumber;
        _serialToTokenId[serialNumber] = tokenId;
        _ownerTokenSerials[to][tokenId].push(serialNumber);
        _serialOwners[serialNumber] = to;
    }

    function burn(uint256 tokenId) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    // IIsSerialized Implementation
    function isSerialized() external pure override returns (bool) {
        return true;
    }

    function getSerial(uint256 tokenId, uint256 index) external view override returns (uint256) {
        address owner = ownerOf(tokenId);
        require(index < _ownerTokenSerials[owner][tokenId].length, "Invalid index");
        return _ownerTokenSerials[owner][tokenId][index];
    }

    function getFirstSerialByOwner(address owner, uint256 tokenId) external view override returns (uint256) {
        require(_ownerTokenSerials[owner][tokenId].length > 0, "No serials found");
        return _ownerTokenSerials[owner][tokenId][0];
    }

    function getOwnerOfSerial(uint256 serialNumber) external view override returns (address) {
        return _serialOwners[serialNumber];
    }

    function getSerialByOwnerAtIndex(address owner, uint256 tokenId, uint256 index)
        external
        view
        override
        returns (uint256)
    {
        require(index < _ownerTokenSerials[owner][tokenId].length, "Invalid index");
        return _ownerTokenSerials[owner][tokenId][index];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) external view override returns (uint256) {
        return _serialToTokenId[serialNumber];
    }

    function isOverloadSerial() external pure override returns (bool) {
        return false;
    }

    // Internal functions
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenURIs[tokenId];

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

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        // Update serial number ownership
        uint256 serialNumber = _tokenIdToSerial[tokenId];
        _serialOwners[serialNumber] = to;
        _ownerTokenSerials[to][tokenId].push(serialNumber);

        // Remove serial from previous owner
        uint256[] storage fromSerials = _ownerTokenSerials[from][tokenId];
        for (uint256 i = 0; i < fromSerials.length; i++) {
            if (fromSerials[i] == serialNumber) {
                fromSerials[i] = fromSerials[fromSerials.length - 1];
                fromSerials.pop();
                break;
            }
        }

        emit Transfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: invalid token ID");
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
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}
