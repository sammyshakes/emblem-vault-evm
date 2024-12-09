// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IHandlerCallback.sol";
import "../interfaces/IIsSerialized.sol";
import "../interfaces/IVaultProxy.sol";

/**
 * @title ERC1155VaultImplementation
 * @notice Implementation of the ERC1155 vault token with serial number tracking
 * @dev Implements ERC1155 with supply tracking and callback support
 * TODO: Discuss with team about royalties enforcement strategy
 */
contract ERC1155VaultImplementation is
    Initializable,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IIsSerialized,
    IVaultProxy
{
    // Serial number tracking
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenSerials; // tokenId => index => serialNumber
    mapping(uint256 => uint256) private _serialToTokenId; // serialNumber => tokenId
    mapping(address => mapping(uint256 => uint256[])) private _ownerTokenSerials; // owner => tokenId => serialNumbers[]
    mapping(uint256 => address) private _serialOwners; // serialNumber => owner
    uint256 private _nextSerial;

    // Registered contracts by type
    mapping(uint256 => address[]) public registeredOfType;

    // Events
    event SerialNumberAssigned(uint256 indexed tokenId, uint256 indexed serialNumber);
    event ContractRegistered(uint256 indexed contractType, address indexed contractAddress);
    event ContractUnregistered(uint256 indexed contractType, address indexed contractAddress);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory uri_) public initializer {
        __ERC1155_init(uri_);
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        _nextSerial = 1; // Start serial numbers at 1
    }

    /**
     * @notice Update the base URI for token metadata
     * @param newuri The new base URI to set
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function registerContract(uint256 contractType, address contractAddress) external onlyOwner {
        registeredOfType[contractType].push(contractAddress);
        emit ContractRegistered(contractType, contractAddress);
    }

    function unregisterContract(uint256 contractType, address contractAddress) external onlyOwner {
        address[] storage contracts = registeredOfType[contractType];
        for (uint256 i = 0; i < contracts.length; i++) {
            if (contracts[i] == contractAddress) {
                contracts[i] = contracts[contracts.length - 1];
                contracts.pop();
                emit ContractUnregistered(contractType, contractAddress);
                break;
            }
        }
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
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
            for (uint256 i = 0; i < ids.length; i++) {
                for (uint256 j = 0; j < values[i]; j++) {
                    uint256 serialNumber = _nextSerial++;
                    _tokenSerials[ids[i]][j] = serialNumber;
                    _serialToTokenId[serialNumber] = ids[i];
                    _ownerTokenSerials[to][ids[i]].push(serialNumber);
                    _serialOwners[serialNumber] = to;
                    emit SerialNumberAssigned(ids[i], serialNumber);
                }

                // Execute callbacks if called by handler
                if (registeredOfType[3].length > 0 && registeredOfType[3][0] == _msgSender()) {
                    IHandlerCallback(_msgSender()).executeCallbacks(
                        address(0), to, ids[i], IHandlerCallback.CallbackType.MINT
                    );
                }
            }
        }
        // Handle burning
        else if (to == address(0) && from != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256[] storage serials = _ownerTokenSerials[from][ids[i]];
                for (uint256 j = 0; j < values[i] && serials.length > 0; j++) {
                    uint256 serialNumber = serials[serials.length - 1];
                    delete _serialToTokenId[serialNumber];
                    delete _serialOwners[serialNumber];
                    serials.pop();
                }

                // Execute callbacks if handler is registered
                if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
                    IHandlerCallback(registeredOfType[3][0]).executeCallbacks(
                        _msgSender(), address(0), ids[i], IHandlerCallback.CallbackType.BURN
                    );
                }
            }
        }
        // Handle transfers
        else if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256[] storage fromSerials = _ownerTokenSerials[from][ids[i]];
                for (uint256 j = 0; j < values[i] && fromSerials.length > 0; j++) {
                    uint256 serialNumber = fromSerials[fromSerials.length - 1];
                    fromSerials.pop();
                    _ownerTokenSerials[to][ids[i]].push(serialNumber);
                    _serialOwners[serialNumber] = to;
                }
            }
        }
    }

    // IIsSerialized Implementation
    function isSerialized() external pure returns (bool) {
        return true;
    }

    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256) {
        require(_tokenSerials[tokenId][index] != 0, "Invalid serial");
        return _tokenSerials[tokenId][index];
    }

    function getFirstSerialByOwner(address owner, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        require(_ownerTokenSerials[owner][tokenId].length > 0, "No serials found");
        return _ownerTokenSerials[owner][tokenId][0];
    }

    function getOwnerOfSerial(uint256 serialNumber) external view returns (address) {
        return _serialOwners[serialNumber];
    }

    function getSerialByOwnerAtIndex(address owner, uint256 tokenId, uint256 index)
        external
        view
        returns (uint256)
    {
        require(index < _ownerTokenSerials[owner][tokenId].length, "Invalid index");
        return _ownerTokenSerials[owner][tokenId][index];
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
