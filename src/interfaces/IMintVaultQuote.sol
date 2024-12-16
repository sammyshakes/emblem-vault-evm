// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IMintVaultQuote Interface
/// @notice Interface for handling price quotes and discounts in the Emblem Vault system
/// @dev This interface manages pricing, discounts, and mint passes for the vault system
interface IMintVaultQuote {
    /// @notice Initialize the quote contract
    function initialize() external;

    /// @notice Set the trading pair address for price calculations
    /// @param _pair Address of the trading pair contract
    function setPair(address _pair) external;

    /// @notice Set the base USD price
    /// @param _usdPrice Price in USD (with decimals)
    function setUsdPrice(uint256 _usdPrice) external;

    /// @notice Add a new discount token configuration
    /// @param _discountToken Address of the token that provides a discount
    /// @param amount Amount of tokens required for the discount
    /// @param discount Discount percentage (basis points)
    function addDiscountToken(address _discountToken, uint256 amount, uint256 discount) external;

    /// @notice Update an existing discount token configuration
    /// @param index Index of the discount token to update
    /// @param _discountToken New discount token address
    /// @param amount New amount required for discount
    /// @param discount New discount percentage (basis points)
    function updateDiscountToken(
        uint256 index,
        address _discountToken,
        uint256 amount,
        uint256 discount
    ) external;

    /// @notice Remove a discount token configuration
    /// @param index Index of the discount token to remove
    function removeDiscountToken(uint256 index) external;

    /// @notice Add a new mint pass configuration
    /// @param _mintPass Address of the mint pass contract
    /// @param tokenId Token ID of the mint pass
    /// @param price Special price for mint pass holders
    function addMintPass(address _mintPass, uint256 tokenId, uint256 price) external;

    /// @notice Update an existing mint pass configuration
    /// @param index Index of the mint pass to update
    /// @param _mintPass New mint pass contract address
    /// @param tokenId New token ID
    /// @param price New special price
    function updateMintPass(uint256 index, address _mintPass, uint256 tokenId, uint256 price)
        external;

    /// @notice Remove a mint pass configuration
    /// @param index Index of the mint pass to remove
    function removeMintPass(uint256 index) external;

    /// @notice Convert a USD price to ETH
    /// @param _usdPrice Price in USD to convert
    /// @return Equivalent price in ETH
    function getUsdPriceInEth(uint256 _usdPrice) external view returns (uint256);

    /// @notice Get the current reserves of the trading pair
    /// @return reserve0 Reserve of token0
    /// @return reserve1 Reserve of token1
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    /// @notice Get the final price for a buyer considering discounts
    /// @param buyer Address of the potential buyer
    /// @param _usdPrice Base price in USD
    /// @return Final price in ETH after applying discounts
    function quoteExternalPrice(address buyer, uint256 _usdPrice) external view returns (uint256);

    /// @notice Get the stored price for a buyer
    /// @param buyer Address of the potential buyer
    /// @return Stored price in ETH
    function quoteStoredPrice(address buyer) external view returns (uint256);
}
