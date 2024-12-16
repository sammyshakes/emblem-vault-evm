// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "ERC721A-Upgradeable/ERC721AUpgradeable.sol";
import "ERC721A-Upgradeable/extensions/ERC721ABurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IVaultProxy.sol";

/**
 * @title ERC721VaultImplementationOptimized
 * @notice Gas-optimized implementation of the ERC721A vault token
 * @dev Implements ERC721A with additional gas optimizations
 */
contract ERC721VaultImplementationOptimized is
    Initializable,
    ERC721AUpgradeable,
    ERC721ABurnableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IVaultProxy
{
    // Constants for gas optimization
    bytes32 private constant BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
    string private constant DEFAULT_BASE_URI = "https://v2.emblemvault.io/meta/";
    uint256 private constant STARTING_TOKEN_ID = 1;

    // Storage
    mapping(uint256 => uint256) private _tokenIdMap; // tokenId >> externalTokenId
    string private _baseTokenURI;

    // Events
    event TokenMinted(
        address indexed to, uint256 indexed tokenId, uint256 indexed externalTokenId, bytes data
    );
    event TokenBurned(
        address indexed from, uint256 indexed tokenId, uint256 indexed externalTokenId, bytes data
    );
    event BaseURIUpdated(string newBaseURI);
    event DetailsUpdated(string name, string symbol);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata symbol_)
        public
        initializerERC721A
        initializer
    {
        __ERC721A_init(name_, symbol_);
        __ERC721ABurnable_init();
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        _baseTokenURI = DEFAULT_BASE_URI;
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mintSingle(to, tokenId, "");
    }

    function mintWithData(address to, uint256 tokenId, bytes calldata data) external onlyOwner {
        _mintSingle(to, tokenId, data);
    }

    function mintMany(address[] calldata to, uint256[] calldata tokenIds) external onlyOwner {
        uint256 length = to.length;
        require(length == tokenIds.length, "Invalid input");

        // Cache next token ID
        uint256 nextId = _nextTokenId();

        // Batch mint
        unchecked {
            for (uint256 i; i < length; ++i) {
                require(_tokenIdMap[tokenIds[i]] == 0, "External ID already minted");
                _tokenIdMap[tokenIds[i]] = nextId + i;
                _mint(to[i], 1);
                emit TokenMinted(to[i], nextId + i, tokenIds[i], "");
            }
        }
    }

    function burn(uint256 tokenId) public override {
        _burnWithData(tokenId, "");
    }

    function burnWithData(uint256 tokenId, bytes calldata data) public {
        _burnWithData(tokenId, data);
    }

    function _mintSingle(address to, uint256 externalId, bytes memory data) internal {
        require(_tokenIdMap[externalId] == 0, "External ID already minted");

        uint256 nextId = _nextTokenId();
        _tokenIdMap[externalId] = nextId;
        _mint(to, 1);

        emit TokenMinted(to, nextId, externalId, data);
    }

    function _burnWithData(uint256 tokenId, bytes memory data) internal {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "Not authorized");

        // Find external ID
        uint256 externalId;
        for (uint256 i = 1; i <= _nextTokenId(); i++) {
            if (_tokenIdMap[i] == tokenId) {
                externalId = i;
                break;
            }
        }

        delete _tokenIdMap[externalId];
        super.burn(tokenId);

        emit TokenBurned(_msgSender(), tokenId, externalId, data);
    }

    // Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    // External token ID mapping
    function getInternalTokenId(uint256 tokenId) external view returns (uint256) {
        return _tokenIdMap[tokenId];
    }

    function setDetails(string calldata name_, string calldata symbol_) external onlyOwner {
        ERC721AStorage.Layout storage layout = ERC721AStorage.layout();
        layout._name = name_;
        layout._symbol = symbol_;
        emit DetailsUpdated(name_, symbol_);
    }

    function supportsInterface(bytes4 id)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC165, IERC721AUpgradeable)
        returns (bool)
    {
        return id == type(IVaultProxy).interfaceId || id == bytes4(keccak256("ERC721A"))
            || super.supportsInterface(id);
    }

    function version() external pure returns (string memory) {
        return "15";
    }

    function interfaceId() external pure returns (bytes4) {
        return bytes4(keccak256("ERC721A"));
    }

    // IVaultProxy Implementation
    function beacon() external view returns (address beaconAddress) {
        assembly {
            beaconAddress := sload(BEACON_SLOT)
        }
    }

    function implementation() external view returns (address) {
        return address(this);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return STARTING_TOKEN_ID;
    }
}
