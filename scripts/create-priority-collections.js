const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("Creating Priority Collections on Merlin Chain...");

    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log(`Creating collections with account: ${deployer.address}`);

    // Read existing deployment report to get Diamond address
    const networkName = hre.network.name.toUpperCase();
    const reportPath = path.join(__dirname, "../deployment-reports", `HARDHAT_DEPLOYMENT_REPORT_${networkName}.md`);

    if (!fs.existsSync(reportPath)) {
        console.error(`Deployment report not found at ${reportPath}`);
        console.error("Please run deploy-merlin.js, deploy-vault-implementations.js, and deploy-beacon-and-factory.js first");
        process.exit(1);
    }

    const report = fs.readFileSync(reportPath, 'utf8');

    // Extract Diamond address from the report
    const diamondMatch = report.match(/Diamond.*?`(0x[a-fA-F0-9]{40})`/s);

    if (!diamondMatch) {
        console.error("Could not find Diamond address in the deployment report");
        process.exit(1);
    }

    const diamondAddress = diamondMatch[1];
    console.log(`Using Diamond: ${diamondAddress}`);

    // Get the Collection Facet by wrapping the diamond address with the EmblemVaultCollectionFacet interface
    const collectionFacet = await ethers.getContractAt("EmblemVaultCollectionFacet", diamondAddress);
    console.log("Collection Facet interface wrapped around Diamond address");

    // Collection types (from EmblemVaultCollectionFacet)
    const COLLECTION_TYPE_ERC721 = 1;
    const COLLECTION_TYPE_ERC1155 = 2;

    // Create Priority Collections based on the Foundry script
    const priorityCollections = [
        // ERC1155 Collections
        {
            name: "Rare Pepe",
            symbol: "PEPE",
            type: COLLECTION_TYPE_ERC1155
        },
        {
            name: "Spells of Genesis",
            symbol: "SOG",
            type: COLLECTION_TYPE_ERC1155
        },
        {
            name: "Fake Rares",
            symbol: "FAKE",
            type: COLLECTION_TYPE_ERC1155
        },
        // ERC721 Collections
        {
            name: "EmBells",
            symbol: "BELL",
            type: COLLECTION_TYPE_ERC721
        },
        {
            name: "Emblem Open",
            symbol: "OPEN",
            type: COLLECTION_TYPE_ERC721
        }
    ];

    const createdCollections = [];

    for (const collection of priorityCollections) {
        console.log(`\nCreating ${collection.name} (${collection.symbol}) collection...`);

        // Create the collection
        const tx = await collectionFacet.createVaultCollection(
            collection.name,
            collection.symbol,
            collection.type
        );
        const receipt = await tx.wait();

        // Find the collection address from the event logs
        const abi = ["event VaultCollectionCreated(address indexed collection, uint8 indexed collectionType, string name)"];
        const iface = new ethers.Interface(abi);

        let collectionAddress = null;
        for (const log of receipt.logs) {
            try {
                const parsedLog = iface.parseLog(log);
                if (parsedLog && parsedLog.name === "VaultCollectionCreated") {
                    collectionAddress = parsedLog.args[0];
                    break;
                }
            } catch (e) {
                // Not the event we're looking for
            }
        }

        if (!collectionAddress) {
            console.error(`Failed to find collection address for ${collection.name}`);
            continue;
        }

        console.log(`${collection.name} collection created at: ${collectionAddress}`);

        // Set collection URI based on collection type
        // Use the format from the Foundry script: BASE_URI_PREFIX + collection address + "/"
        const baseUriPrefix = "https://v2.emblemvault.io/v3/meta/";
        const uri = baseUriPrefix + collectionAddress + "/";

        if (collection.type === COLLECTION_TYPE_ERC721) {
            console.log(`Setting base URI for ${collection.name} (ERC721)...`);
            await collectionFacet.setCollectionBaseURI(
                collectionAddress,
                uri
            );
            console.log(`Base URI set for ${collection.name}: ${uri}`);
        } else {
            console.log(`Setting URI for ${collection.name} (ERC1155)...`);
            await collectionFacet.setCollectionURI(
                collectionAddress,
                uri
            );
            console.log(`URI set for ${collection.name}: ${uri}`);
        }

        createdCollections.push({
            name: collection.name,
            symbol: collection.symbol,
            type: collection.type === COLLECTION_TYPE_ERC721 ? "ERC721" : "ERC1155",
            address: collectionAddress
        });
    }

    // Update deployment report
    let collectionsSection = `## Priority Collections\n\n`;

    for (const collection of createdCollections) {
        collectionsSection += `### ${collection.name} (${collection.symbol})\n`;
        collectionsSection += `- Type: ${collection.type}\n`;
        collectionsSection += `- Address: [\`${collection.address}\`](https://scan.merlinchain.io/address/${collection.address})\n\n`;
    }

    const updatedReport = report.replace(
        /## Next Steps/,
        `${collectionsSection}## Next Steps`
    );

    fs.writeFileSync(reportPath, updatedReport);
    console.log(`\nPriority collections created! Report updated at ${reportPath}`);

    return createdCollections;
}

// Execute the deployment
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
