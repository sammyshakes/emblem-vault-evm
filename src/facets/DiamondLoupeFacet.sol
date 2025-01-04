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
        return LibDiamond.diamondStorage().selectorToFacet[_functionSelector].facetAddress;
    }

    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @return Whether the contract implements the interface
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return LibDiamond.diamondStorage().supportedInterfaces[_interfaceId];
    }

    /// @notice Gets the facets that support the given selectors in a single call
    /// @param _selectors Array of function selectors to query
    /// @return addresses Array of facet addresses corresponding to the selectors
    function getFacetAddresses(bytes4[] calldata _selectors)
        external
        view
        returns (address[] memory addresses)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        addresses = new address[](_selectors.length);

        for (uint256 i; i < _selectors.length; i++) {
            addresses[i] = ds.selectorToFacet[_selectors[i]].facetAddress;
        }
    }

    /// @notice Gets function selectors for multiple facets in a single call
    /// @param _facets Array of facet addresses to query
    /// @return selectors Array of selector arrays corresponding to the facets
    function batchFacetFunctionSelectors(address[] calldata _facets)
        external
        view
        returns (bytes4[][] memory selectors)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        selectors = new bytes4[][](_facets.length);

        for (uint256 i; i < _facets.length; i++) {
            bytes4[] memory facetSelectors = ds.facetSelectors[_facets[i]];
            selectors[i] = new bytes4[](facetSelectors.length);
            for (uint256 j; j < facetSelectors.length; j++) {
                selectors[i][j] = facetSelectors[j];
            }
        }
    }

    /// @notice Query if a contract implements multiple interfaces in a single call
    /// @param _interfaceIds Array of interface identifiers to query
    /// @return supported Array of booleans indicating interface support
    function supportsInterfaces(bytes4[] calldata _interfaceIds)
        external
        view
        returns (bool[] memory supported)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        supported = new bool[](_interfaceIds.length);

        for (uint256 i; i < _interfaceIds.length; i++) {
            supported[i] = ds.supportedInterfaces[_interfaceIds[i]];
        }
    }

    /// @notice Gets all facets and their selectors for a list of facet addresses
    /// @param _facetAddresses Array of facet addresses to query
    /// @return facets_ Array of facets with their selectors
    function batchFacets(address[] calldata _facetAddresses)
        external
        view
        returns (Facet[] memory facets_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facets_ = new Facet[](_facetAddresses.length);

        for (uint256 i; i < _facetAddresses.length; i++) {
            address currentFacet = _facetAddresses[i];
            facets_[i].facetAddress = currentFacet;
            bytes4[] memory facetSelectors = ds.facetSelectors[currentFacet];
            facets_[i].functionSelectors = new bytes4[](facetSelectors.length);
            for (uint256 j; j < facetSelectors.length; j++) {
                facets_[i].functionSelectors[j] = facetSelectors[j];
            }
        }
    }
}
