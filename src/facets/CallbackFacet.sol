// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibVaultStorage.sol";
import "../interfaces/IHandlerCallback.sol";

contract CallbackFacet {
    event CallbackExecuted(
        address indexed _from,
        address indexed _to,
        address indexed target,
        uint256 tokenId,
        bytes4 targetFunction,
        IHandlerCallback.CallbackType _type,
        bytes returnData
    );
    event CallbackReverted(
        address indexed _from,
        address indexed _to,
        address indexed target,
        uint256 tokenId,
        bytes4 targetFunction,
        IHandlerCallback.CallbackType _type
    );
    event CallbackFailed(
        address indexed _from,
        address indexed _to,
        address indexed target,
        uint256 tokenId,
        bytes4 targetFunction,
        IHandlerCallback.CallbackType _type
    );

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier isRegisteredContract(address _contract) {
        LibVaultStorage.enforceIsRegisteredContract(_contract);
        _;
    }

    modifier isOwnerOrCallbackRegistrant(
        address _contract,
        address target,
        uint256 tokenId,
        IHandlerCallback.CallbackType _type,
        uint256 index
    ) {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        bool registrant = false;

        if (hasTokenIdCallback(_contract, target, tokenId, _type)) {
            registrant = vs.registeredCallbacks[_contract][tokenId][_type][index].registrant == msg.sender;
        } else if (hasWildcardCallback(_contract, target, _type)) {
            registrant = vs.registeredWildcardCallbacks[_contract][_type][index].registrant == msg.sender;
        }

        require(msg.sender == LibDiamond.contractOwner() || registrant, "Not owner or callback registrant");
        _;
    }

    function executeCallbacks(address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type)
        external
        isRegisteredContract(msg.sender)
    {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        if (vs.allowCallbacks) {
            IHandlerCallback.Callback[] storage callbacks = vs.registeredCallbacks[msg.sender][tokenId][_type];
            if (callbacks.length > 0) {
                executeCallbackLoop(callbacks, _from, _to, tokenId, _type);
            }

            IHandlerCallback.Callback[] storage wildcardCallbacks = vs.registeredWildcardCallbacks[msg.sender][_type];
            if (wildcardCallbacks.length > 0) {
                executeCallbackLoop(wildcardCallbacks, _from, _to, tokenId, _type);
            }
        }
    }

    function executeCallbackLoop(
        IHandlerCallback.Callback[] storage callbacks,
        address _from,
        address _to,
        uint256 tokenId,
        IHandlerCallback.CallbackType _type
    ) internal {
        for (uint256 i = 0; i < callbacks.length; ++i) {
            IHandlerCallback.Callback storage cb = callbacks[i];
            if (cb.target != address(0)) {
                (bool success, bytes memory returnData) = address(cb.target).call(
                    abi.encodePacked(cb.targetFunction, abi.encode(_from), abi.encode(_to), abi.encode(tokenId))
                );

                if (success) {
                    emit CallbackExecuted(_from, _to, cb.target, tokenId, cb.targetFunction, _type, returnData);
                } else if (cb.canRevert) {
                    emit CallbackReverted(_from, _to, cb.target, tokenId, cb.targetFunction, _type);
                    revert("Callback Reverted");
                } else {
                    emit CallbackFailed(_from, _to, cb.target, tokenId, cb.targetFunction, _type);
                }
            }
        }
    }

    function registerCallback(
        address _contract,
        address target,
        uint256 tokenId,
        IHandlerCallback.CallbackType _type,
        bytes4 _function,
        bool allowRevert
    ) external isRegisteredContract(_contract) onlyOwner {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        vs.registeredCallbacks[_contract][tokenId][_type].push(
            IHandlerCallback.Callback({
                contractAddress: _contract,
                registrant: msg.sender,
                target: target,
                targetFunction: _function,
                canRevert: allowRevert
            })
        );
    }

    function registerWildcardCallback(
        address _contract,
        address target,
        IHandlerCallback.CallbackType _type,
        bytes4 _function,
        bool allowRevert
    ) external isRegisteredContract(_contract) onlyOwner {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        vs.registeredWildcardCallbacks[_contract][_type].push(
            IHandlerCallback.Callback({
                contractAddress: _contract,
                registrant: msg.sender,
                target: target,
                targetFunction: _function,
                canRevert: allowRevert
            })
        );
    }

    function hasCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type)
        public
        view
        returns (bool)
    {
        return hasTokenIdCallback(_contract, target, tokenId, _type) || hasWildcardCallback(_contract, target, _type);
    }

    function hasTokenIdCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type)
        internal
        view
        returns (bool)
    {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        IHandlerCallback.Callback[] storage callbacks = vs.registeredCallbacks[_contract][tokenId][_type];

        for (uint256 i = 0; i < callbacks.length; ++i) {
            if (callbacks[i].target == target) {
                return true;
            }
        }
        return false;
    }

    function hasWildcardCallback(address _contract, address target, IHandlerCallback.CallbackType _type)
        internal
        view
        returns (bool)
    {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();
        IHandlerCallback.Callback[] storage callbacks = vs.registeredWildcardCallbacks[_contract][_type];

        for (uint256 i = 0; i < callbacks.length; ++i) {
            if (callbacks[i].target == target) {
                return true;
            }
        }
        return false;
    }

    function unregisterCallback(
        address _contract,
        address target,
        uint256 tokenId,
        IHandlerCallback.CallbackType _type,
        uint256 index
    ) external isOwnerOrCallbackRegistrant(_contract, target, tokenId, _type, index) {
        LibVaultStorage.VaultStorage storage vs = LibVaultStorage.vaultStorage();

        if (hasTokenIdCallback(_contract, target, tokenId, _type)) {
            IHandlerCallback.Callback[] storage arr = vs.registeredCallbacks[_contract][tokenId][_type];
            arr[index] = arr[arr.length - 1];
            arr.pop();
        } else if (hasWildcardCallback(_contract, target, _type)) {
            IHandlerCallback.Callback[] storage arr = vs.registeredWildcardCallbacks[_contract][_type];
            arr[index] = arr[arr.length - 1];
            arr.pop();
        }
    }

    function toggleAllowCallbacks() external onlyOwner {
        LibVaultStorage.toggleAllowCallbacks();
    }
}
