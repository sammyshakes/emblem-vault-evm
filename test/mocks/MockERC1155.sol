// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/IERC1155.sol";
import "../../src/interfaces/IERC165.sol";
import "../../src/interfaces/IIsSerialized.sol";

contract MockERC1155 is IERC165, IERC1155, IIsSerialized {
    // Token data
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _uri;

    // Serial number data
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenSerials; // tokenId => index => serialNumber
    mapping(uint256 => uint256) private _serialToTokenId; // serialNumber => tokenId
    mapping(address => mapping(uint256 => uint256[])) private _ownerTokenSerials; // owner => tokenId => serialNumbers[]
    mapping(uint256 => address) private _serialOwners; // serialNumber => owner
    uint256 private _nextSerial = 1;

    constructor(string memory uri_) {
        _uri = uri_;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1155).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IIsSerialized).interfaceId;
    }

    function uri(uint256) public view virtual returns (string memory) {
        return _uri;
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        virtual
        override
    {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function mint(address to, uint256 id, uint256 amount) public virtual override {
        require(to != address(0), "ERC1155: mint to the zero address");

        _balances[id][to] += amount;

        // Create serial numbers
        for (uint256 i = 0; i < amount; i++) {
            uint256 serialNumber = _nextSerial++;
            _tokenSerials[id][i] = serialNumber;
            _serialToTokenId[serialNumber] = id;
            _ownerTokenSerials[to][id].push(serialNumber);
            _serialOwners[serialNumber] = to;
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function mintWithSerial(address to, uint256 id, uint256 amount, bytes calldata serialData)
        public
        virtual
        override
    {
        mint(to, id, amount);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes[] calldata serialNumbers)
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

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

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    function burn(address from, uint256 id, uint256 value) public virtual override {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not token owner or approved"
        );

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= value, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - value;
        }

        // Remove serial numbers
        uint256[] storage serials = _ownerTokenSerials[from][id];
        for (uint256 i = 0; i < value && serials.length > 0; i++) {
            uint256 serialNumber = serials[serials.length - 1];
            delete _serialToTokenId[serialNumber];
            delete _serialOwners[serialNumber];
            serials.pop();
        }

        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function burnBatch(address from, uint256[] memory ids, uint256[] memory values) public virtual override {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not token owner or approved"
        );
        require(ids.length == values.length, "ERC1155: ids and values length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 value = values[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= value, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - value;
            }

            // Remove serial numbers
            uint256[] storage serials = _ownerTokenSerials[from][id];
            for (uint256 j = 0; j < value && serials.length > 0; j++) {
                uint256 serialNumber = serials[serials.length - 1];
                delete _serialToTokenId[serialNumber];
                delete _serialOwners[serialNumber];
                serials.pop();
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, values);
    }

    // IIsSerialized Implementation
    function isSerialized() external pure override returns (bool) {
        return true;
    }

    function getSerial(uint256 tokenId, uint256 index) external view override returns (uint256) {
        require(index < _ownerTokenSerials[msg.sender][tokenId].length, "Invalid index");
        return _ownerTokenSerials[msg.sender][tokenId][index];
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

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        internal
        virtual
    {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = msg.sender;

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
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
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
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
    }
}
