const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("Deploying Complete System to Merlin Chain...");

    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying with account: ${deployer.address}`);

    // Create deployment report directory if it doesn't exist
    const reportDir = path.join(__dirname, "../deployment-reports");
    if (!fs.existsSync(reportDir)) {
        fs.mkdirSync(reportDir, { recursive: true });
    }

    const networkName = hre.network.name.toUpperCase();
    const reportPath = path.join(reportDir, `HARDHAT_DEPLOYMENT_REPORT_${networkName}.md`);

    // Step 1: Deploy Diamond System
    console.log("\n=== Step 1: Deploying Diamond System ===");

    // Deploy facets
    console.log("\nDeploying facets...");

    console.log("Deploying DiamondCutFacet...");
    const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");

    // Estimate gas for deployment
    const deploymentData = DiamondCutFacet.interface.encodeDeploy([]);
    const estimatedGas = await ethers.provider.estimateGas({
        data: deploymentData
    });

    // Get gas price
    const gasPrice = await ethers.provider.getFeeData();

    // Calculate cost in ETH
    const costInWei = estimatedGas * gasPrice.gasPrice;
    const costInEth = ethers.formatEther(costInWei);

    console.log(`Estimated gas for DiamondCutFacet deployment: ${estimatedGas}`);
    console.log(`Estimated cost in ETH: ${costInEth}`);

    // Check balance
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log(`Current balance: ${ethers.formatEther(balance)} ETH`);

    // Deploy if we have enough balance
    if (balance < costInWei) {
        console.error(`Insufficient funds. Need at least ${costInEth} ETH, but have ${ethers.formatEther(balance)} ETH`);
        process.exit(1);
    }

    const diamondCutFacet = await DiamondCutFacet.deploy();
    await diamondCutFacet.waitForDeployment();
    const diamondCutFacetAddress = await diamondCutFacet.getAddress();
    console.log(`DiamondCutFacet deployed to: ${diamondCutFacetAddress}`);

    console.log("Deploying DiamondLoupeFacet...");
    const DiamondLoupeFacet = await ethers.getContractFactory("DiamondLoupeFacet");
    const diamondLoupeFacet = await DiamondLoupeFacet.deploy();
    await diamondLoupeFacet.waitForDeployment();
    const diamondLoupeFacetAddress = await diamondLoupeFacet.getAddress();
    console.log(`DiamondLoupeFacet deployed to: ${diamondLoupeFacetAddress}`);

    console.log("Deploying OwnershipFacet...");
    const OwnershipFacet = await ethers.getContractFactory("OwnershipFacet");
    const ownershipFacet = await OwnershipFacet.deploy();
    await ownershipFacet.waitForDeployment();
    const ownershipFacetAddress = await ownershipFacet.getAddress();
    console.log(`OwnershipFacet deployed to: ${ownershipFacetAddress}`);

    console.log("Deploying EmblemVaultCoreFacet...");
    const VaultCoreFacet = await ethers.getContractFactory("EmblemVaultCoreFacet");
    const vaultCoreFacet = await VaultCoreFacet.deploy();
    await vaultCoreFacet.waitForDeployment();
    const vaultCoreFacetAddress = await vaultCoreFacet.getAddress();
    console.log(`EmblemVaultCoreFacet deployed to: ${vaultCoreFacetAddress}`);

    console.log("Deploying EmblemVaultUnvaultFacet...");
    const UnvaultFacet = await ethers.getContractFactory("EmblemVaultUnvaultFacet");
    const unvaultFacet = await UnvaultFacet.deploy();
    await unvaultFacet.waitForDeployment();
    const unvaultFacetAddress = await unvaultFacet.getAddress();
    console.log(`EmblemVaultUnvaultFacet deployed to: ${unvaultFacetAddress}`);

    console.log("Deploying EmblemVaultMintFacet...");
    const MintFacet = await ethers.getContractFactory("EmblemVaultMintFacet");
    const mintFacet = await MintFacet.deploy();
    await mintFacet.waitForDeployment();
    const mintFacetAddress = await mintFacet.getAddress();
    console.log(`EmblemVaultMintFacet deployed to: ${mintFacetAddress}`);

    console.log("Deploying EmblemVaultCollectionFacet...");
    const CollectionFacet = await ethers.getContractFactory("EmblemVaultCollectionFacet");
    const collectionFacet = await CollectionFacet.deploy();
    await collectionFacet.waitForDeployment();
    const collectionFacetAddress = await collectionFacet.getAddress();
    console.log(`EmblemVaultCollectionFacet deployed to: ${collectionFacetAddress}`);

    console.log("Deploying EmblemVaultInitFacet...");
    const InitFacet = await ethers.getContractFactory("EmblemVaultInitFacet");
    const initFacet = await InitFacet.deploy();
    await initFacet.waitForDeployment();
    const initFacetAddress = await initFacet.getAddress();
    console.log(`EmblemVaultInitFacet deployed to: ${initFacetAddress}`);

    // Deploy Diamond
    console.log("\nDeploying Diamond...");
    const Diamond = await ethers.getContractFactory("EmblemVaultDiamond");
    const diamond = await Diamond.deploy(deployer.address, diamondCutFacetAddress);
    await diamond.waitForDeployment();
    const diamondAddress = await diamond.getAddress();
    console.log(`Diamond deployed to: ${diamondAddress}`);

    // Prepare diamond cut
    console.log("\nPreparing diamond cut...");
    const diamondCut = await ethers.getContractAt("DiamondCutFacet", diamondAddress);
    const diamondLoupe = await ethers.getContractAt("DiamondLoupeFacet", diamondAddress);
    const ownership = await ethers.getContractAt("OwnershipFacet", diamondAddress);
    const vaultCore = await ethers.getContractAt("EmblemVaultCoreFacet", diamondAddress);
    const unvault = await ethers.getContractAt("EmblemVaultUnvaultFacet", diamondAddress);
    const mint = await ethers.getContractAt("EmblemVaultMintFacet", diamondAddress);
    const collectionFacetContract = await ethers.getContractAt("EmblemVaultCollectionFacet", diamondAddress);
    const init = await ethers.getContractAt("EmblemVaultInitFacet", diamondAddress);

    // Get function selectors
    const getSelectors = (contract) => {
        const signatures = [];
        for (const key in contract.interface.fragments) {
            const fragment = contract.interface.fragments[key];
            if (fragment.type === 'function') {
                // Skip the selector that's causing the error
                if (fragment.selector !== '0xcfdbf254') {
                    signatures.push(fragment.selector);
                }
            }
        }
        return signatures;
    };

    const facetCuts = [
        {
            facetAddress: diamondLoupeFacetAddress,
            action: 0, // Add
            functionSelectors: getSelectors(diamondLoupe)
        },
        {
            facetAddress: ownershipFacetAddress,
            action: 0, // Add
            functionSelectors: getSelectors(ownership)
        },
        {
            facetAddress: vaultCoreFacetAddress,
            action: 0, // Add
            functionSelectors: getSelectors(vaultCore)
        },
        {
            facetAddress: unvaultFacetAddress,
            action: 0, // Add
            functionSelectors: getSelectors(unvault)
        },
        {
            facetAddress: mintFacetAddress,
            action: 0, // Add
            functionSelectors: getSelectors(mint)
        },
        {
            facetAddress: collectionFacetAddress,
            action: 0, // Add
            functionSelectors: getSelectors(collectionFacetContract)
        },
        {
            facetAddress: initFacetAddress,
            action: 0, // Add
            functionSelectors: getSelectors(init)
        }
    ];

    // Add facets to diamond
    console.log("\nAdding facets to diamond...");
    // Debug init interface
    console.log("Checking init interface...");
    console.log("Init interface:", init.interface ? "exists" : "does not exist");

    // Skip initialization in the diamond cut
    const tx = await diamondCut.diamondCut(
        facetCuts,
        ethers.ZeroAddress, // No initialization address
        "0x" // No initialization calldata
    );
    await tx.wait();
    console.log("Facets added to diamond");

    // Initialize diamond
    console.log("\nInitializing diamond...");
    const initTx = await init.initialize(deployer.address);
    await initTx.wait();
    console.log("Diamond initialized");

    // Create initial deployment report
    const initialReport = `# ${networkName} Deployment Report (Hardhat)

