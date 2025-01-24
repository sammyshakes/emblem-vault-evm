// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/IERC165.sol";

contract MockClaimer is IERC165 {
    mapping(address => mapping(uint256 => bool)) private _claimed;

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    function isClaimed(address _nftAddress, uint256 tokenId, bytes32[] memory)
        external
        view
        returns (bool)
    {
        return _claimed[_nftAddress][tokenId];
    }

    function claim(address _nftAddress, uint256 tokenId, address) external {
        _claimed[_nftAddress][tokenId] = true;
    }
}
