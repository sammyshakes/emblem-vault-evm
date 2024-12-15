// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract DiamondLoupeFacet {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facets and their selectors
    /// @return facets_ Array of facet addresses and their selectors
    function facets() external view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);

        // Initialize facets array
        for (uint256 i; i < numFacets; i++) {
            address currentFacet = ds.facetAddresses[i];
            facets_[i].facetAddress = currentFacet;
            facets_[i].functionSelectors = ds.facetSelectors[currentFacet];
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet
    /// @param _facet The facet address
    /// @return Array of function selectors
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory) {
        return LibDiamond.diamondStorage().facetSelectors[_facet];
    }

    /// @notice Get all the facet addresses used in this diamond
    /// @return Array of facet addresses
    function facetAddresses() external view returns (address[] memory) {
        return LibDiamond.diamondStorage().facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector
    /// @param _functionSelector The function selector to get the facet for
    /// @return The facet address
    function getFacetAddress(bytes4 _functionSelector) external view returns (address) {
        return LibDiamond.diamondStorage().facetAddressAndSelectorPosition[_functionSelector]
            .facetAddress;
    }

    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @return Whether the contract implements the interface
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return LibDiamond.diamondStorage().supportedInterfaces[_interfaceId];
    }
}
