// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {RaffleContract} from "../src/RaffleContract.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockERC1155} from "./mocks/MockERC1155.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract RaffleContractTest is Test {
    RaffleContract public raffleContract;
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;
    MockERC20 public mockUSDC;
    MockERC20 public mockOtherToken;

    address public owner = address(0x1);
    address public feeCollector = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public user3 = address(0x5);

    uint256 public platformFee = 0.01 ether;
    uint256 public ticketPrice = 0.1 ether;
    uint256 public minTickets = 5;
    uint256 public raffleDuration = 7 days;

    uint256 public erc721TokenId = 1;
    uint256 public erc1155TokenId = 2;
    uint256 public erc1155Amount = 1;

    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed creator,
        address indexed assetContract,
        uint256 tokenId
    );

    function setUp() public {
        // Deploy mock tokens
        mockERC721 = new MockERC721("Mock ERC721", "MOCK721");
        mockERC1155 = new MockERC1155("URI");
        mockUSDC = new MockERC20("USD Coin", "USDC");
        mockOtherToken = new MockERC20("Other Token", "OTHER");

        // Deploy raffle contract with USDC address
        vm.prank(owner);
        raffleContract = new RaffleContract(owner, feeCollector, platformFee, address(mockUSDC));

        // Mint tokens to owner for platform fees
        mockUSDC.mint(owner, 100 ether);
        mockOtherToken.mint(owner, 100 ether);

        // Approve tokens for platform fees
        vm.prank(owner);
        mockUSDC.approve(address(raffleContract), type(uint256).max);
        vm.prank(owner);
        mockOtherToken.approve(address(raffleContract), type(uint256).max);

        // Mint tokens to users
        mockERC721.mint(owner, erc721TokenId);
        mockERC1155.mint(owner, erc1155TokenId, erc1155Amount, "");

        // Mint USDC to users
        mockUSDC.mint(user1, 100 ether);
        mockUSDC.mint(user2, 100 ether);
        mockUSDC.mint(user3, 100 ether);

        // Mint other token to users
        mockOtherToken.mint(user1, 100 ether);
        mockOtherToken.mint(user2, 100 ether);
        mockOtherToken.mint(user3, 100 ether);

        // Whitelist collections
        vm.startPrank(owner);
        raffleContract.addCollectionToWhitelist(address(mockERC721));
        raffleContract.addCollectionToWhitelist(address(mockERC1155));

        // Add other token to whitelist
        raffleContract.addPaymentTokenToWhitelist(address(mockOtherToken));
        vm.stopPrank();

        // Approve raffle contract to transfer tokens
        vm.prank(owner);
        mockERC721.setApprovalForAll(address(raffleContract), true);
        vm.prank(owner);
        mockERC1155.setApprovalForAll(address(raffleContract), true);

        // Approve payment tokens
        vm.prank(user1);
        mockUSDC.approve(address(raffleContract), type(uint256).max);
        vm.prank(user2);
        mockUSDC.approve(address(raffleContract), type(uint256).max);
        vm.prank(user3);
        mockUSDC.approve(address(raffleContract), type(uint256).max);

        vm.prank(user1);
        mockOtherToken.approve(address(raffleContract), type(uint256).max);
        vm.prank(user2);
        mockOtherToken.approve(address(raffleContract), type(uint256).max);
        vm.prank(user3);
        mockOtherToken.approve(address(raffleContract), type(uint256).max);
    }

    function test_CreateRaffleWithUSDC() public {
        // Record fee collector balance before
        uint256 feeCollectorBalanceBefore = mockUSDC.balanceOf(feeCollector);

        vm.prank(owner);
        uint256 raffleId = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId,
            1, // amount (must be 1 for ERC721)
            ticketPrice,
            address(mockUSDC), // USDC payment
            minTickets,
            raffleDuration
        );

        // Check fee was collected
        uint256 feeCollectorBalanceAfter = mockUSDC.balanceOf(feeCollector);
        assertEq(
            feeCollectorBalanceAfter - feeCollectorBalanceBefore,
            platformFee,
            "Platform fee should be collected at creation"
        );

        assertEq(raffleId, 0, "First raffle ID should be 0");

        // Check raffle info
        (
            address assetContract,
            uint256 tokenId,
            uint256 amount,
            address paymentToken,
            address vaultDepositor,
            uint256 price,
            uint256 min,
            ,
            uint256 ticketsSold,
            address winner,
            RaffleContract.RaffleStatus status,
            bool isDeposited
        ) = raffleContract.getRaffleInfo(raffleId);

        assertEq(assetContract, address(mockERC721), "Asset contract should match");
        assertEq(tokenId, erc721TokenId, "Token ID should match");
        assertEq(amount, 1, "Amount should be 1 for ERC721");
        assertEq(paymentToken, address(mockUSDC), "Payment token should be USDC");
        assertEq(vaultDepositor, owner, "Vault depositor should be owner");
        assertEq(price, ticketPrice, "Ticket price should match");
        assertEq(min, minTickets, "Min tickets should match");
        assertEq(ticketsSold, 0, "No tickets should be sold yet");
        assertEq(winner, address(0), "No winner should be set yet");
        assertEq(
            uint256(status), uint256(RaffleContract.RaffleStatus.Open), "Raffle should be open"
        );
        assertTrue(isDeposited, "Vault should be deposited");

        // Check token ownership
        assertEq(
            mockERC721.ownerOf(erc721TokenId),
            address(raffleContract),
            "Raffle contract should own the ERC721 token"
        );
    }

    function test_CreateRaffleWithOtherToken() public {
        // Record fee collector balance before
        uint256 feeCollectorBalanceBefore = mockOtherToken.balanceOf(feeCollector);

        vm.prank(owner);
        uint256 raffleId = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC1155,
            address(mockERC1155),
            erc1155TokenId,
            erc1155Amount,
            ticketPrice,
            address(mockOtherToken), // Other token payment
            minTickets,
            raffleDuration
        );

        // Check fee was collected
        uint256 feeCollectorBalanceAfter = mockOtherToken.balanceOf(feeCollector);
        assertEq(
            feeCollectorBalanceAfter - feeCollectorBalanceBefore,
            platformFee,
            "Platform fee should be collected at creation"
        );

        assertEq(raffleId, 0, "First raffle ID should be 0");

        // Check raffle info
        (
            address assetContract,
            uint256 tokenId,
            uint256 amount,
            address paymentToken,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            bool isDeposited
        ) = raffleContract.getRaffleInfo(raffleId);

        assertEq(assetContract, address(mockERC1155), "Asset contract should match");
        assertEq(tokenId, erc1155TokenId, "Token ID should match");
        assertEq(amount, erc1155Amount, "Amount should match");
        assertEq(paymentToken, address(mockOtherToken), "Payment token should be OTHER");
        assertTrue(isDeposited, "Vault should be deposited");

        // Check token ownership
        assertEq(
            mockERC1155.balanceOf(address(raffleContract), erc1155TokenId),
            erc1155Amount,
            "Raffle contract should own the ERC1155 token"
        );
    }

    function test_EthPaymentsDisabledByDefault() public {
        vm.prank(owner);
        vm.expectRevert("ETH payments are disabled");
        raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId,
            1,
            ticketPrice,
            address(0), // ETH payment (should fail)
            minTickets,
            raffleDuration
        );
    }

    function test_EnableEthPayments() public {
        // Enable ETH payments
        vm.prank(owner);
        raffleContract.setEthPaymentsEnabled(true);

        // Whitelist ETH as payment
        vm.prank(owner);
        raffleContract.addPaymentTokenToWhitelist(address(0));

        // Mint another token for this test
        uint256 newTokenId = 3;
        mockERC721.mint(owner, newTokenId);

        // Record fee collector balance before
        uint256 feeCollectorBalanceBefore = address(feeCollector).balance;

        // Create raffle with ETH payment
        vm.deal(owner, platformFee);
        vm.prank(owner);
        uint256 raffleId = raffleContract.createRaffle{value: platformFee}(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            newTokenId,
            1,
            ticketPrice,
            address(0), // ETH payment (should work now)
            minTickets,
            raffleDuration
        );

        // Check fee was collected
        uint256 feeCollectorBalanceAfter = address(feeCollector).balance;
        assertEq(
            feeCollectorBalanceAfter - feeCollectorBalanceBefore,
            platformFee,
            "Platform fee should be collected at creation"
        );

        // Check payment token
        (,,, address paymentToken,,,,,,,,) = raffleContract.getRaffleInfo(raffleId);
        assertEq(paymentToken, address(0), "Payment token should be ETH");
    }

    function test_BuyTicketsWithUSDC() public {
        // Create raffle with USDC payment
        vm.prank(owner);
        uint256 raffleId = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId,
            1,
            ticketPrice,
            address(mockUSDC),
            minTickets,
            raffleDuration
        );

        // Buy tickets
        vm.prank(user1);
        raffleContract.buyTicket(raffleId, 3);

        vm.prank(user2);
        raffleContract.buyTicket(raffleId, 2);

        // Check ticket counts
        (,,,,,,,, uint256 ticketsSold,,,) = raffleContract.getRaffleInfo(raffleId);
        assertEq(ticketsSold, 5, "Raffle should have 5 tickets sold");

        // Check ticket buyers
        assertEq(
            raffleContract.getTicketBuyer(raffleId, 0), user1, "Ticket 0 should belong to user1"
        );
        assertEq(
            raffleContract.getTicketBuyer(raffleId, 3), user2, "Ticket 3 should belong to user2"
        );

        // Check USDC balance
        assertEq(
            mockUSDC.balanceOf(address(raffleContract)),
            ticketPrice * 5,
            "Contract should have correct USDC balance"
        );
    }

    function test_DrawWinnerAfterEndTime() public {
        // Create raffle with USDC payment
        vm.prank(owner);
        uint256 raffleId = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId,
            1,
            ticketPrice,
            address(mockUSDC),
            minTickets,
            raffleDuration
        );

        // Buy tickets
        vm.prank(user1);
        raffleContract.buyTicket(raffleId, 3);

        vm.prank(user2);
        raffleContract.buyTicket(raffleId, 2);

        // Try to draw winner before end time
        vm.prank(owner);
        vm.expectRevert("Raffle end time has not passed yet");
        raffleContract.drawWinner(raffleId);

        // Fast forward past raffle end time
        vm.warp(block.timestamp + raffleDuration + 1);

        // Draw winner
        vm.prank(owner);
        raffleContract.drawWinner(raffleId);

        // Check raffle status and winner
        (,,,,,,,,, address winner, RaffleContract.RaffleStatus status,) =
            raffleContract.getRaffleInfo(raffleId);

        assertEq(
            uint256(status), uint256(RaffleContract.RaffleStatus.Closed), "Raffle should be closed"
        );
        assertTrue(winner == user1 || winner == user2, "Winner should be one of the participants");
    }

    function test_ClaimVault() public {
        // Create raffle with USDC payment
        vm.prank(owner);
        uint256 raffleId = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId,
            1,
            ticketPrice,
            address(mockUSDC),
            minTickets,
            raffleDuration
        );

        // Buy tickets
        vm.prank(user1);
        raffleContract.buyTicket(raffleId, 3);

        vm.prank(user2);
        raffleContract.buyTicket(raffleId, 2);

        // Fast forward past raffle end time
        vm.warp(block.timestamp + raffleDuration + 1);

        // Draw winner
        vm.prank(owner);
        raffleContract.drawWinner(raffleId);

        // Get the winner
        (,,,,,,,,, address winner,,) = raffleContract.getRaffleInfo(raffleId);

        // Claim vault as winner
        vm.prank(winner);
        raffleContract.claimVault(raffleId);

        // Check token ownership
        assertEq(mockERC721.ownerOf(erc721TokenId), winner, "Winner should own the ERC721 token");
    }

    function test_WithdrawFunds() public {
        // Create raffle with USDC payment
        vm.prank(owner);
        uint256 raffleId = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId,
            1,
            ticketPrice,
            address(mockUSDC),
            minTickets,
            raffleDuration
        );

        // Buy tickets
        vm.prank(user1);
        raffleContract.buyTicket(raffleId, 3);

        vm.prank(user2);
        raffleContract.buyTicket(raffleId, 2);

        // Fast forward past raffle end time
        vm.warp(block.timestamp + raffleDuration + 1);

        // Draw winner
        vm.prank(owner);
        raffleContract.drawWinner(raffleId);

        // Get the winner
        (,,,,,,,,, address winner,,) = raffleContract.getRaffleInfo(raffleId);

        // Claim vault as winner
        vm.prank(winner);
        raffleContract.claimVault(raffleId);

        // Record balances before withdrawal
        uint256 ownerBalanceBefore = mockUSDC.balanceOf(owner);
        uint256 contractBalanceBefore = mockUSDC.balanceOf(address(raffleContract));

        // Withdraw funds
        vm.prank(owner);
        raffleContract.withdrawFunds(raffleId);

        // Check balances after withdrawal
        uint256 ownerBalanceAfter = mockUSDC.balanceOf(owner);

        assertEq(
            ownerBalanceAfter - ownerBalanceBefore,
            contractBalanceBefore,
            "Owner should receive all funds"
        );
        assertEq(
            mockUSDC.balanceOf(address(raffleContract)),
            0,
            "Contract should have 0 USDC balance after withdrawal"
        );
    }

    function test_MultipleRafflesSimultaneously() public {
        // Create two raffles
        vm.startPrank(owner);
        uint256 raffleId1 = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId,
            1,
            ticketPrice,
            address(mockUSDC),
            minTickets,
            raffleDuration
        );

        // Mint another ERC721 for the second raffle
        uint256 erc721TokenId2 = 2;
        mockERC721.mint(owner, erc721TokenId2);

        uint256 raffleId2 = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId2,
            1,
            ticketPrice * 2, // Different ticket price
            address(mockOtherToken), // Different payment token
            minTickets,
            raffleDuration
        );
        vm.stopPrank();

        // Buy tickets for both raffles
        vm.startPrank(user1);
        raffleContract.buyTicket(raffleId1, 3); // USDC payment
        raffleContract.buyTicket(raffleId2, 2); // OTHER token payment
        vm.stopPrank();

        vm.startPrank(user2);
        raffleContract.buyTicket(raffleId1, 2); // USDC payment
        raffleContract.buyTicket(raffleId2, 3); // OTHER token payment
        vm.stopPrank();

        // Check ticket counts
        (,,,,,,,, uint256 ticketsSold1,,,) = raffleContract.getRaffleInfo(raffleId1);
        (,,,,,,,, uint256 ticketsSold2,,,) = raffleContract.getRaffleInfo(raffleId2);

        assertEq(ticketsSold1, 5, "Raffle 1 should have 5 tickets sold");
        assertEq(ticketsSold2, 5, "Raffle 2 should have 5 tickets sold");

        // Fast forward past raffle end time
        vm.warp(block.timestamp + raffleDuration + 1);

        // Draw winners for both raffles
        vm.prank(owner);
        raffleContract.drawWinner(raffleId1);

        vm.prank(owner);
        raffleContract.drawWinner(raffleId2);

        // Get winners
        (,,,,,,,,, address winner1,,) = raffleContract.getRaffleInfo(raffleId1);
        (,,,,,,,,, address winner2,,) = raffleContract.getRaffleInfo(raffleId2);

        // Claim vaults
        vm.prank(winner1);
        raffleContract.claimVault(raffleId1);

        vm.prank(winner2);
        raffleContract.claimVault(raffleId2);

        // Check token ownership
        assertEq(
            mockERC721.ownerOf(erc721TokenId), winner1, "Winner 1 should own the first ERC721 token"
        );
        assertEq(
            mockERC721.ownerOf(erc721TokenId2),
            winner2,
            "Winner 2 should own the second ERC721 token"
        );

        // Withdraw funds from both raffles
        vm.startPrank(owner);
        raffleContract.withdrawFunds(raffleId1);
        raffleContract.withdrawFunds(raffleId2);
        vm.stopPrank();

        // Check balances
        assertEq(
            mockUSDC.balanceOf(address(raffleContract)),
            0,
            "Contract should have 0 USDC balance after withdrawal"
        );
        assertEq(
            mockOtherToken.balanceOf(address(raffleContract)),
            0,
            "Contract should have 0 OTHER token balance after withdrawal"
        );
    }

    function test_CancelRaffle() public {
        // Create raffle
        vm.prank(owner);
        uint256 raffleId = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId,
            1,
            ticketPrice,
            address(mockUSDC),
            minTickets,
            raffleDuration
        );

        // Buy some tickets but not enough to meet minimum
        vm.prank(user1);
        raffleContract.buyTicket(raffleId, 2);

        // Fast forward past raffle end time
        vm.warp(block.timestamp + raffleDuration + 1);

        // Cancel raffle
        vm.prank(owner);
        raffleContract.cancelRaffle(raffleId);

        // Check raffle status
        (,,,,,,,,, address winner, RaffleContract.RaffleStatus status,) =
            raffleContract.getRaffleInfo(raffleId);

        assertEq(
            uint256(status), uint256(RaffleContract.RaffleStatus.Closed), "Raffle should be closed"
        );
        assertEq(winner, address(0), "No winner should be set");

        // Check token ownership
        assertEq(mockERC721.ownerOf(erc721TokenId), owner, "Owner should get the ERC721 token back");

        // Withdraw funds
        vm.prank(owner);
        raffleContract.withdrawFunds(raffleId);

        // Check USDC balance
        assertEq(
            mockUSDC.balanceOf(address(raffleContract)),
            0,
            "Contract should have 0 USDC balance after withdrawal"
        );
    }

    function test_SellMoreThanMinimumTickets() public {
        // Create raffle
        vm.prank(owner);
        uint256 raffleId = raffleContract.createRaffle(
            RaffleContract.AssetType.ERC721,
            address(mockERC721),
            erc721TokenId,
            1,
            ticketPrice,
            address(mockUSDC),
            minTickets,
            raffleDuration
        );

        // Buy more than minimum tickets
        vm.prank(user1);
        raffleContract.buyTicket(raffleId, 4);

        vm.prank(user2);
        raffleContract.buyTicket(raffleId, 4);

        // Check ticket count
        (,,,,,,,, uint256 ticketsSold,,,) = raffleContract.getRaffleInfo(raffleId);
        assertEq(ticketsSold, 8, "Raffle should have 8 tickets sold");

        // Fast forward past raffle end time
        vm.warp(block.timestamp + raffleDuration + 1);

        // Draw winner
        vm.prank(owner);
        raffleContract.drawWinner(raffleId);

        // Check raffle status
        (,,,,,,,,, address winner, RaffleContract.RaffleStatus status,) =
            raffleContract.getRaffleInfo(raffleId);

        assertEq(
            uint256(status), uint256(RaffleContract.RaffleStatus.Closed), "Raffle should be closed"
        );
        assertTrue(winner == user1 || winner == user2, "Winner should be one of the participants");
    }
}
