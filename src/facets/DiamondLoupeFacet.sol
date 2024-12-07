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
            facets_[i].functionSelectors = new bytes4[](0);
        }

        // Populate selectors for each facet
        for (uint256 i; i < numFacets; i++) {
            address currentFacet = ds.facetAddresses[i];
            bytes4[] memory selectors = new bytes4[](0);
            uint256 selectorCount;

            // Count selectors for this facet
            for (uint256 selectorIndex; selectorIndex < type(uint32).max; selectorIndex++) {
                bytes4 selector = bytes4(keccak256(abi.encodePacked(selectorIndex)));
                if (ds.facetAddressAndSelectorPosition[selector].facetAddress == currentFacet) {
                    selectorCount++;
                }
            }

            // Resize selectors array
            selectors = new bytes4[](selectorCount);

            // Populate selectors
            uint256 selectorPosition;
            for (uint256 selectorIndex; selectorIndex < type(uint32).max; selectorIndex++) {
                bytes4 selector = bytes4(keccak256(abi.encodePacked(selectorIndex)));
                if (ds.facetAddressAndSelectorPosition[selector].facetAddress == currentFacet) {
                    selectors[selectorPosition] = selector;
                    selectorPosition++;
                    if (selectorPosition == selectorCount) break;
                }
            }

            facets_[i].functionSelectors = selectors;
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet
    /// @param _facet The facet address
    /// @return facetFunctionSelectors_ Array of function selectors
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Count selectors for this facet
        uint256 numSelectors;
        for (uint256 selectorIndex; selectorIndex < type(uint32).max; selectorIndex++) {
            bytes4 selector = bytes4(keccak256(abi.encodePacked(selectorIndex)));
            if (ds.facetAddressAndSelectorPosition[selector].facetAddress == _facet) {
                numSelectors++;
            }
        }

        // Allocate array
        facetFunctionSelectors_ = new bytes4[](numSelectors);

        // Populate array
        uint256 selectorPosition;
        for (uint256 selectorIndex; selectorIndex < type(uint32).max; selectorIndex++) {
            bytes4 selector = bytes4(keccak256(abi.encodePacked(selectorIndex)));
            if (ds.facetAddressAndSelectorPosition[selector].facetAddress == _facet) {
                facetFunctionSelectors_[selectorPosition] = selector;
                selectorPosition++;
                if (selectorPosition == numSelectors) break;
            }
        }
    }

    /// @notice Get all the facet addresses used in this diamond
    /// @return facetAddresses_ Array of facet addresses
    function facetAddresses() external view returns (address[] memory) {
        return LibDiamond.diamondStorage().facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector
    /// @param _functionSelector The function selector to get the facet for
    /// @return facetAddress_ The facet address
    function getFacetAddress(bytes4 _functionSelector) external view returns (address) {
        return LibDiamond.diamondStorage().facetAddressAndSelectorPosition[_functionSelector].facetAddress;
    }

    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @return bool Whether the contract implements the interface
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return LibDiamond.diamondStorage().supportedInterfaces[_interfaceId];
    }
}
