// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "ERC721A-Upgradeable/ERC721AUpgradeable.sol";
import "ERC721A-Upgradeable/extensions/ERC721ABurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IVaultProxy.sol";
import "../interfaces/IERC721AVault.sol";

contract ERC721VaultImplementation is
    Initializable,
    ERC721AUpgradeable,
    ERC721ABurnableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IVaultProxy,
    IERC721AVault
{
    using ERC721AStorage for ERC721AStorage.Layout;

    bytes32 private constant BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
    string private constant DEFAULT_BASE_URI = "https://v2.emblemvault.io/meta/";
    uint256 private constant STARTING_TOKEN_ID = 1;

    mapping(uint256 => uint256) internal _externalTokenIdMap; // internalTokenId >> externalTokenId
    mapping(uint256 => uint256) internal _reverseTokenIdMap; // externalTokenId >> internalTokenId
    string private _baseTokenURI;

    event TokenMinted(
        address indexed to,
        uint256 indexed internalTokenId,
        uint256 indexed externalTokenId,
        bytes data
    );
    event TokenBurned(
        address indexed from,
        uint256 indexed internalTokenId,
        uint256 indexed externalTokenId,
        bytes data
    );
    event BaseURIUpdated(string newBaseURI);
    event DetailsUpdated(string name, string symbol);

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

    function mint(address to, uint256 externalTokenId) external override onlyOwner {
        require(_reverseTokenIdMap[externalTokenId] == 0, "External ID already minted");

        // Get the next internal ID that will be minted
        uint256 startTokenId = _nextTokenId();

        // Mint a new token - ERC721A will handle sequential internal IDs
        _mint(to, 1);

        // Map the IDs
        _externalTokenIdMap[startTokenId] = externalTokenId;
        _reverseTokenIdMap[externalTokenId] = startTokenId;

        emit TokenMinted(to, startTokenId, externalTokenId, "");
    }

    function mintWithData(address to, uint256 externalTokenId, bytes calldata data)
        external
        override
        onlyOwner
    {
        require(_reverseTokenIdMap[externalTokenId] == 0, "External ID already minted");

        // Get the next internal ID that will be minted
        uint256 startTokenId = _nextTokenId();

        // Mint a new token - ERC721A will handle sequential internal IDs
        _mint(to, 1);

        // After minting, verify the token exists and map the IDs
        require(_exists(startTokenId), "Token was not minted");
        require(ownerOf(startTokenId) == to, "Token not owned by recipient");

        // Map the IDs after verifying token exists
        _externalTokenIdMap[startTokenId] = externalTokenId;
        _reverseTokenIdMap[externalTokenId] = startTokenId;

        emit TokenMinted(to, startTokenId, externalTokenId, data);
    }

    function batchMint(address to, uint256[] calldata externalTokenIds) external onlyOwner {
        _mintBatch(to, externalTokenIds, "");
    }

    function batchMintWithData(address to, uint256[] calldata externalTokenIds, bytes calldata data)
        external
        onlyOwner
    {
        _mintBatch(to, externalTokenIds, data);
    }

    function _mintBatch(address to, uint256[] memory externalTokenIds, bytes memory data)
        internal
    {
        uint256 length = externalTokenIds.length;
        require(length > 0, "Empty arrays");

        // Check for duplicate external IDs first
        for (uint256 i = 0; i < length;) {
            require(_reverseTokenIdMap[externalTokenIds[i]] == 0, "External ID already minted");
            unchecked {
                ++i;
            }
        }

        // Get the starting internal ID
        uint256 startTokenId = _nextTokenId();

        // Mint all tokens to the recipient
        _mint(to, length);

        // Map IDs after minting to ensure tokens exist
        for (uint256 i = 0; i < length;) {
            uint256 internalTokenId = startTokenId + i;
            uint256 externalTokenId = externalTokenIds[i];

            // Verify token exists and ownership
            require(_exists(internalTokenId), "Token was not minted");
            require(ownerOf(internalTokenId) == to, "Token not owned by recipient");

            // Map IDs after verifying token exists
            _externalTokenIdMap[internalTokenId] = externalTokenId;
            _reverseTokenIdMap[externalTokenId] = internalTokenId;

            emit TokenMinted(to, internalTokenId, externalTokenId, data);
            unchecked {
                ++i;
            }
        }
    }

    function burn(uint256 internalTokenId)
        public
        override(ERC721ABurnableUpgradeable, IERC721AVault)
    {
        _burnSingle(internalTokenId, "");
    }

    function burnWithData(uint256 internalTokenId, bytes calldata data) public override {
        _burnSingle(internalTokenId, data);
    }

    function _burnSingle(uint256 internalTokenId, bytes memory data) internal {
        address owner = ownerOf(internalTokenId);
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "Not authorized");

        uint256 externalTokenId = _externalTokenIdMap[internalTokenId];
        delete _reverseTokenIdMap[externalTokenId];
        delete _externalTokenIdMap[internalTokenId];

        super.burn(internalTokenId);

        emit TokenBurned(_msgSender(), internalTokenId, externalTokenId, data);
    }

    function batchBurn(uint256[] calldata internalTokenIds) external override {
        _burnBatch(internalTokenIds, "");
    }

    function batchBurnWithData(uint256[] calldata internalTokenIds, bytes calldata data)
        external
        override
    {
        _burnBatch(internalTokenIds, data);
    }

    function _burnBatch(uint256[] memory internalTokenIds, bytes memory data) internal {
        uint256 length = internalTokenIds.length;
        require(length > 0, "Empty array");

        for (uint256 i = 0; i < length;) {
            _burnSingle(internalTokenIds[i], data);
            unchecked {
                ++i;
            }
        }
    }

    function getInternalTokenId(uint256 externalTokenId) external view override returns (uint256) {
        uint256 internalId = _reverseTokenIdMap[externalTokenId];
        require(internalId != 0, "Token mapping not found");
        require(_exists(internalId), "Token does not exist");
        return internalId;
    }

    function getExternalTokenId(uint256 internalTokenId) external view override returns (uint256) {
        require(_exists(internalTokenId), "Token does not exist");
        uint256 externalId = _externalTokenIdMap[internalTokenId];
        require(externalId != 0, "Token mapping not found");
        return externalId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external override onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    function setDetails(string calldata name_, string calldata symbol_)
        external
        override
        onlyOwner
    {
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
        return id == type(IVaultProxy).interfaceId || id == type(IERC721AVault).interfaceId
            || id == 0x01ffc9a7 // ERC165
            || id == 0xf4a95f26; // ERC721A
    }

    function version() external pure override returns (string memory) {
        return "1";
    }

    function interfaceId() external pure override returns (bytes4) {
        return type(IVaultProxy).interfaceId;
    }

    function beacon()
        external
        view
        override(IERC721AVault, IVaultProxy)
        returns (address beaconAddress)
    {
        assembly {
            beaconAddress := sload(BEACON_SLOT)
        }
    }

    function implementation()
        external
        view
        override(IERC721AVault, IVaultProxy)
        returns (address)
    {
        return address(this);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return STARTING_TOKEN_ID;
    }
}
