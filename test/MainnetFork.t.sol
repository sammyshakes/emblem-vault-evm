// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import "forge-std/Test.sol";
// import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
// import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
// import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
// import {EmblemVaultUnvaultFacet} from "../src/facets/EmblemVaultUnvaultFacet.sol";
// import {EmblemVaultCollectionFacet} from "../src/facets/EmblemVaultCollectionFacet.sol";
// import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";
// import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
// import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {IERC721AVault} from "../src/interfaces/IERC721AVault.sol";

// contract MainnetForkTest is Test {
//     // Mainnet deployed addresses
//     address immutable DIAMOND;
//     address immutable DIAMOND_HANDS_COLLECTION;
//     address immutable COLLECTION_FACTORY;

//     constructor() {
//         DIAMOND = vm.envAddress("DIAMOND_ADDRESS");
//         DIAMOND_HANDS_COLLECTION = vm.envAddress("ERC721_COLLECTION");
//         COLLECTION_FACTORY = vm.envAddress("COLLECTION_FACTORY_ADDRESS");
//     }

//     // Test addresses
//     address owner;
//     address user1;
//     address user2;

//     function setUp() public {
//         // Fork mainnet
//         vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

//         // Setup test accounts
//         owner = OwnershipFacet(DIAMOND).owner();
//         user1 = makeAddr("user1");
//         user2 = makeAddr("user2");
//         vm.deal(user1, 100 ether);
//         vm.deal(user2, 100 ether);
//     }

//     function testMainnetDeployment() public view {
//         // Test Diamond Hands Collection
//         bool isCollection =
//             EmblemVaultCollectionFacet(DIAMOND).isCollection(DIAMOND_HANDS_COLLECTION);
//         console.log("Is Collection:", isCollection);
//         assertTrue(isCollection);

//         uint256 collectionType =
//             EmblemVaultCollectionFacet(DIAMOND).getCollectionType(DIAMOND_HANDS_COLLECTION);
//         console.log("Collection Type:", collectionType);
//         assertEq(collectionType, 1); // ERC721

//         string memory name = IERC721Metadata(DIAMOND_HANDS_COLLECTION).name();
//         console.log("Collection Name:", name);
//         assertEq(name, "Diamond Hands Collection");

//         string memory symbol = IERC721Metadata(DIAMOND_HANDS_COLLECTION).symbol();
//         console.log("Collection Symbol:", symbol);
//         assertEq(symbol, "DHC");

//         // Test Factory
//         address factoryAddress = EmblemVaultCollectionFacet(DIAMOND).getCollectionFactory();
//         console.log("Factory Address:", factoryAddress);
//         assertEq(factoryAddress, COLLECTION_FACTORY);

//         // Test Facet Versions
//         string memory coreVersion = EmblemVaultCoreFacet(DIAMOND).getCoreVersion();
//         console.log("Core Version:", coreVersion);
//         assertEq(coreVersion, "0.1.0");

//         string memory collectionVersion = EmblemVaultCollectionFacet(DIAMOND).getCollectionVersion();
//         console.log("Collection Version:", collectionVersion);
//         assertEq(collectionVersion, "0.1.0");

//         string memory mintVersion = EmblemVaultMintFacet(DIAMOND).getMintVersion();
//         console.log("Mint Version:", mintVersion);
//         assertEq(mintVersion, "0.1.0");

//         string memory unvaultVersion = EmblemVaultUnvaultFacet(DIAMOND).getUnvaultVersion();
//         console.log("Unvault Version:", unvaultVersion);
//         assertEq(unvaultVersion, "0.1.0");

//         string memory initVersion = EmblemVaultInitFacet(DIAMOND).getInitVersion();
//         console.log("Init Version:", initVersion);
//         assertEq(initVersion, "0.1.0");
//     }

//     function testMainnetCollectionOperations() public view {
//         // Test collection owner
//         address collectionOwner = Ownable(DIAMOND_HANDS_COLLECTION).owner();
//         console.log("Collection Owner:", collectionOwner);
//         assertEq(
//             collectionOwner, 0xa99526E4Dc81b85C1d248Ca974Eadce81837eCF1, "Wrong collection owner"
//         );

//         // Test collection metadata
//         string memory name = IERC721Metadata(DIAMOND_HANDS_COLLECTION).name();
//         console.log("Collection Name:", name);
//         string memory symbol = IERC721Metadata(DIAMOND_HANDS_COLLECTION).symbol();
//         console.log("Collection Symbol:", symbol);

//         // Test collection total supply and ownership
//         uint256 balance = IERC721(DIAMOND_HANDS_COLLECTION).balanceOf(collectionOwner);
//         console.log("Owner Balance:", balance);

//         // Test first token if any exist
//         if (balance > 0) {
//             address tokenOwner = IERC721(DIAMOND_HANDS_COLLECTION).ownerOf(1);
//             console.log("Token 1 Owner:", tokenOwner);
//         }
//     }

//     function testMainnetWitnessOperations() public view {
//         // Test witness count
//         uint256 witnessCount = EmblemVaultCoreFacet(DIAMOND).getWitnessCount();
//         console.log("Witness Count:", witnessCount);

//         // Test if owner is witness
//         bool isWitness = EmblemVaultCoreFacet(DIAMOND).isWitness(owner);
//         console.log("Is Owner Witness:", isWitness);
//         assertTrue(isWitness, "Owner should be a witness");
//     }

