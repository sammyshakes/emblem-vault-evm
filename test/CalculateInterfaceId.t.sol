// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {IIsSerialized} from "../src/interfaces/IIsSerialized.sol";

contract CalculateInterfaceIdTest is Test {
    function setUp() public {}

    function testCalculateInterfaceId() public {
        // Calculate individual function selectors
        bytes4 isSerialized = bytes4(keccak256("isSerialized()"));
        bytes4 getSerial = bytes4(keccak256("getSerial(uint256,uint256)"));
        bytes4 getFirstSerialByOwner = bytes4(keccak256("getFirstSerialByOwner(address,uint256)"));
        bytes4 getOwnerOfSerial = bytes4(keccak256("getOwnerOfSerial(uint256)"));
        bytes4 getSerialByOwnerAtIndex =
            bytes4(keccak256("getSerialByOwnerAtIndex(address,uint256,uint256)"));
        bytes4 getTokenIdForSerialNumber = bytes4(keccak256("getTokenIdForSerialNumber(uint256)"));

        // XOR all selectors together
        bytes4 manualInterfaceId = isSerialized ^ getSerial ^ getFirstSerialByOwner
            ^ getOwnerOfSerial ^ getSerialByOwnerAtIndex ^ getTokenIdForSerialNumber;

        // Get interface ID using type()
        bytes4 autoInterfaceId = type(IIsSerialized).interfaceId;

        // Log both values
        console.log("Manual calculation:");
        console.logBytes4(manualInterfaceId);
        console.log("type() calculation:");
        console.logBytes4(autoInterfaceId);

        // Verify they match
        assertEq(manualInterfaceId, autoInterfaceId, "Interface IDs should match");
    }
}
