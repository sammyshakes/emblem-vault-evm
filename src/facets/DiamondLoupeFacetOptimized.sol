// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract DiamondLoupeFacetOptimized {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facets and their selectors
    /// @return facets_ Array of facet addresses and their selectors
    function facets() external view returns (Facet[] memory facets_) {
        // Cache storage pointer to save gas on repeated SLOADs
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address[] storage storedFacetAddresses = ds.facetAddresses;
        uint256 numFacets = storedFacetAddresses.length;
        facets_ = new Facet[](numFacets);

        // Single loop with cached storage reads
        for (uint256 i; i < numFacets;) {
            address currentFacet = storedFacetAddresses[i];
            bytes4[] storage currentSelectors = ds.facetSelectors[currentFacet];

            // Direct storage to memory copy
            facets_[i].facetAddress = currentFacet;
            facets_[i].functionSelectors = currentSelectors;

            // Cheaper increment
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet
    /// @param _facet The facet address
    /// @return selectors Function selectors array
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory selectors)
    {
        // Direct storage to memory assignment
        selectors = LibDiamond.diamondStorage().facetSelectors[_facet];
    }

    /// @notice Get all the facet addresses used in this diamond
    /// @return facetAddresses_ Array of facet addresses
    function facetAddresses() external view returns (address[] memory facetAddresses_) {
        // Direct storage to memory assignment
        facetAddresses_ = LibDiamond.diamondStorage().facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector
    /// @param _functionSelector The function selector to get the facet for
    /// @return facetAddress_ The facet address
    function getFacetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_)
    {
        // Single SLOAD with direct field access
        facetAddress_ = LibDiamond.diamondStorage().selectorToFacet[_functionSelector].facetAddress;
    }

    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier
    /// @return supported_ Whether the interface is supported
    function supportsInterface(bytes4 _interfaceId) external view returns (bool supported_) {
        // Single SLOAD
        supported_ = LibDiamond.diamondStorage().supportedInterfaces[_interfaceId];
    }

    /// @notice Gets the facets that support the given selectors in a single call
    /// @param _selectors Array of function selectors to query
    /// @return addresses Array of facet addresses
    function getFacetAddresses(bytes4[] calldata _selectors)
        external
        view
        returns (address[] memory addresses)
    {
        // Cache storage pointer
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 length = _selectors.length;
        addresses = new address[](length);

        // Single loop with unchecked increment
        for (uint256 i; i < length;) {
            addresses[i] = ds.selectorToFacet[_selectors[i]].facetAddress;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Gets function selectors for multiple facets in a single call
    /// @param _facets Array of facet addresses to query
    /// @return selectors Array of selector arrays
    function batchFacetFunctionSelectors(address[] calldata _facets)
        external
        view
        returns (bytes4[][] memory selectors)
    {
        // Cache storage pointer
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 length = _facets.length;
        selectors = new bytes4[][](length);

        // Single loop with direct storage to memory assignment
        for (uint256 i; i < length;) {
            selectors[i] = ds.facetSelectors[_facets[i]];
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Query if a contract implements multiple interfaces
    /// @param _interfaceIds Array of interface identifiers
    /// @return supported Array of support flags
    function supportsInterfaces(bytes4[] calldata _interfaceIds)
        external
        view
        returns (bool[] memory supported)
    {
        // Cache storage pointer
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 length = _interfaceIds.length;
        supported = new bool[](length);

        // Single loop with unchecked increment
        for (uint256 i; i < length;) {
            supported[i] = ds.supportedInterfaces[_interfaceIds[i]];
            unchecked {
                ++i;
            }
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
        // Cache storage pointer
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 length = _facetAddresses.length;
        facets_ = new Facet[](length);

        // Single loop with direct storage to memory assignment
        for (uint256 i; i < length;) {
            address currentFacet = _facetAddresses[i];
            facets_[i].facetAddress = currentFacet;
            facets_[i].functionSelectors = ds.facetSelectors[currentFacet];
            unchecked {
                ++i;
            }
        }
    }
}
