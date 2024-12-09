// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IHandlerCallback.sol";
import "../interfaces/IIsSerialized.sol";
import "../interfaces/IVaultProxy.sol";

/**
 * @title ERC721VaultImplementation
 * @notice Implementation of the ERC721 vault token with serial number tracking
 * @dev Implements ERC721 with enumerable extension and callback support
 * TODO: Discuss with team about royalties enforcement strategy
 */
contract ERC721VaultImplementation is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IIsSerialized,
    IVaultProxy
{
    // Storage
    mapping(uint256 => uint256) internal _externalTokenIdMap; // tokenId >> externalTokenId
    string private _baseTokenURI;

    // Serial number tracking
    mapping(uint256 => uint256) private _tokenIdToSerial;
    mapping(uint256 => uint256) private _serialToTokenId;
    mapping(address => mapping(uint256 => uint256[])) private _ownerTokenSerials;
    mapping(uint256 => address) private _serialOwners;
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

    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Burnable_init();
        __ERC721Enumerable_init();
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        _baseTokenURI = "https://v2.emblemvault.io/meta/"; // Default base URI
        _nextSerial = 1; // Start serial numbers at 1
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

    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function mintMany(address[] memory to, uint256[] memory tokenId) external onlyOwner {
        require(to.length == tokenId.length, "Invalid input");
        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], tokenId[i]);
        }
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (address)
    {
        address from = super._update(to, tokenId, auth);

        // Handle minting
        if (from == address(0) && to != address(0)) {
            require(_externalTokenIdMap[tokenId] == 0, "External ID already minted");
            _externalTokenIdMap[tokenId] = tokenId;

            // Create and assign serial number
            uint256 serialNumber = _nextSerial++;
            _tokenIdToSerial[tokenId] = serialNumber;
            _serialToTokenId[serialNumber] = tokenId;
            _serialOwners[serialNumber] = to;
            _ownerTokenSerials[to][tokenId].push(serialNumber);

            emit SerialNumberAssigned(tokenId, serialNumber);

            // Execute callbacks if called by handler
            if (registeredOfType[3].length > 0 && registeredOfType[3][0] == _msgSender()) {
                IHandlerCallback(_msgSender()).executeCallbacks(
                    address(0), to, tokenId, IHandlerCallback.CallbackType.MINT
                );
            }
        }
        // Handle burning
        else if (to == address(0) && from != address(0)) {
            // Clear serial number data
            uint256 serialNumber = _tokenIdToSerial[tokenId];
            delete _tokenIdToSerial[tokenId];
            delete _serialToTokenId[serialNumber];
            delete _serialOwners[serialNumber];
            delete _externalTokenIdMap[tokenId];

            // Remove from owner's serial list
            uint256[] storage serials = _ownerTokenSerials[from][tokenId];
            for (uint256 i = 0; i < serials.length; i++) {
                if (serials[i] == serialNumber) {
                    serials[i] = serials[serials.length - 1];
                    serials.pop();
                    break;
                }
            }

            // Execute callbacks if handler is registered
            if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
                IHandlerCallback(registeredOfType[3][0]).executeCallbacks(
                    _msgSender(), address(0), tokenId, IHandlerCallback.CallbackType.BURN
                );
            }
        }
        // Handle transfers
        else if (from != address(0) && to != address(0)) {
            // Update serial number ownership
            uint256 serialNumber = _tokenIdToSerial[tokenId];
            _serialOwners[serialNumber] = to;
            _ownerTokenSerials[to][tokenId].push(serialNumber);

            // Remove from previous owner's serial list
            uint256[] storage serials = _ownerTokenSerials[from][tokenId];
            for (uint256 i = 0; i < serials.length; i++) {
                if (serials[i] == serialNumber) {
                    serials[i] = serials[serials.length - 1];
                    serials.pop();
                    break;
                }
            }
        }

        return from;
    }

    // Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // IIsSerialized Implementation
    function isSerialized() external pure returns (bool) {
        return true;
    }

    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256) {
        address owner = ownerOf(tokenId);
        require(index < _ownerTokenSerials[owner][tokenId].length, "Invalid index");
        return _ownerTokenSerials[owner][tokenId][index];
    }

    function getFirstSerialByOwner(address owner, uint256 tokenId) external view returns (uint256) {
        require(_ownerTokenSerials[owner][tokenId].length > 0, "No serials found");
        return _ownerTokenSerials[owner][tokenId][0];
    }

    function getOwnerOfSerial(uint256 serialNumber) external view returns (address) {
        return _serialOwners[serialNumber];
    }

    function getSerialByOwnerAtIndex(address owner, uint256 tokenId, uint256 index) external view returns (uint256) {
        require(index < _ownerTokenSerials[owner][tokenId].length, "Invalid index");
        return _ownerTokenSerials[owner][tokenId][index];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256) {
        return _serialToTokenId[serialNumber];
    }

    function isOverloadSerial() external pure returns (bool) {
        return false;
    }

    // External token ID mapping
    function getInternalTokenId(uint256 tokenId) external view returns (uint256) {
        return _externalTokenIdMap[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IIsSerialized).interfaceId || interfaceId == type(IVaultProxy).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function version() external pure returns (string memory) {
        return "2.0.0";
    }

    function _increaseBalance(address account, uint128 value)
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._increaseBalance(account, value);
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
