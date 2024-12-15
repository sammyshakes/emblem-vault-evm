// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibErrors} from "./LibErrors.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint96 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
        // Selector cache
        mapping(address => bytes4[]) facetSelectors; // Cache of selectors per facet
        mapping(bytes4 => uint256) selectorToIndex; // Position of selector in facetSelectors array
        uint256 totalSelectors; // Total number of selectors
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        LibErrors.revertIfZeroAddress(_newOwner);
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address) {
        return diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        LibErrors.revertIfNotContractOwner(msg.sender, diamondStorage().contractOwner);
    }

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert LibErrors.InvalidFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        LibErrors.revertIfZeroAddress(_facetAddress);
        DiamondStorage storage ds = diamondStorage();
        uint96 selectorPosition = uint96(ds.facetAddresses.length);

        // Add new facet address if it does not exist
        bool facetAddressExists;
        for (uint256 i; i < ds.facetAddresses.length; i++) {
            if (ds.facetAddresses[i] == _facetAddress) {
                facetAddressExists = true;
                break;
            }
        }
        if (!facetAddressExists) {
            ds.facetAddresses.push(_facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert LibErrors.FunctionAlreadyExists(selector);
            }

            // Update selector mappings
            ds.facetAddressAndSelectorPosition[selector] =
                FacetAddressAndSelectorPosition(_facetAddress, selectorPosition);

            // Update selector cache
            ds.facetSelectors[_facetAddress].push(selector);
            ds.selectorToIndex[selector] = ds.facetSelectors[_facetAddress].length - 1;
            ds.totalSelectors++;

            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        LibErrors.revertIfZeroAddress(_facetAddress);
        DiamondStorage storage ds = diamondStorage();
        uint96 selectorPosition = uint96(ds.facetAddresses.length);

        // Add new facet address if it does not exist
        bool facetAddressExists;
        for (uint256 i; i < ds.facetAddresses.length; i++) {
            if (ds.facetAddresses[i] == _facetAddress) {
                facetAddressExists = true;
                break;
            }
        }
        if (!facetAddressExists) {
            ds.facetAddresses.push(_facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (oldFacetAddress == _facetAddress) {
                revert LibErrors.CannotReplaceSameFunction(selector);
            }
            if (oldFacetAddress == address(0)) {
                revert LibErrors.FunctionDoesNotExist(selector);
            }

            // Remove from old facet's cache
            uint256 oldSelectorIndex = ds.selectorToIndex[selector];
            bytes4[] storage oldFacetSelectorCache = ds.facetSelectors[oldFacetAddress];
            uint256 lastIndex = oldFacetSelectorCache.length - 1;
            if (oldSelectorIndex != lastIndex) {
                bytes4 lastSelector = oldFacetSelectorCache[lastIndex];
                oldFacetSelectorCache[oldSelectorIndex] = lastSelector;
                ds.selectorToIndex[lastSelector] = oldSelectorIndex;
            }
            oldFacetSelectorCache.pop();
            delete ds.selectorToIndex[selector];

            // Update selector mappings
            ds.facetAddressAndSelectorPosition[selector] =
                FacetAddressAndSelectorPosition(_facetAddress, selectorPosition);

            // Add to new facet's cache
            ds.facetSelectors[_facetAddress].push(selector);
            ds.selectorToIndex[selector] = ds.facetSelectors[_facetAddress].length - 1;

            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress != address(0)) {
            revert LibErrors.InvalidFacetCutAction(uint8(IDiamondCut.FacetCutAction.Remove));
        }
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = _functionSelectors.length;

        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address facetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;

            if (facetAddress == address(0)) {
                revert LibErrors.FunctionDoesNotExist(selector);
            }

            // Remove from facet's cache
            uint256 oldSelectorIndex = ds.selectorToIndex[selector];
            bytes4[] storage facetSelectorCache = ds.facetSelectors[facetAddress];
            uint256 lastIndex = facetSelectorCache.length - 1;
            if (oldSelectorIndex != lastIndex) {
                bytes4 lastSelector = facetSelectorCache[lastIndex];
                facetSelectorCache[oldSelectorIndex] = lastSelector;
                ds.selectorToIndex[lastSelector] = oldSelectorIndex;
            }
            facetSelectorCache.pop();
            delete ds.selectorToIndex[selector];
            delete ds.facetAddressAndSelectorPosition[selector];
            ds.totalSelectors--;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        LibErrors.revertIfInitializationInvalid(_init, _calldata);
        if (_init != address(0)) {
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                revert LibErrors.DiamondInitFailed(_init, error.length > 0 ? error : _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert LibErrors.InitializationContractEmpty(_contract);
        }
    }
}
