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
 * @dev A contract to manage multiple raffles for ERC721 or ERC1155 vaults from whitelisted collections, using whitelisted payment tokens, with a flat platform fee.
 * @notice This contract allows users to buy tickets to win a Vault. Only whitelisted collections and payment tokens can be used. A flat platform fee is applied.
 */
contract RaffleContract is IERC721Receiver, IERC1155Receiver, Ownable, ReentrancyGuard {
    using Address for address payable;

    // --- Enums ---
    enum RaffleStatus {
        Open, // Raffle is active and accepting tickets
        Drawing, // In the process of selecting a winner (transient state)
        Closed, // Winner drawn successfully, vault claimable, funds withdrawable
        Failed // Minimum tickets not reached by end time, refunds available

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
        uint256 minTickets; // Minimum tickets to be sold for the raffle to succeed
        uint256 raffleEndTime;
        uint256 ticketsSold;
        address[] participants; // Array of buyers for random selection (Consider gas limits for large raffles)
        address winner;
        RaffleStatus status;
        mapping(uint256 => address) ticketBuyers; // ticketId => buyer address (Consider gas limits for large raffles)
        mapping(address => uint256) amountSpentByBuyer; // Tracks total spent by each buyer for refunds
        mapping(address => bool) refundClaimed; // Tracks if a buyer has claimed a refund for a failed raffle
        bool feePaid; // Tracks if the platform fee has been paid for this raffle
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
    event RaffleFailed(uint256 indexed raffleId); // Emitted when minTickets not reached
    event AssetReclaimed(uint256 indexed raffleId, address indexed depositor); // Emitted when depositor reclaims asset after failure
    event RefundClaimed(uint256 indexed raffleId, address indexed buyer, uint256 amount); // Emitted when a buyer claims refund
    event FundsWithdrawn(
        uint256 indexed raffleId, address indexed recipient, uint256 amount, uint256 platformFee
    ); // Updated fee parameter name
    event CollectionWhitelisted(address indexed collection);
    event CollectionRemoved(address indexed collection);
    event PaymentTokenWhitelisted(address indexed token);
    event PaymentTokenRemoved(address indexed token);
    event PlatformFeeUpdated(uint256 newFeeAmount);

    // --- Errors ---
    error CannotSetZeroAddress();
    error Erc721AmountMustBeOne();
    error TicketPriceMustBePositive();
    error MinTicketsMustBePositive();
    error RaffleDurationMustBePositive();
    error QuantityMustBePositive();
    error IncorrectEthValue();
    error EthSentWithTokenPayment();
    error PaymentFailed();
    error FeeTransferFailed();
    error DepositorFundsTransferFailed();
    error BatchTransfersNotSupported();
    error DirectEthTransfersNotAllowed();
    error FunctionDoesNotExist();
    error InvalidTicketId();

    error CollectionNotWhitelisted();
    error PaymentTokenNotWhitelisted();
    error VaultNotDeposited();
    error EthPaymentsDisabled();
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
    error RaffleNotOpen();
    error RaffleDoesNotExist();
    error RaffleNotFailed();
    error RefundAlreadyClaimed();
    error RefundTransferFailed();
    error NothingToRefund();
    error RaffleNotSuccessful();
    error FeeAlreadyPaid();
    error InsufficientFundsForFee();

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
        require(_feeCollector != address(0), CannotSetZeroAddress());
        require(_usdcAddress != address(0), CannotSetZeroAddress());

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
        // Check if the asset contract is whitelisted
        require(whitelistedCollections[_assetContract], CollectionNotWhitelisted());

        if (_assetType == AssetType.ERC721) {
            require(_amount == 1, Erc721AmountMustBeOne());
        }
        require(_ticketPrice > 0, TicketPriceMustBePositive());
        require(_minTickets > 0, MinTicketsMustBePositive());
        require(_raffleDuration > 0, RaffleDurationMustBePositive());

        // Check if ETH payments are enabled
        require(_paymentToken != address(0) || ethPaymentsEnabled, EthPaymentsDisabled());

        // Check if the payment token is whitelisted
        if (_paymentToken != address(0)) {
            require(whitelistedPaymentTokens[_paymentToken], PaymentTokenNotWhitelisted());
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
        raffle.feePaid = false; // Initialize feePaid status

        // Transfer the vault asset to the contract
        if (_assetType == AssetType.ERC721) {
            IERC721(_assetContract).safeTransferFrom(msg.sender, address(this), _tokenId);
        } else {
            IERC1155(_assetContract).safeTransferFrom(
                msg.sender, address(this), _tokenId, _amount, ""
            );
        }

        // Verify the asset was transferred
        require(isVaultDeposited(raffleId), TransferFailed());

        emit RaffleCreated(raffleId, msg.sender, _assetContract, _tokenId);
        emit VaultDeposited(raffleId, msg.sender, _assetContract, _tokenId);

        return raffleId;
    }

    // --- Whitelist Management ---

    function addCollectionToWhitelist(address _collection) external onlyOwner {
        require(_collection != address(0), CannotSetZeroAddress());
        whitelistedCollections[_collection] = true;
        emit CollectionWhitelisted(_collection);
    }

    function removeCollectionFromWhitelist(address _collection) external onlyOwner {
        require(_collection != address(0), CannotSetZeroAddress());
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
        require(_raffleId < raffleCounter, RaffleDoesNotExist());

        Raffle storage raffle = raffles[_raffleId];

        require(raffle.status == RaffleStatus.Open, RaffleNotOpen());
        require(block.timestamp <= raffle.raffleEndTime, RaffleEnded());
        require(isVaultDeposited(_raffleId), VaultNotDeposited());
        require(_quantity > 0, QuantityMustBePositive());

        require(whitelistedPaymentTokens[raffle.paymentToken], PaymentTokenNotWhitelisted());

        uint256 totalPrice = raffle.ticketPrice * _quantity;

        if (raffle.paymentToken == address(0)) {
            require(msg.value == totalPrice, IncorrectEthValue());
        } else {
            require(msg.value == 0, EthSentWithTokenPayment());
            require(
                IERC20(raffle.paymentToken).transferFrom(msg.sender, address(this), totalPrice),
                PaymentFailed()
            );
        }

        for (uint256 i = 0; i < _quantity; ++i) {
            uint256 ticketId = raffle.ticketsSold + i;
            raffle.ticketBuyers[ticketId] = msg.sender;
            raffle.participants.push(msg.sender);
            emit TicketPurchased(_raffleId, msg.sender, ticketId);
        }
        raffle.ticketsSold += _quantity;
        raffle.amountSpentByBuyer[msg.sender] += totalPrice; // Track amount spent
    }

    // --- Core Raffle Logic ---

    /**
     * @notice Finalizes a raffle after its end time.
     * @dev If minTickets is reached, draws a winner. Otherwise, marks the raffle as Failed.
     * @param _raffleId The ID of the raffle to finalize.
     */
    function finalizeRaffle(uint256 _raffleId) external nonReentrant {
        require(_raffleId < raffleCounter, RaffleDoesNotExist());

        Raffle storage raffle = raffles[_raffleId];

        require(raffle.status == RaffleStatus.Open, RaffleNotOpen());
        require(block.timestamp > raffle.raffleEndTime, RaffleStillOpen());
        require(isVaultDeposited(_raffleId), VaultNotDeposited()); // Ensure asset is still here

        if (raffle.ticketsSold >= raffle.minTickets) {
            // Raffle succeeded, draw winner
            raffle.status = RaffleStatus.Drawing; // Transient state

            // Simple pseudo-randomness (Consider Chainlink VRF for production)
            uint256 randomIndex = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp, block.prevrandao, raffle.ticketsSold, _raffleId
                    )
                )
            ) % raffle.participants.length;
            raffle.winner = raffle.participants[randomIndex];

            raffle.status = RaffleStatus.Closed; // Final state for successful raffle
            emit WinnerDrawn(_raffleId, raffle.winner);
        } else {
            // Raffle failed, mark for refunds
            raffle.status = RaffleStatus.Failed;
            emit RaffleFailed(_raffleId);
        }
    }

    /**
     * @notice Allows the winner to claim the vault asset after a successful raffle.
     * @param _raffleId The ID of the raffle.
     */
    function claimVault(uint256 _raffleId) external nonReentrant {
        require(_raffleId < raffleCounter, RaffleDoesNotExist());

        Raffle storage raffle = raffles[_raffleId];

        require(raffle.status == RaffleStatus.Closed, RaffleNotClosed());
        require(msg.sender == raffle.winner, NotWinner());
        require(isVaultDeposited(_raffleId), VaultNotDeposited());

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

    /**
     * @notice Allows the vault depositor to reclaim their asset if the raffle failed.
     * @param _raffleId The ID of the failed raffle.
     */
    function reclaimAssetOnFailure(uint256 _raffleId) external nonReentrant {
        require(_raffleId < raffleCounter, RaffleDoesNotExist());

        Raffle storage raffle = raffles[_raffleId];

        require(raffle.status == RaffleStatus.Failed, RaffleNotFailed());
        require(msg.sender == raffle.vaultDepositor, NotDepositor());
        require(isVaultDeposited(_raffleId), VaultNotDeposited()); // Should still be here

        // Transfer asset back
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

        emit AssetReclaimed(_raffleId, raffle.vaultDepositor);
    }

    /**
     * @notice Allows ticket buyers to claim a refund if the raffle failed.
     * @param _raffleId The ID of the failed raffle.
     */
    function claimRefund(uint256 _raffleId) external nonReentrant {
        require(_raffleId < raffleCounter, RaffleDoesNotExist());

        Raffle storage raffle = raffles[_raffleId];

        require(raffle.status == RaffleStatus.Failed, RaffleNotFailed());

        uint256 refundAmount = raffle.amountSpentByBuyer[msg.sender];
        require(refundAmount > 0, NothingToRefund());
        require(!raffle.refundClaimed[msg.sender], RefundAlreadyClaimed());

        raffle.refundClaimed[msg.sender] = true; // Mark as claimed before transfer

        // Transfer refund
        if (raffle.paymentToken == address(0)) {
            // ETH refund
            payable(msg.sender).sendValue(refundAmount);
        } else {
            // ERC20 refund
            require(
                IERC20(raffle.paymentToken).transfer(msg.sender, refundAmount),
                RefundTransferFailed()
            );
        }

        emit RefundClaimed(_raffleId, msg.sender, refundAmount);
    }

    /**
     * @notice Allows the vault depositor to withdraw proceeds from a successful raffle after the platform fee is deducted.
     * @param _raffleId The ID of the successful raffle.
     */
    function withdrawFunds(uint256 _raffleId) external nonReentrant {
        require(_raffleId < raffleCounter, RaffleDoesNotExist());

        Raffle storage raffle = raffles[_raffleId];

        require(raffle.status == RaffleStatus.Closed, RaffleNotSuccessful()); // Must be successfully closed
        require(raffle.winner != address(0), RaffleNotSuccessful()); // Winner must be set
        require(msg.sender == raffle.vaultDepositor, NotDepositor()); // Only depositor can withdraw
        require(!raffle.feePaid, FeeAlreadyPaid()); // Prevent double withdrawal/fee payment

        uint256 totalRevenue = raffle.ticketsSold * raffle.ticketPrice;
        uint256 feeAmount = platformFeeAmount; // Use the stored flat fee

        require(totalRevenue >= feeAmount, InsufficientFundsForFee()); // Cannot pay fee

        uint256 amountToDepositor = totalRevenue - feeAmount;

        raffle.feePaid = true; // Mark fee as paid before transfers

        // Transfer fee to collector
        if (raffle.paymentToken == address(0)) {
            // ETH fee
            payable(feeCollector).sendValue(feeAmount);
        } else {
            // ERC20 fee
            require(
                IERC20(raffle.paymentToken).transfer(feeCollector, feeAmount), FeeTransferFailed()
            );
        }

        // Transfer remaining funds to depositor
        if (amountToDepositor > 0) {
            if (raffle.paymentToken == address(0)) {
                // ETH to depositor
                payable(raffle.vaultDepositor).sendValue(amountToDepositor);
            } else {
                // ERC20 to depositor
                require(
                    IERC20(raffle.paymentToken).transfer(raffle.vaultDepositor, amountToDepositor),
                    DepositorFundsTransferFailed()
                );
            }
        }

        emit FundsWithdrawn(_raffleId, raffle.vaultDepositor, amountToDepositor, feeAmount);
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
            bool isDeposited,
            bool feePaid // Added feePaid status
        )
    {
        require(_raffleId < raffleCounter, RaffleDoesNotExist());

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
            isVaultDeposited(_raffleId),
            raffle.feePaid // Return feePaid status
        );
    }

    function getTicketBuyer(uint256 _raffleId, uint256 _ticketId) external view returns (address) {
        require(_raffleId < raffleCounter, RaffleDoesNotExist());

        Raffle storage raffle = raffles[_raffleId];

        require(_ticketId < raffle.ticketsSold, InvalidTicketId());

        return raffle.ticketBuyers[_ticketId];
    }

    function getParticipants(uint256 _raffleId) external view returns (address[] memory) {
        require(_raffleId < raffleCounter, RaffleDoesNotExist());
        // Consider deprecating or adding warnings about gas usage for large arrays
        return raffles[_raffleId].participants;
    }

    function getBuyerInfo(uint256 _raffleId, address _buyer)
        external
        view
        returns (uint256 amountSpent, bool claimedRefund)
    {
        require(_raffleId < raffleCounter, RaffleDoesNotExist());
        Raffle storage raffle = raffles[_raffleId];
        return (raffle.amountSpentByBuyer[_buyer], raffle.refundClaimed[_buyer]);
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
        revert BatchTransfersNotSupported();
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId;
    }

    // --- Fallback Functions ---

    receive() external payable {
        revert DirectEthTransfersNotAllowed();
    }

    fallback() external payable {
        revert FunctionDoesNotExist();
    }
}
