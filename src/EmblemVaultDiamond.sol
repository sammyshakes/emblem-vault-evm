// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {LibErrors} from "./libraries/LibErrors.sol";
import {LibInterfaceIds} from "./libraries/LibInterfaceIds.sol";

contract EmblemVaultDiamond {
    /// @notice Initialization guard with minimal storage impact
    bool private initialized;

    /// @notice Modifier to prevent re-initialization
    modifier initializer() {
        if (initialized) revert LibErrors.AlreadyInitialized();
        initialized = true;
        _;
    }

    constructor(address _contractOwner, address _diamondCutFacet) payable initializer {
        LibErrors.revertIfZeroAddress(_diamondCutFacet);
        LibErrors.revertIfZeroAddress(_contractOwner);

        LibDiamond.setContractOwner(_contractOwner);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Register standard diamond interfaces
        LibInterfaceIds.registerDiamondInterfaces(ds.supportedInterfaces);

        // Add diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = IDiamondCut.diamondCut.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        // Initialize the diamond cut
        LibDiamond.diamondCut(cut, address(0), new bytes(0));
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;

        // Get diamond storage
        assembly {
            ds.slot := position
        }

        // Get facet from function selector
        address facet = ds.selectorToFacet[msg.sig].facetAddress;
        LibErrors.revertIfFunctionNotFound(msg.sig, facet);

        // Execute external function from facet using delegatecall
        assembly {
            // Copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())

            // Execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)

            // Copy the returned data
            returndatacopy(0, 0, returndatasize())

            // Return or revert
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice Allow the contract to receive ETH
    receive() external payable {}
}