## Network Information
- Network: ${hre.network.name}
- Chain ID: ${hre.network.config.chainId}

## Deployed Contracts

### Core Diamond System
- Diamond: [\`${diamondAddress}\`](https://scan.merlinchain.io/address/${diamondAddress})
- DiamondCutFacet: [\`${diamondCutFacetAddress}\`](https://scan.merlinchain.io/address/${diamondCutFacetAddress})
- DiamondLoupeFacet: [\`${diamondLoupeFacetAddress}\`](https://scan.merlinchain.io/address/${diamondLoupeFacetAddress})
- OwnershipFacet: [\`${ownershipFacetAddress}\`](https://scan.merlinchain.io/address/${ownershipFacetAddress})

### Vault Facets
- VaultCoreFacet: [\`${vaultCoreFacetAddress}\`](https://scan.merlinchain.io/address/${vaultCoreFacetAddress})
- UnvaultFacet: [\`${unvaultFacetAddress}\`](https://scan.merlinchain.io/address/${unvaultFacetAddress})
- MintFacet: [\`${mintFacetAddress}\`](https://scan.merlinchain.io/address/${mintFacetAddress})
- CollectionFacet: [\`${collectionFacetAddress}\`](https://scan.merlinchain.io/address/${collectionFacetAddress})
- InitFacet: [\`${initFacetAddress}\`](https://scan.merlinchain.io/address/${initFacetAddress})

## Deployment Timestamp
${new Date().toISOString()}

## Next Steps
1. Deploy Vault Implementations
2. Deploy Beacon System (ERC721 & ERC1155 Beacons)
3. Deploy Collection Factory
4. Connect Factory to Diamond
5. Deploy Priority Collections
`;

    fs.writeFileSync(reportPath, initialReport);
    console.log(`\nDiamond System deployment complete! Report saved to ${reportPath}`);

    // Step 2: Deploy Vault Implementations
    console.log("\n=== Step 2: Deploying Vault Implementations ===");

    // Deploy ERC721 Vault Implementation
    console.log("\nDeploying ERC721 Vault Implementation...");
    const ERC721VaultImplementation = await ethers.getContractFactory("ERC721VaultImplementation");
    const erc721Implementation = await ERC721VaultImplementation.deploy();
    await erc721Implementation.waitForDeployment();
    const erc721ImplementationAddress = await erc721Implementation.getAddress();
    console.log(`ERC721 Vault Implementation deployed to: ${erc721ImplementationAddress}`);

    // Deploy ERC1155 Vault Implementation
    console.log("\nDeploying ERC1155 Vault Implementation...");
    const ERC1155VaultImplementation = await ethers.getContractFactory("ERC1155VaultImplementation");
    const erc1155Implementation = await ERC1155VaultImplementation.deploy();
    await erc1155Implementation.waitForDeployment();
    const erc1155ImplementationAddress = await erc1155Implementation.getAddress();
    console.log(`ERC1155 Vault Implementation deployed to: ${erc1155ImplementationAddress}`);

    // Update deployment report with implementation addresses
    let report = fs.readFileSync(reportPath, 'utf8');
    const implementationsSection = `## Vault Implementation Addresses

### ERC721 Implementation
- Address: [\`${erc721ImplementationAddress}\`](https://scan.merlinchain.io/address/${erc721ImplementationAddress})

### ERC1155 Implementation
- Address: [\`${erc1155ImplementationAddress}\`](https://scan.merlinchain.io/address/${erc1155ImplementationAddress})

`;

    report = report.replace(
        /## Next Steps/,
        `${implementationsSection}## Next Steps`
    );
    fs.writeFileSync(reportPath, report);
    console.log(`\nVault Implementations deployment complete! Report updated at ${reportPath}`);

    // Step 3: Deploy Beacon System and Collection Factory
    console.log("\n=== Step 3: Deploying Beacon System and Collection Factory ===");

    // Deploy ERC721 Beacon
    console.log("\nDeploying ERC721 Beacon...");
    const ERC721VaultBeacon = await ethers.getContractFactory("ERC721VaultBeacon");
    const erc721Beacon = await ERC721VaultBeacon.deploy(erc721ImplementationAddress, { gasLimit: 5000000 });
    await erc721Beacon.waitForDeployment();
    const erc721BeaconAddress = await erc721Beacon.getAddress();
    console.log(`ERC721 Beacon deployed to: ${erc721BeaconAddress}`);

    // Deploy ERC1155 Beacon
    console.log("\nDeploying ERC1155 Beacon...");
    const ERC1155VaultBeacon = await ethers.getContractFactory("ERC1155VaultBeacon");
    const erc1155Beacon = await ERC1155VaultBeacon.deploy(erc1155ImplementationAddress, { gasLimit: 5000000 });
    await erc1155Beacon.waitForDeployment();
    const erc1155BeaconAddress = await erc1155Beacon.getAddress();
    console.log(`ERC1155 Beacon deployed to: ${erc1155BeaconAddress}`);

    // Deploy Collection Factory
    console.log("\nDeploying Collection Factory...");
    const CollectionFactory = await ethers.getContractFactory("VaultCollectionFactory");
    const collectionFactory = await CollectionFactory.deploy(
        erc721BeaconAddress,
        erc1155BeaconAddress,
        diamondAddress
    );
    await collectionFactory.waitForDeployment();
    const collectionFactoryAddress = await collectionFactory.getAddress();
    console.log(`Collection Factory deployed to: ${collectionFactoryAddress}`);

    // Set Collection Factory in Diamond
    console.log("\nSetting Collection Factory in Diamond...");
    const diamondCollectionFacet = await ethers.getContractAt("EmblemVaultCollectionFacet", diamondAddress);
    const setFactoryTx = await diamondCollectionFacet.setCollectionFactory(collectionFactoryAddress);
    await setFactoryTx.wait();
    console.log("Collection Factory set in Diamond");

    // Update deployment report with beacon system addresses
    report = fs.readFileSync(reportPath, 'utf8');
    const beaconSystemSection = `## Beacon System Addresses

### ERC721 Beacon
- Address: [\`${erc721BeaconAddress}\`](https://scan.merlinchain.io/address/${erc721BeaconAddress})

### ERC1155 Beacon
- Address: [\`${erc1155BeaconAddress}\`](https://scan.merlinchain.io/address/${erc1155BeaconAddress})

### Collection Factory
- Address: [\`${collectionFactoryAddress}\`](https://scan.merlinchain.io/address/${collectionFactoryAddress})

`;

    report = report.replace(
        /## Next Steps/,
        `${beaconSystemSection}## Next Steps`
    );
    fs.writeFileSync(reportPath, report);
    console.log(`\nBeacon System deployment complete! Report updated at ${reportPath}`);

    // Step 4: Create Priority Collections
    console.log("\n=== Step 4: Creating Priority Collections ===");

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
        const tx = await diamondCollectionFacet.createVaultCollection(
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
            await diamondCollectionFacet.setCollectionBaseURI(
                collectionAddress,
                uri
            );
            console.log(`Base URI set for ${collection.name}: ${uri}`);
        } else {
            console.log(`Setting URI for ${collection.name} (ERC1155)...`);
            await diamondCollectionFacet.setCollectionURI(
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

    // Update deployment report with collection addresses
    report = fs.readFileSync(reportPath, 'utf8');
    let collectionsSection = `## Priority Collections\n\n`;

    for (const collection of createdCollections) {
        collectionsSection += `### ${collection.name} (${collection.symbol})\n`;
        collectionsSection += `- Type: ${collection.type}\n`;
        collectionsSection += `- Address: [\`${collection.address}\`](https://scan.merlinchain.io/address/${collection.address})\n\n`;
    }

    report = report.replace(
        /## Next Steps/,
        `${collectionsSection}## Next Steps`
    );
    fs.writeFileSync(reportPath, report);
    console.log(`\nPriority collections created! Report updated at ${reportPath}`);

    console.log("\n=== Complete System Deployment Finished ===");
    console.log(`Deployment report saved to ${reportPath}`);

    return {
        diamond: diamondAddress,
        erc721Implementation: erc721ImplementationAddress,
        erc1155Implementation: erc1155ImplementationAddress,
        erc721Beacon: erc721BeaconAddress,
        erc1155Beacon: erc1155BeaconAddress,
        collectionFactory: collectionFactoryAddress,
        collections: createdCollections
    };
}

// Execute the deployment
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
