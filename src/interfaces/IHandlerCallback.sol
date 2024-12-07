// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IHandlerCallback {
    enum CallbackType {
        TRANSFER,
        MINT,
        BURN,
        CLAIM
    }

    struct Callback {
        address contractAddress;
        address registrant;
        address target;
        bytes4 targetFunction;
        bool canRevert;
    }
}
