// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultUnvaultFacet} from "../src/facets/EmblemVaultUnvaultFacet.sol";
import {EmblemVaultCollectionFacet} from "../src/facets/EmblemVaultCollectionFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MainnetForkTest is Test {
    // Mainnet deployed addresses
    address constant DIAMOND = 0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60;
    address constant DIAMOND_HANDS_COLLECTION = 0xAfE0130Bad95763A66871e1F2fd73B8e7ee18037;
    address constant COLLECTION_FACTORY = 0x109De29e0FB4de58A66ce077253E0604D81AD14C;

    // Test addresses
    address owner;
    address user1;
    address user2;

    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        // Setup test accounts
        owner = OwnershipFacet(DIAMOND).owner();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testMainnetDeployment() public view {
        // Test Diamond Hands Collection
        bool isCollection =
            EmblemVaultCollectionFacet(DIAMOND).isCollection(DIAMOND_HANDS_COLLECTION);
        console.log("Is Collection:", isCollection);
        assertTrue(isCollection);

        uint256 collectionType =
            EmblemVaultCollectionFacet(DIAMOND).getCollectionType(DIAMOND_HANDS_COLLECTION);
        console.log("Collection Type:", collectionType);
        assertEq(collectionType, 1); // ERC721

        string memory name = IERC721Metadata(DIAMOND_HANDS_COLLECTION).name();
        console.log("Collection Name:", name);
        assertEq(name, "Diamond Hands Collection");

        string memory symbol = IERC721Metadata(DIAMOND_HANDS_COLLECTION).symbol();
        console.log("Collection Symbol:", symbol);
        assertEq(symbol, "DHC");

        // Test Factory
        address factoryAddress = EmblemVaultCollectionFacet(DIAMOND).getCollectionFactory();
        console.log("Factory Address:", factoryAddress);
        assertEq(factoryAddress, COLLECTION_FACTORY);

        // Test Facet Versions
        string memory coreVersion = EmblemVaultCoreFacet(DIAMOND).getCoreVersion();
        console.log("Core Version:", coreVersion);
        assertEq(coreVersion, "0.1.0");

        string memory collectionVersion = EmblemVaultCollectionFacet(DIAMOND).getCollectionVersion();
        console.log("Collection Version:", collectionVersion);
        assertEq(collectionVersion, "0.1.0");

        string memory mintVersion = EmblemVaultMintFacet(DIAMOND).getMintVersion();
        console.log("Mint Version:", mintVersion);
        assertEq(mintVersion, "0.1.0");

        string memory unvaultVersion = EmblemVaultUnvaultFacet(DIAMOND).getUnvaultVersion();
        console.log("Unvault Version:", unvaultVersion);
        assertEq(unvaultVersion, "0.1.0");

        string memory initVersion = EmblemVaultInitFacet(DIAMOND).getInitVersion();
        console.log("Init Version:", initVersion);
        assertEq(initVersion, "0.1.0");
    }

    function testMainnetCollectionOperations() public view {
        // Test collection owner
        address collectionOwner = Ownable(DIAMOND_HANDS_COLLECTION).owner();
        console.log("Collection Owner:", collectionOwner);
        assertEq(
            collectionOwner, 0xa99526E4Dc81b85C1d248Ca974Eadce81837eCF1, "Wrong collection owner"
        );

        // Test collection metadata
        string memory name = IERC721Metadata(DIAMOND_HANDS_COLLECTION).name();
        console.log("Collection Name:", name);
        string memory symbol = IERC721Metadata(DIAMOND_HANDS_COLLECTION).symbol();
        console.log("Collection Symbol:", symbol);

        // Test collection total supply and ownership
        uint256 balance = IERC721(DIAMOND_HANDS_COLLECTION).balanceOf(collectionOwner);
        console.log("Owner Balance:", balance);

        // Test first token if any exist
        if (balance > 0) {
            address tokenOwner = IERC721(DIAMOND_HANDS_COLLECTION).ownerOf(1);
            console.log("Token 1 Owner:", tokenOwner);
        }
    }

    function testMainnetWitnessOperations() public view {
        // Test witness count
        uint256 witnessCount = EmblemVaultCoreFacet(DIAMOND).getWitnessCount();
        console.log("Witness Count:", witnessCount);

        // Test if owner is witness
        bool isWitness = EmblemVaultCoreFacet(DIAMOND).isWitness(owner);
        console.log("Is Owner Witness:", isWitness);
        assertTrue(isWitness, "Owner should be a witness");
    }

    function testMainnetUnvaultOperations() public view {
        // Test if unvaulting is enabled
        (
            string memory baseUri,
            address recipientAddr,
            bool unvaultingEnabled,
            bool byPassable,
            uint256 witnessCount
        ) = EmblemVaultInitFacet(DIAMOND).getConfiguration();

        console.log("Base URI:", baseUri);
        console.log("Recipient Address:", recipientAddr);
        console.log("Unvaulting Enabled:", unvaultingEnabled);
        console.log("Bypassable:", byPassable);
        console.log("Witness Count:", witnessCount);

        assertFalse(byPassable, "Bypassing should be disabled by default");
    }

    function testMainnetMintOperations() public view {
        // Test collection factory
        address factoryAddress = EmblemVaultCollectionFacet(DIAMOND).getCollectionFactory();
        console.log("Factory Address:", factoryAddress);
        assertEq(factoryAddress, COLLECTION_FACTORY, "Wrong factory address");

        // Test collection verification
        bool isCollection =
            EmblemVaultCollectionFacet(DIAMOND).isCollection(DIAMOND_HANDS_COLLECTION);
        console.log("Is Collection:", isCollection);
        assertTrue(isCollection, "Should be a valid collection");
    }

    function testMainnetCollectionCreation() public view {
        // Test factory configuration
        address factoryAddress = EmblemVaultCollectionFacet(DIAMOND).getCollectionFactory();
        console.log("Factory Address:", factoryAddress);
        assertEq(factoryAddress, COLLECTION_FACTORY, "Wrong factory address");

        // Test collection type
        uint256 collectionType =
            EmblemVaultCollectionFacet(DIAMOND).getCollectionType(DIAMOND_HANDS_COLLECTION);
        console.log("Collection Type:", collectionType);
        assertEq(collectionType, 1, "Should be ERC721 type");
    }
}
