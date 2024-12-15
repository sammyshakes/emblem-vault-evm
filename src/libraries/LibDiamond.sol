// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibErrors} from "./LibErrors.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress; // 20 bytes
        uint32 arrayPosition; // 4 bytes
        uint32 selectorIndex; // 4 bytes
        uint32 flags; // 4 bytes (reserved for future use)
    }

    struct DiamondStorage {
        // Packed storage (32 bytes)
        address contractOwner; // 20 bytes
        uint96 totalSelectors; // 12 bytes
        // Arrays and mappings (separate slots)
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacet;
        address[] facetAddresses;
        mapping(bytes4 => bool) supportedInterfaces;
        mapping(address => bytes4[]) facetSelectors;
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
        uint32 arrayPosition = uint32(ds.facetAddresses.length);

        // Add new facet address if it does not exist
        bool facetAddressExists;
        for (uint256 i; i < ds.facetAddresses.length; i++) {
            if (ds.facetAddresses[i] == _facetAddress) {
                facetAddressExists = true;
                arrayPosition = uint32(i);
                break;
            }
        }
        if (!facetAddressExists) {
            ds.facetAddresses.push(_facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacet[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert LibErrors.FunctionAlreadyExists(selector);
            }

            // Update selector mappings
            uint32 position = uint32(ds.facetSelectors[_facetAddress].length);
            ds.selectorToFacet[selector] = FacetAddressAndPosition({
                facetAddress: _facetAddress,
                arrayPosition: arrayPosition,
                selectorIndex: position,
                flags: 0
            });

            // Update selector cache
            ds.facetSelectors[_facetAddress].push(selector);
            ds.totalSelectors++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        LibErrors.revertIfZeroAddress(_facetAddress);
        DiamondStorage storage ds = diamondStorage();
        uint32 arrayPosition = uint32(ds.facetAddresses.length);

        // Add new facet address if it does not exist
        bool facetAddressExists;
        for (uint256 i; i < ds.facetAddresses.length; i++) {
            if (ds.facetAddresses[i] == _facetAddress) {
                facetAddressExists = true;
                arrayPosition = uint32(i);
                break;
            }
        }
        if (!facetAddressExists) {
            ds.facetAddresses.push(_facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndPosition memory oldFacet = ds.selectorToFacet[selector];
            if (oldFacet.facetAddress == _facetAddress) {
                revert LibErrors.CannotReplaceSameFunction(selector);
            }
            if (oldFacet.facetAddress == address(0)) {
                revert LibErrors.FunctionDoesNotExist(selector);
            }

            // Remove from old facet's cache
            bytes4[] storage oldFacetSelectorCache = ds.facetSelectors[oldFacet.facetAddress];
            uint256 lastIndex = oldFacetSelectorCache.length - 1;
            if (oldFacet.selectorIndex != lastIndex) {
                bytes4 lastSelector = oldFacetSelectorCache[lastIndex];
                oldFacetSelectorCache[oldFacet.selectorIndex] = lastSelector;
                ds.selectorToFacet[lastSelector].selectorIndex = oldFacet.selectorIndex;
            }
            oldFacetSelectorCache.pop();
            delete ds.selectorToFacet[selector];

            // Add to new facet
            uint32 position = uint32(ds.facetSelectors[_facetAddress].length);
            ds.selectorToFacet[selector] = FacetAddressAndPosition({
                facetAddress: _facetAddress,
                arrayPosition: arrayPosition,
                selectorIndex: position,
                flags: 0
            });
            ds.facetSelectors[_facetAddress].push(selector);
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress != address(0)) {
            revert LibErrors.InvalidFacetCutAction(uint8(IDiamondCut.FacetCutAction.Remove));
        }
        DiamondStorage storage ds = diamondStorage();

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndPosition memory facetAndPosition = ds.selectorToFacet[selector];
            address facetAddress = facetAndPosition.facetAddress;

            if (facetAddress == address(0)) {
                revert LibErrors.FunctionDoesNotExist(selector);
            }

            // Remove from facet's cache
            bytes4[] storage facetSelectorCache = ds.facetSelectors[facetAddress];
            uint256 lastIndex = facetSelectorCache.length - 1;
            if (facetAndPosition.selectorIndex != lastIndex) {
                bytes4 lastSelector = facetSelectorCache[lastIndex];
                facetSelectorCache[facetAndPosition.selectorIndex] = lastSelector;
                ds.selectorToFacet[lastSelector].selectorIndex = facetAndPosition.selectorIndex;
            }
            facetSelectorCache.pop();
            delete ds.selectorToFacet[selector];
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
