const { ethers, run } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("Verifying contracts on Merlin Chain...");

    // Read deployment report to get contract addresses
    const networkName = hre.network.name.toUpperCase();
    const reportPath = path.join(__dirname, "../deployment-reports", `HARDHAT_DEPLOYMENT_REPORT_${networkName}.md`);

    if (!fs.existsSync(reportPath)) {
        console.error(`Deployment report not found at ${reportPath}`);
        console.error("Please deploy the contracts first");
        process.exit(1);
    }

    const report = fs.readFileSync(reportPath, 'utf8');

    // Extract contract addresses from the report
    const diamondMatch = report.match(/Diamond.*?`(0x[a-fA-F0-9]{40})`/s);
    const diamondCutFacetMatch = report.match(/DiamondCutFacet.*?`(0x[a-fA-F0-9]{40})`/s);
    const diamondLoupeFacetMatch = report.match(/DiamondLoupeFacet.*?`(0x[a-fA-F0-9]{40})`/s);
    const ownershipFacetMatch = report.match(/OwnershipFacet.*?`(0x[a-fA-F0-9]{40})`/s);
    const vaultCoreFacetMatch = report.match(/VaultCoreFacet.*?`(0x[a-fA-F0-9]{40})`/s);
    const unvaultFacetMatch = report.match(/UnvaultFacet.*?`(0x[a-fA-F0-9]{40})`/s);
    const mintFacetMatch = report.match(/MintFacet.*?`(0x[a-fA-F0-9]{40})`/s);
    const collectionFacetMatch = report.match(/CollectionFacet.*?`(0x[a-fA-F0-9]{40})`/s);
    const initFacetMatch = report.match(/InitFacet.*?`(0x[a-fA-F0-9]{40})`/s);
    const erc721ImplementationMatch = report.match(/ERC721 Implementation.*?`(0x[a-fA-F0-9]{40})`/s);
    const erc1155ImplementationMatch = report.match(/ERC1155 Implementation.*?`(0x[a-fA-F0-9]{40})`/s);
    const erc721BeaconMatch = report.match(/ERC721 Beacon.*?`(0x[a-fA-F0-9]{40})`/s);
    const erc1155BeaconMatch = report.match(/ERC1155 Beacon.*?`(0x[a-fA-F0-9]{40})`/s);
    const collectionFactoryMatch = report.match(/Collection Factory.*?`(0x[a-fA-F0-9]{40})`/s);

    // Verify Diamond
    if (diamondMatch && diamondCutFacetMatch) {
        const diamondAddress = diamondMatch[1];
        const diamondCutFacetAddress = diamondCutFacetMatch[1];
        console.log(`\nVerifying Diamond at ${diamondAddress}...`);
        try {
            await run("verify:verify", {
                address: diamondAddress,
                constructorArguments: [
                    await ethers.provider.getSigner(0).getAddress(), // owner
                    diamondCutFacetAddress
                ],
                contract: "src/EmblemVaultDiamond.sol:EmblemVaultDiamond"
            });
            console.log("Diamond verified successfully");
        } catch (error) {
            console.error("Error verifying Diamond:", error.message);
        }
    }

    // Verify DiamondCutFacet
    if (diamondCutFacetMatch) {
        const diamondCutFacetAddress = diamondCutFacetMatch[1];
        console.log(`\nVerifying DiamondCutFacet at ${diamondCutFacetAddress}...`);
        try {
            await run("verify:verify", {
                address: diamondCutFacetAddress,
                constructorArguments: [],
                contract: "src/facets/DiamondCutFacet.sol:DiamondCutFacet"
            });
            console.log("DiamondCutFacet verified successfully");
        } catch (error) {
            console.error("Error verifying DiamondCutFacet:", error.message);
        }
    }

    // Verify DiamondLoupeFacet
    if (diamondLoupeFacetMatch) {
        const diamondLoupeFacetAddress = diamondLoupeFacetMatch[1];
        console.log(`\nVerifying DiamondLoupeFacet at ${diamondLoupeFacetAddress}...`);
        try {
            await run("verify:verify", {
                address: diamondLoupeFacetAddress,
                constructorArguments: [],
                contract: "src/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet"
            });
            console.log("DiamondLoupeFacet verified successfully");
        } catch (error) {
            console.error("Error verifying DiamondLoupeFacet:", error.message);
        }
    }

    // Verify OwnershipFacet
    if (ownershipFacetMatch) {
        const ownershipFacetAddress = ownershipFacetMatch[1];
        console.log(`\nVerifying OwnershipFacet at ${ownershipFacetAddress}...`);
        try {
            await run("verify:verify", {
                address: ownershipFacetAddress,
                constructorArguments: [],
                contract: "src/facets/OwnershipFacet.sol:OwnershipFacet"
            });
            console.log("OwnershipFacet verified successfully");
        } catch (error) {
            console.error("Error verifying OwnershipFacet:", error.message);
        }
    }

    // Verify VaultCoreFacet
    if (vaultCoreFacetMatch) {
        const vaultCoreFacetAddress = vaultCoreFacetMatch[1];
        console.log(`\nVerifying VaultCoreFacet at ${vaultCoreFacetAddress}...`);
        try {
            await run("verify:verify", {
                address: vaultCoreFacetAddress,
                constructorArguments: [],
                contract: "src/facets/EmblemVaultCoreFacet.sol:EmblemVaultCoreFacet"
            });
            console.log("VaultCoreFacet verified successfully");
        } catch (error) {
            console.error("Error verifying VaultCoreFacet:", error.message);
        }
    }

    // Verify UnvaultFacet
    if (unvaultFacetMatch) {
        const unvaultFacetAddress = unvaultFacetMatch[1];
        console.log(`\nVerifying UnvaultFacet at ${unvaultFacetAddress}...`);
        try {
            await run("verify:verify", {
                address: unvaultFacetAddress,
                constructorArguments: [],
                contract: "src/facets/EmblemVaultUnvaultFacet.sol:EmblemVaultUnvaultFacet"
            });
            console.log("UnvaultFacet verified successfully");
        } catch (error) {
            console.error("Error verifying UnvaultFacet:", error.message);
        }
    }

    // Verify MintFacet
    if (mintFacetMatch) {
        const mintFacetAddress = mintFacetMatch[1];
        console.log(`\nVerifying MintFacet at ${mintFacetAddress}...`);
        try {
            await run("verify:verify", {
                address: mintFacetAddress,
                constructorArguments: [],
                contract: "src/facets/EmblemVaultMintFacet.sol:EmblemVaultMintFacet"
            });
            console.log("MintFacet verified successfully");
        } catch (error) {
            console.error("Error verifying MintFacet:", error.message);
        }
    }

    // Verify CollectionFacet
    if (collectionFacetMatch) {
        const collectionFacetAddress = collectionFacetMatch[1];
        console.log(`\nVerifying CollectionFacet at ${collectionFacetAddress}...`);
        try {
            await run("verify:verify", {
                address: collectionFacetAddress,
                constructorArguments: [],
                contract: "src/facets/EmblemVaultCollectionFacet.sol:EmblemVaultCollectionFacet"
            });
            console.log("CollectionFacet verified successfully");
        } catch (error) {
            console.error("Error verifying CollectionFacet:", error.message);
        }
    }

    // Verify InitFacet
    if (initFacetMatch) {
        const initFacetAddress = initFacetMatch[1];
        console.log(`\nVerifying InitFacet at ${initFacetAddress}...`);
        try {
            await run("verify:verify", {
                address: initFacetAddress,
                constructorArguments: [],
                contract: "src/facets/EmblemVaultInitFacet.sol:EmblemVaultInitFacet"
            });
            console.log("InitFacet verified successfully");
        } catch (error) {
            console.error("Error verifying InitFacet:", error.message);
        }
    }

    // Verify ERC721 Implementation
    if (erc721ImplementationMatch) {
        const erc721ImplementationAddress = erc721ImplementationMatch[1];
        console.log(`\nVerifying ERC721 Implementation at ${erc721ImplementationAddress}...`);
        try {
            await run("verify:verify", {
                address: erc721ImplementationAddress,
                constructorArguments: [],
                contract: "src/implementations/ERC721VaultImplementation.sol:ERC721VaultImplementation"
            });
            console.log("ERC721 Implementation verified successfully");
        } catch (error) {
            console.error("Error verifying ERC721 Implementation:", error.message);
        }
    }

    // Verify ERC1155 Implementation
    if (erc1155ImplementationMatch) {
        const erc1155ImplementationAddress = erc1155ImplementationMatch[1];
        console.log(`\nVerifying ERC1155 Implementation at ${erc1155ImplementationAddress}...`);
        try {
            await run("verify:verify", {
                address: erc1155ImplementationAddress,
                constructorArguments: [],
                contract: "src/implementations/ERC1155VaultImplementation.sol:ERC1155VaultImplementation"
            });
            console.log("ERC1155 Implementation verified successfully");
        } catch (error) {
            console.error("Error verifying ERC1155 Implementation:", error.message);
        }
    }

    // Verify ERC721 Beacon
    if (erc721BeaconMatch && erc721ImplementationMatch) {
        const erc721BeaconAddress = erc721BeaconMatch[1];
        const erc721ImplementationAddress = erc721ImplementationMatch[1];
        console.log(`\nVerifying ERC721 Beacon at ${erc721BeaconAddress}...`);
        try {
            await run("verify:verify", {
                address: erc721BeaconAddress,
                constructorArguments: [erc721ImplementationAddress],
                contract: "src/beacon/ERC721VaultBeacon.sol:ERC721VaultBeacon"
            });
            console.log("ERC721 Beacon verified successfully");
        } catch (error) {
            console.error("Error verifying ERC721 Beacon:", error.message);
        }
    }

    // Verify ERC1155 Beacon
    if (erc1155BeaconMatch && erc1155ImplementationMatch) {
        const erc1155BeaconAddress = erc1155BeaconMatch[1];
        const erc1155ImplementationAddress = erc1155ImplementationMatch[1];
        console.log(`\nVerifying ERC1155 Beacon at ${erc1155BeaconAddress}...`);
        try {
            await run("verify:verify", {
                address: erc1155BeaconAddress,
                constructorArguments: [erc1155ImplementationAddress],
                contract: "src/beacon/ERC1155VaultBeacon.sol:ERC1155VaultBeacon"
            });
            console.log("ERC1155 Beacon verified successfully");
        } catch (error) {
            console.error("Error verifying ERC1155 Beacon:", error.message);
        }
    }

    // Verify Collection Factory
    if (collectionFactoryMatch && erc721BeaconMatch && erc1155BeaconMatch && diamondMatch) {
        const collectionFactoryAddress = collectionFactoryMatch[1];
        const erc721BeaconAddress = erc721BeaconMatch[1];
        const erc1155BeaconAddress = erc1155BeaconMatch[1];
        const diamondAddress = diamondMatch[1];
        console.log(`\nVerifying Collection Factory at ${collectionFactoryAddress}...`);
        try {
            await run("verify:verify", {
                address: collectionFactoryAddress,
                constructorArguments: [
                    erc721BeaconAddress,
                    erc1155BeaconAddress,
                    diamondAddress
                ],
                contract: "src/factories/VaultCollectionFactory.sol:VaultCollectionFactory"
            });
            console.log("Collection Factory verified successfully");
        } catch (error) {
            console.error("Error verifying Collection Factory:", error.message);
        }
    }

    console.log("\nVerification process completed");
}

// Execute the verification
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
