// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title RaffleContract
 * @dev A contract to manage multiple raffles for ERC721 or ERC1155 assets from whitelisted collections, using whitelisted payment tokens, with a flat platform fee.
 * @notice This contract allows users to buy tickets to win a Vault. Only whitelisted collections and payment tokens can be used. A flat platform fee is applied.
 */
contract RaffleContract is IERC721Receiver, IERC1155Receiver, Ownable, ReentrancyGuard {
    using Address for address payable;

    // --- Enums ---
    enum RaffleStatus {
        Open,
        Drawing,
        Closed
    }

    enum AssetType {
        ERC721,
        ERC1155
    }

    // --- Structs ---
    struct VaultAsset {
        AssetType assetType;
        address assetContract;
        uint256 tokenId;
        uint256 amount; // For ERC1155
    }

    struct Raffle {
        VaultAsset vaultAsset;
        address paymentToken; // Address(0) indicates ETH payment
        address vaultDepositor; // The original owner who deposited the Vault
        uint256 ticketPrice;
        uint256 minTickets;
        uint256 raffleEndTime;
        uint256 ticketsSold;
        address[] participants; // Array of buyers for random selection
        address winner;
        RaffleStatus status;
        mapping(uint256 => address) ticketBuyers; // ticketId => buyer address
    }

    // --- State Variables ---
    uint256 public raffleCounter;
    mapping(uint256 => Raffle) private raffles;

    address public immutable feeCollector;
    address public immutable usdcAddress; // USDC token address

    // Platform Fee state
    uint256 public platformFeeAmount; // Flat fee amount in payment token units (or wei for ETH)

    // ETH payment toggle
    bool public ethPaymentsEnabled;

    // Whitelist states
    mapping(address => bool) public whitelistedCollections;
    mapping(address => bool) public whitelistedPaymentTokens; // address(0) represents ETH

    // --- Events ---
    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed creator,
        address indexed assetContract,
        uint256 tokenId
    );
    event VaultDeposited(
        uint256 indexed raffleId,
        address indexed depositor,
        address indexed vaultContract,
        uint256 tokenId
    );
    event TicketPurchased(uint256 indexed raffleId, address indexed buyer, uint256 ticketId);
    event WinnerDrawn(uint256 indexed raffleId, address indexed winner);
    event VaultClaimed(
        uint256 indexed raffleId,
        address indexed winner,
        address indexed vaultContract,
        uint256 tokenId
    );
    event RaffleCancelled(uint256 indexed raffleId, address indexed depositor);
    event FundsWithdrawn(
        uint256 indexed raffleId, address indexed recipient, uint256 amount, uint256 fee
    );
    event CollectionWhitelisted(address indexed collection);
    event CollectionRemoved(address indexed collection);
    event PaymentTokenWhitelisted(address indexed token);
    event PaymentTokenRemoved(address indexed token);
    event PlatformFeeUpdated(uint256 newFeeAmount);

    // --- Errors ---
    error RaffleNotOpen();
    error VaultNotDeposited();
    error IncorrectPayment();
    error MinTicketsNotReached();
    error RaffleEnded();
    error RaffleNotReadyForDraw();
    error DrawAlreadyOccurred();
    error NotWinner();
    error RaffleNotClosed();
    error TransferFailed();
    error AlreadyDeposited();
    error NotDepositor();
    error RaffleStillOpen();
    error CollectionNotWhitelisted();
    error PaymentTokenNotWhitelisted();
    error FeeExceedsBalance();
    error RaffleDoesNotExist();

    /**
     * @param _initialOwner Owner of this raffle contract
     * @param _feeCollector Address to receive platform fees
     * @param _initialPlatformFeeAmount The initial flat platform fee amount
     * @param _usdcAddress Address of the USDC token
     */
    constructor(
        address _initialOwner,
        address _feeCollector,
        uint256 _initialPlatformFeeAmount,
        address _usdcAddress
    ) Ownable(_initialOwner) {
        require(_feeCollector != address(0), "Invalid fee collector");
        require(_usdcAddress != address(0), "Invalid USDC address");

        feeCollector = _feeCollector;
        platformFeeAmount = _initialPlatformFeeAmount;
        usdcAddress = _usdcAddress;
        ethPaymentsEnabled = false; // Start with ETH payments disabled

        // Add USDC to whitelisted payment tokens
        whitelistedPaymentTokens[_usdcAddress] = true;
    }

    /**
     * @notice Creates a new raffle and deposits the vault asset in a single transaction
     * @param _assetType Type of asset being raffled (ERC721/ERC1155)
     * @param _assetContract Address of the asset contract
     * @param _tokenId ID of the token to be raffled
     * @param _amount Amount of tokens (for ERC1155)
     * @param _ticketPrice Price per ticket in payment token units
     * @param _paymentToken Address of ERC20 token used for payments (0x0 for ETH if enabled)
     * @param _minTickets Minimum number of tickets to sell before drawing
     * @param _raffleDuration Duration of the raffle in seconds from creation
     * @return raffleId The ID of the newly created raffle
     */
    function createRaffle(
        AssetType _assetType,
        address _assetContract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _ticketPrice,
        address _paymentToken,
        uint256 _minTickets,
        uint256 _raffleDuration
    ) external payable nonReentrant returns (uint256 raffleId) {
        require(_assetContract != address(0), "Invalid asset contract");

        if (_assetType == AssetType.ERC721) {
            require(_amount == 1, "ERC721 requires amount=1");
        }
        require(_ticketPrice > 0, "Ticket price must be positive");
        require(_minTickets > 0, "Minimum tickets must be positive");
        require(_raffleDuration > 0, "Raffle duration must be positive");

        // Check if ETH payments are enabled
        if (_paymentToken == address(0) && !ethPaymentsEnabled) {
            revert("ETH payments are disabled");
        }

        if (!whitelistedCollections[_assetContract]) {
            revert CollectionNotWhitelisted();
        }

        if (!whitelistedPaymentTokens[_paymentToken]) {
            revert PaymentTokenNotWhitelisted();
        }

        // Collect platform fee upfront
        if (_paymentToken == address(0)) {
            // ETH payment
            require(msg.value == platformFeeAmount, "Incorrect ETH fee amount");
            // Transfer fee to fee collector
            payable(feeCollector).sendValue(platformFeeAmount);
        } else {
            // ERC20 payment
            require(msg.value == 0, "ETH sent with token payment");
            require(
                IERC20(_paymentToken).transferFrom(msg.sender, feeCollector, platformFeeAmount),
                "Fee payment failed"
            );
        }

        raffleId = raffleCounter++;
        Raffle storage raffle = raffles[raffleId];

        raffle.vaultAsset = VaultAsset(_assetType, _assetContract, _tokenId, _amount);
        raffle.paymentToken = _paymentToken;
        raffle.vaultDepositor = msg.sender;
        raffle.ticketPrice = _ticketPrice;
        raffle.minTickets = _minTickets;
        raffle.raffleEndTime = block.timestamp + _raffleDuration;
        raffle.status = RaffleStatus.Open;

        // Transfer the vault asset to the contract
        if (_assetType == AssetType.ERC721) {
            IERC721(_assetContract).safeTransferFrom(msg.sender, address(this), _tokenId);
        } else {
            IERC1155(_assetContract).safeTransferFrom(
                msg.sender, address(this), _tokenId, _amount, ""
            );
        }

        // Verify the asset was transferred
        if (!isVaultDeposited(raffleId)) {
            revert TransferFailed();
        }

        emit RaffleCreated(raffleId, msg.sender, _assetContract, _tokenId);
        emit VaultDeposited(raffleId, msg.sender, _assetContract, _tokenId);

        return raffleId;
    }

    // --- Whitelist Management ---

    function addCollectionToWhitelist(address _collection) external onlyOwner {
        require(_collection != address(0), "Invalid collection address");
        whitelistedCollections[_collection] = true;
        emit CollectionWhitelisted(_collection);
    }

    function removeCollectionFromWhitelist(address _collection) external onlyOwner {
        require(_collection != address(0), "Invalid collection address");
        whitelistedCollections[_collection] = false;
        emit CollectionRemoved(_collection);
    }

    function addPaymentTokenToWhitelist(address _token) external onlyOwner {
        whitelistedPaymentTokens[_token] = true;
        emit PaymentTokenWhitelisted(_token);
    }

    function removePaymentTokenFromWhitelist(address _token) external onlyOwner {
        whitelistedPaymentTokens[_token] = false;
        emit PaymentTokenRemoved(_token);
    }

    // --- Fee Management ---

    function setPlatformFeeAmount(uint256 _newFeeAmount) external onlyOwner {
        platformFeeAmount = _newFeeAmount;
        emit PlatformFeeUpdated(_newFeeAmount);
    }

    /**
     * @notice Enables or disables ETH payments
     * @param _enabled Whether ETH payments should be enabled
     */
    function setEthPaymentsEnabled(bool _enabled) external onlyOwner {
        ethPaymentsEnabled = _enabled;
    }

    function buyTicket(uint256 _raffleId, uint256 _quantity) external payable nonReentrant {
        if (_raffleId >= raffleCounter) revert RaffleDoesNotExist();

        Raffle storage raffle = raffles[_raffleId];

        if (raffle.status != RaffleStatus.Open) revert RaffleNotOpen();
        if (block.timestamp > raffle.raffleEndTime) revert RaffleEnded();
        if (!isVaultDeposited(_raffleId)) revert VaultNotDeposited();
        require(_quantity > 0, "Quantity must be positive");

        if (!whitelistedPaymentTokens[raffle.paymentToken]) {
            revert PaymentTokenNotWhitelisted();
        }

        uint256 totalPrice = raffle.ticketPrice * _quantity;

        if (raffle.paymentToken == address(0)) {
            require(msg.value == totalPrice, "Incorrect ETH value");
        } else {
            require(msg.value == 0, "ETH sent with token payment");
            require(
                IERC20(raffle.paymentToken).transferFrom(msg.sender, address(this), totalPrice),
                "Payment failed"
            );
        }

        for (uint256 i = 0; i < _quantity; ++i) {
            uint256 ticketId = raffle.ticketsSold + i;
            raffle.ticketBuyers[ticketId] = msg.sender;
            raffle.participants.push(msg.sender);
            emit TicketPurchased(_raffleId, msg.sender, ticketId);
        }
        raffle.ticketsSold += _quantity;
    }

    // --- Core Raffle Logic ---

    function drawWinner(uint256 _raffleId) external nonReentrant {
        if (_raffleId >= raffleCounter) revert RaffleDoesNotExist();

        Raffle storage raffle = raffles[_raffleId];

        if (raffle.status != RaffleStatus.Open) revert RaffleNotOpen();
        // Only allow drawing after raffle end time has passed
        if (block.timestamp <= raffle.raffleEndTime) {
            revert("Raffle end time has not passed yet");
        }
        // Check if minimum tickets were sold
        if (raffle.ticketsSold < raffle.minTickets) {
            revert MinTicketsNotReached();
        }
        if (!isVaultDeposited(_raffleId)) revert VaultNotDeposited();

        raffle.status = RaffleStatus.Drawing;

        uint256 randomIndex = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, raffle.ticketsSold, _raffleId)
            )
        ) % raffle.participants.length;
        raffle.winner = raffle.participants[randomIndex];

        raffle.status = RaffleStatus.Closed;

        emit WinnerDrawn(_raffleId, raffle.winner);
    }

    function claimVault(uint256 _raffleId) external nonReentrant {
        if (_raffleId >= raffleCounter) revert RaffleDoesNotExist();

        Raffle storage raffle = raffles[_raffleId];

        if (raffle.status != RaffleStatus.Closed) revert RaffleNotClosed();
        if (msg.sender != raffle.winner) revert NotWinner();
        if (!isVaultDeposited(_raffleId)) revert VaultNotDeposited();

        if (raffle.vaultAsset.assetType == AssetType.ERC721) {
            IERC721(raffle.vaultAsset.assetContract).safeTransferFrom(
                address(this), raffle.winner, raffle.vaultAsset.tokenId
            );
        } else {
            IERC1155(raffle.vaultAsset.assetContract).safeTransferFrom(
                address(this),
                raffle.winner,
                raffle.vaultAsset.tokenId,
                raffle.vaultAsset.amount,
                ""
            );
        }

        emit VaultClaimed(
            _raffleId, raffle.winner, raffle.vaultAsset.assetContract, raffle.vaultAsset.tokenId
        );
    }

    function cancelRaffle(uint256 _raffleId) external nonReentrant {
        if (_raffleId >= raffleCounter) revert RaffleDoesNotExist();

        Raffle storage raffle = raffles[_raffleId];

        if (raffle.status != RaffleStatus.Open) revert RaffleNotOpen();
        if (block.timestamp <= raffle.raffleEndTime) revert RaffleStillOpen();
        if (raffle.ticketsSold >= raffle.minTickets) revert MinTicketsNotReached();
        if (msg.sender != raffle.vaultDepositor) revert NotDepositor();
        if (!isVaultDeposited(_raffleId)) revert VaultNotDeposited();

        raffle.status = RaffleStatus.Closed;

        if (raffle.vaultAsset.assetType == AssetType.ERC721) {
            IERC721(raffle.vaultAsset.assetContract).safeTransferFrom(
                address(this), raffle.vaultDepositor, raffle.vaultAsset.tokenId
            );
        } else {
            IERC1155(raffle.vaultAsset.assetContract).safeTransferFrom(
                address(this),
                raffle.vaultDepositor,
                raffle.vaultAsset.tokenId,
                raffle.vaultAsset.amount,
                ""
            );
        }

        emit RaffleCancelled(_raffleId, raffle.vaultDepositor);
    }

    function withdrawFunds(uint256 _raffleId) external nonReentrant {
        if (_raffleId >= raffleCounter) revert RaffleDoesNotExist();

        Raffle storage raffle = raffles[_raffleId];

        if (raffle.status != RaffleStatus.Closed) revert RaffleNotClosed();
        // Check if the raffle was cancelled (no winner but status is Closed)
        // or if a winner was drawn (winner is set)
        if (raffle.winner == address(0) && isVaultDeposited(_raffleId)) {
            revert DrawAlreadyOccurred();
        }
        if (msg.sender != raffle.vaultDepositor && msg.sender != owner()) revert NotDepositor();

        uint256 balance;
        if (raffle.paymentToken == address(0)) {
            // For ETH raffles, we need to calculate how much ETH belongs to this raffle
            // This is an approximation based on tickets sold
            balance = raffle.ticketsSold * raffle.ticketPrice;
            // Ensure we don't try to withdraw more than the contract has
            if (balance > address(this).balance) {
                balance = address(this).balance;
            }
        } else {
            // For token raffles, we can get the exact balance
            balance = IERC20(raffle.paymentToken).balanceOf(address(this));
        }

        if (balance == 0) revert TransferFailed();

        // Transfer all funds to the vault depositor (fee was already collected at creation)
        if (raffle.paymentToken == address(0)) {
            payable(raffle.vaultDepositor).sendValue(balance);
        } else {
            IERC20(raffle.paymentToken).transfer(raffle.vaultDepositor, balance);
        }

        emit FundsWithdrawn(_raffleId, raffle.vaultDepositor, balance, 0);
    }

    // --- View Functions ---

    function isVaultDeposited(uint256 _raffleId) public view returns (bool) {
        if (_raffleId >= raffleCounter) return false;

        Raffle storage raffle = raffles[_raffleId];

        if (raffle.vaultAsset.assetContract == address(0)) return false;

        if (raffle.vaultAsset.assetType == AssetType.ERC721) {
            try IERC721(raffle.vaultAsset.assetContract).ownerOf(raffle.vaultAsset.tokenId)
            returns (address currentOwner) {
                return currentOwner == address(this);
            } catch {
                return false;
            }
        } else {
            try IERC1155(raffle.vaultAsset.assetContract).balanceOf(
                address(this), raffle.vaultAsset.tokenId
            ) returns (uint256 balance) {
                return balance >= raffle.vaultAsset.amount;
            } catch {
                return false;
            }
        }
    }

    function getRaffleInfo(uint256 _raffleId)
        external
        view
        returns (
            address assetContract,
            uint256 tokenId,
            uint256 amount,
            address paymentToken,
            address vaultDepositor,
            uint256 ticketPrice,
            uint256 minTickets,
            uint256 raffleEndTime,
            uint256 ticketsSold,
            address winner,
            RaffleStatus status,
            bool isDeposited
        )
    {
        if (_raffleId >= raffleCounter) revert RaffleDoesNotExist();

        Raffle storage raffle = raffles[_raffleId];

        return (
            raffle.vaultAsset.assetContract,
            raffle.vaultAsset.tokenId,
            raffle.vaultAsset.amount,
            raffle.paymentToken,
            raffle.vaultDepositor,
            raffle.ticketPrice,
            raffle.minTickets,
            raffle.raffleEndTime,
            raffle.ticketsSold,
            raffle.winner,
            raffle.status,
            isVaultDeposited(_raffleId)
        );
    }

    function getTicketBuyer(uint256 _raffleId, uint256 _ticketId) external view returns (address) {
        if (_raffleId >= raffleCounter) revert RaffleDoesNotExist();

        Raffle storage raffle = raffles[_raffleId];

        if (_ticketId >= raffle.ticketsSold) revert("Invalid ticket ID");

        return raffle.ticketBuyers[_ticketId];
    }

    function getParticipants(uint256 _raffleId) external view returns (address[] memory) {
        if (_raffleId >= raffleCounter) revert RaffleDoesNotExist();

        return raffles[_raffleId].participants;
    }

    // --- Receiver Callbacks ---

    function onERC721Received(address, address from, uint256 tokenId, bytes memory data)
        external
        view
        override
        returns (bytes4)
    {
        // If data is provided, it should contain the raffleId
        uint256 raffleId;
        if (data.length >= 32) {
            // Extract raffleId from data
            assembly {
                raffleId := mload(add(data, 32))
            }

            if (raffleId < raffleCounter) {
                Raffle storage raffle = raffles[raffleId];

                if (
                    msg.sender == raffle.vaultAsset.assetContract
                        && tokenId == raffle.vaultAsset.tokenId && from == raffle.vaultDepositor
                        && raffle.vaultAsset.assetType == AssetType.ERC721
                ) {
                    return IERC721Receiver.onERC721Received.selector;
                }
            }
        }

        // Fallback: check all open raffles
        for (uint256 i = 0; i < raffleCounter; i++) {
            Raffle storage raffle = raffles[i];

            if (
                raffle.status == RaffleStatus.Open && msg.sender == raffle.vaultAsset.assetContract
                    && tokenId == raffle.vaultAsset.tokenId && from == raffle.vaultDepositor
                    && raffle.vaultAsset.assetType == AssetType.ERC721
            ) {
                return IERC721Receiver.onERC721Received.selector;
            }
        }

        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address from, uint256 id, uint256 value, bytes memory data)
        external
        view
        override
        returns (bytes4)
    {
        // If data is provided, it should contain the raffleId
        uint256 raffleId;
        if (data.length >= 32) {
            // Extract raffleId from data
            assembly {
                raffleId := mload(add(data, 32))
            }

            if (raffleId < raffleCounter) {
                Raffle storage raffle = raffles[raffleId];

                if (
                    msg.sender == raffle.vaultAsset.assetContract && id == raffle.vaultAsset.tokenId
                        && value == raffle.vaultAsset.amount && from == raffle.vaultDepositor
                        && raffle.vaultAsset.assetType == AssetType.ERC1155
                ) {
                    return IERC1155Receiver.onERC1155Received.selector;
                }
            }
        }

        // Fallback: check all open raffles
        for (uint256 i = 0; i < raffleCounter; i++) {
            Raffle storage raffle = raffles[i];

            if (
                raffle.status == RaffleStatus.Open && msg.sender == raffle.vaultAsset.assetContract
                    && id == raffle.vaultAsset.tokenId && value == raffle.vaultAsset.amount
                    && from == raffle.vaultDepositor && raffle.vaultAsset.assetType == AssetType.ERC1155
            ) {
                return IERC1155Receiver.onERC1155Received.selector;
            }
        }

        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure override returns (bytes4) {
        revert("Batch transfers not supported");
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId;
    }

    // --- Fallback Functions ---

    receive() external payable {
        revert("Direct ETH transfers not allowed; use buyTicket");
    }

    fallback() external payable {
        revert("Function does not exist");
    }
}