//     function testMainnetUnvaultOperations() public view {
//         // Test if unvaulting is enabled
//         (
//             string memory baseUri,
//             address recipientAddr,
//             bool unvaultingEnabled,
//             bool byPassable,
//             uint256 witnessCount
//         ) = EmblemVaultInitFacet(DIAMOND).getConfiguration();

//         console.log("Base URI:", baseUri);
//         console.log("Recipient Address:", recipientAddr);
//         console.log("Unvaulting Enabled:", unvaultingEnabled);
//         console.log("Bypassable:", byPassable);
//         console.log("Witness Count:", witnessCount);

//         assertFalse(byPassable, "Bypassing should be disabled by default");
//     }

//     function testMainnetMintOperations() public view {
//         // Test collection factory
//         address factoryAddress = EmblemVaultCollectionFacet(DIAMOND).getCollectionFactory();
//         console.log("Factory Address:", factoryAddress);
//         assertEq(factoryAddress, COLLECTION_FACTORY, "Wrong factory address");

//         // Test collection verification
//         bool isCollection =
//             EmblemVaultCollectionFacet(DIAMOND).isCollection(DIAMOND_HANDS_COLLECTION);
//         console.log("Is Collection:", isCollection);
//         assertTrue(isCollection, "Should be a valid collection");
//     }

//     function testMainnetCollectionCreation() public view {
//         // Test factory configuration
//         address factoryAddress = EmblemVaultCollectionFacet(DIAMOND).getCollectionFactory();
//         console.log("Factory Address:", factoryAddress);
//         assertEq(factoryAddress, COLLECTION_FACTORY, "Wrong factory address");

//         // Test collection type
//         uint256 collectionType =
//             EmblemVaultCollectionFacet(DIAMOND).getCollectionType(DIAMOND_HANDS_COLLECTION);
//         console.log("Collection Type:", collectionType);
//         assertEq(collectionType, 1, "Should be ERC721 type");
//     }

//     function testMainnetMintWithSignedPrice() public {
//         // Get a witness private key
//         uint256 witnessKey = vm.envUint("PRIVATE_KEY");
//         address witness = vm.addr(witnessKey);

//         // Log witness details
//         console.log("Witness address:", witness);
//         console.log("Is witness authorized:", EmblemVaultCoreFacet(DIAMOND).isWitness(witness));
//         console.log("Total witness count:", EmblemVaultCoreFacet(DIAMOND).getWitnessCount());

//         // Verify witness is authorized
//         assertTrue(EmblemVaultCoreFacet(DIAMOND).isWitness(witness), "Not a valid witness");

//         // Get initial balances
//         uint256 initialBalance = IERC721(DIAMOND_HANDS_COLLECTION).balanceOf(user1);
//         uint256 initialEthBalance = user1.balance;

//         console.log("Initial NFT Balance:", initialBalance);
//         console.log("Initial ETH Balance:", initialEthBalance);

//         // Create mint parameters
//         uint256 price = 0.1 ether;
//         uint256 externalTokenId = uint256(keccak256(abi.encodePacked(block.timestamp, user1))); // Random large number
//         bytes32 salt = bytes32(uint256(200)); // Example salt

//         // Get current chainId
//         uint256 currentChainId = block.chainid;
//         console.log("Current chainId:", currentChainId);

//         // Create signature using helper function
//         bytes memory signature = createSignature(
//             DIAMOND_HANDS_COLLECTION,
//             address(0),
//             price,
//             user1,
//             externalTokenId,
//             uint256(salt),
//             1,
//             witnessKey
//         );

//         // Mint with signature
//         vm.prank(user1);
//         EmblemVaultMintFacet(DIAMOND).buyWithSignedPrice{value: price}(
//             DIAMOND_HANDS_COLLECTION, // nftAddress
//             address(0), // payment token (ETH)
//             price, // price
//             user1, // recipient
//             externalTokenId, // tokenId (external ID)
//             uint256(salt), // nonce
//             signature, // signature
//             new uint256[](0), // serialNumbers (empty for ERC721)
//             1 // amount (1 for ERC721)
//         );

//         // Verify mint was successful
//         uint256 finalBalance = IERC721(DIAMOND_HANDS_COLLECTION).balanceOf(user1);
//         uint256 finalEthBalance = user1.balance;

//         console.log("Final NFT Balance:", finalBalance);
//         console.log("Final ETH Balance:", finalEthBalance);
//         console.log("ETH Spent:", initialEthBalance - finalEthBalance);
//         console.log("External Token ID Used:", externalTokenId);

//         assertEq(finalBalance, initialBalance + 1, "NFT not minted");
//         assertEq(finalEthBalance, initialEthBalance - price, "Wrong ETH amount spent");

//         // Get the internal token ID that was mapped to our external ID
//         uint256 internalTokenId =
//             IERC721AVault(DIAMOND_HANDS_COLLECTION).getInternalTokenId(externalTokenId);
//         console.log("Internal Token ID:", internalTokenId);
//         assertEq(
//             IERC721(DIAMOND_HANDS_COLLECTION).ownerOf(internalTokenId), user1, "Wrong token owner"
//         );
//     }

//     // Helper function to create signature for standard purchases
//     function createSignature(
//         address _nftAddress,
//         address _payment,
//         uint256 _price,
//         address _to,
//         uint256 _tokenId,
//         uint256 _nonce,
//         uint256 _amount,
//         uint256 _privateKey
//     ) internal view returns (bytes memory) {
//         bytes32 hash = keccak256(
//             abi.encodePacked(
//                 _nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount, block.chainid
//             )
//         );
//         bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, prefixedHash);
//         return abi.encodePacked(r, s, v);
//     }
// }
