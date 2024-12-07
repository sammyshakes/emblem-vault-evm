// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        require(_diamondCutFacet != address(0), "Diamond: Diamond Cut Facet cannot be zero address");
        require(_contractOwner != address(0), "Diamond: Owner cannot be zero address");

        LibDiamond.setContractOwner(_contractOwner);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Add ERC165 data
        ds.supportedInterfaces[0x01ffc9a7] = true; // ERC165
        ds.supportedInterfaces[0x48e2b093] = true; // DiamondCut
        ds.supportedInterfaces[0x7f5828d0] = true; // DiamondLoupe
        ds.supportedInterfaces[0x7f5828d0] = true; // ERC173

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
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
