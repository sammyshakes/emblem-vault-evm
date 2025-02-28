// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IDiamondLoupe
 * @dev Interface for diamond loupe functions
 */
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Gets all facets and their selectors
     * @return facets_ Facet addresses and their function selectors
     */
    function facets() external view returns (Facet[] memory facets_);

    /**
     * @notice Gets all the function selectors provided by a facet
     * @param _facet The facet address
     * @return facetFunctionSelectors_ The selectors associated with a facet address
     */
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /**
     * @notice Get all the facet addresses used by a diamond
     * @return facetAddresses_ The facet addresses
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /**
     * @notice Gets the facet that supports the given selector
     * @param _functionSelector The function selector
     * @return facetAddress_ The facet address
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
