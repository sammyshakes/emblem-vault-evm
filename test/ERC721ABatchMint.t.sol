// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import "forge-std/Test.sol";
// import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
// import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
// import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
// import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
// import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
// import {EmblemVaultCollectionFacet} from "../src/facets/EmblemVaultCollectionFacet.sol";
// import {VaultBeacon} from "../src/beacon/VaultBeacon.sol";
// import {ERC721VaultImplementation} from "../src/implementations/ERC721VaultImplementation.sol";
// import {ERC1155VaultImplementation} from "../src/implementations/ERC1155VaultImplementation.sol";
// import {VaultCollectionFactory} from "../src/factories/VaultCollectionFactory.sol";
// import {ERC721AUpgradeable} from "ERC721A-Upgradeable/ERC721AUpgradeable.sol";
// import {IERC721AVault} from "../src/interfaces/IERC721AVault.sol";
// import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
// import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

// contract ERC721ABatchMintTest is Test {
//     EmblemVaultDiamond diamond;
//     EmblemVaultMintFacet mintFacet;
//     EmblemVaultCollectionFacet collectionFacet;
//     address owner = address(0x123);
//     address recipient = address(0x456);
//     address nftCollection;
//     IERC721AVault vault;

//     function setUp() public {
//         // Deploy implementations
//         ERC721VaultImplementation erc721Implementation = new ERC721VaultImplementation();
//         ERC1155VaultImplementation erc1155Implementation = new ERC1155VaultImplementation();

//         // Deploy beacons
//         VaultBeacon erc721Beacon = new VaultBeacon(address(erc721Implementation));
//         VaultBeacon erc1155Beacon = new VaultBeacon(address(erc1155Implementation));

//         // Deploy facets
//         DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
//         DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
//         OwnershipFacet ownershipFacet = new OwnershipFacet();
//         mintFacet = new EmblemVaultMintFacet();
//         collectionFacet = new EmblemVaultCollectionFacet();

//         // Deploy Diamond with cut facet
//         diamond = new EmblemVaultDiamond(owner, address(diamondCutFacet));

//         // Add facets to diamond
//         IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](4);
//         cut[0] = IDiamondCut.FacetCut({
//             facetAddress: address(diamondLoupeFacet),
//             action: IDiamondCut.FacetCutAction.Add,
//             functionSelectors: getSelec

//         });
//         cut[1] = IDiamondCut.FacetCut({
//             facetAddress: address(ownershipFacet),
//             action: IDiamondCut.FacetCutAction.Add,
//             functionSelectors: getSelectors(ownershipFacet)
//         });
//         cut[2] = IDiamondCut.FacetCut({
//             facetAddress: address(mintFacet),
//             action: IDiamondCut.FacetCutAction.Add,
//             functionSelectors: getSelectors(mintFacet)
//         });
//         cut[3] = IDiamondCut.FacetCut({
//             facetAddress: address(collectionFacet),
//             action: IDiamondCut.FacetCutAction.Add,
//             functionSelectors: getSelectors(collectionFacet)
//         });
//         IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

//         // Deploy factory
//         VaultCollectionFactory factory = new VaultCollectionFactory(
//             address(erc721Beacon), address(erc1155Beacon), address(diamond)
//         );

//         // Set factory in diamond
//         vm.prank(owner);
//         collectionFacet.setCollectionFactory(address(factory));

//         // Create test collection through diamond
//         vm.prank(owner);
//         nftCollection = collectionFacet.createVaultCollection("TestNFT", "TNFT");
//     }

//     function getSelectors(address facet) internal pure returns (bytes4[] memory) {
//         return IDiamondLoupe(facet).facetFunctionSelectors(facet);
//     }

//     function testBatchMint() public {
//         uint256[] memory tokenIds = new uint256[](3);
//         tokenIds[0] = 1;
//         tokenIds[1] = 2;
//         tokenIds[2] = 3;

//         vm.prank(owner);
//         vault.batchMint(recipient, tokenIds);

//         assertEq(vault.balanceOf(recipient), 3);
//         assertEq(vault.ownerOf(1), recipient);
//         assertEq(vault.ownerOf(2), recipient);
//         assertEq(vault.ownerOf(3), recipient);

//         assertEq(vault.getExternalTokenId(1), 1);
//         assertEq(vault.getExternalTokenId(2), 2);
//         assertEq(vault.getExternalTokenId(3), 3);
//     }

//     function testBatchMintWithData() public {
//         uint256[] memory tokenIds = new uint256[](2);
//         tokenIds[0] = 4;
//         tokenIds[1] = 5;
//         bytes memory data = "test data";

//         vm.prank(owner);
//         vault.batchMintWithData(recipient, tokenIds, data);

//         assertEq(vault.balanceOf(recipient), 2);
//         assertEq(vault.ownerOf(4), recipient);
//         assertEq(vault.ownerOf(5), recipient);
//     }

//     function testBatchMintDuplicateTokenIds() public {
//         uint256[] memory tokenIds = new uint256[](2);
//         tokenIds[0] = 6;
//         tokenIds[1] = 6;

//         vm.prank(owner);
//         vm.expectRevert(abi.encodeWithSignature("ExternalIdAlreadyMinted()"));
//         vault.batchMint(recipient, tokenIds);
//     }

//     function testBatchMintEmptyArray() public {
//         uint256[] memory tokenIds = new uint256[](0);

//         vm.prank(owner);
//         vm.expectRevert("Empty arrays");
//         vault.batchMint(recipient, tokenIds);
//     }

//     function testBatchMintNotOwner() public {
//         uint256[] memory tokenIds = new uint256[](1);
//         tokenIds[0] = 7;

//         vm.expectRevert(
//             abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", address(this))
//         );
//         vault.batchMint(recipient, tokenIds);
//     }
// }
