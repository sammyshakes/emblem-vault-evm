const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("Deploying Beacon System and Collection Factory to Merlin Chain...");

    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying with account: ${deployer.address}`);

    // Read existing deployment report to get implementation addresses
    const networkName = hre.network.name.toUpperCase();
    const reportPath = path.join(__dirname, "../deployment-reports", `HARDHAT_DEPLOYMENT_REPORT_${networkName}.md`);

    if (!fs.existsSync(reportPath)) {
        console.error(`Deployment report not found at ${reportPath}`);
        console.error("Please run deploy-merlin.js and deploy-vault-implementations.js first");
        process.exit(1);
    }

    const report = fs.readFileSync(reportPath, 'utf8');

    // Extract implementation addresses from the report
    const erc721ImplementationMatch = report.match(/ERC721 Implementation.*?`(0x[a-fA-F0-9]{40})`/s);
    const erc1155ImplementationMatch = report.match(/ERC1155 Implementation.*?`(0x[a-fA-F0-9]{40})`/s);
    const diamondMatch = report.match(/Diamond.*?`(0x[a-fA-F0-9]{40})`/s);

    if (!erc721ImplementationMatch || !erc1155ImplementationMatch || !diamondMatch) {
        console.error("Could not find implementation addresses in the deployment report");
        process.exit(1);
    }

    const erc721ImplementationAddress = erc721ImplementationMatch[1];
    const erc1155ImplementationAddress = erc1155ImplementationMatch[1];
    const diamondAddress = diamondMatch[1];

    console.log(`Using ERC721 Implementation: ${erc721ImplementationAddress}`);
    console.log(`Using ERC1155 Implementation: ${erc1155ImplementationAddress}`);
    console.log(`Using Diamond: ${diamondAddress}`);

    // Define the ABI for the VaultBeacon contract
    const VaultBeaconABI = [
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "_implementation",
                    "type": "address"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "constructor"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "oldImplementation",
                    "type": "address"
                },
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "newImplementation",
                    "type": "address"
                }
            ],
            "name": "ImplementationUpgraded",
            "type": "event"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "previousOwner",
                    "type": "address"
                },
                {
                    "indexed": true,
                    "internalType": "address",
                    "name": "newOwner",
                    "type": "address"
                }
            ],
            "name": "OwnershipTransferred",
            "type": "event"
        },
        {
            "inputs": [],
            "name": "implementation",
            "outputs": [
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "owner",
            "outputs": [
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "bytes4",
                    "name": "interfaceId",
                    "type": "bytes4"
                }
            ],
            "name": "supportsInterface",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "pure",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "newOwner",
                    "type": "address"
                }
            ],
            "name": "transferOwnership",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "newImplementation",
                    "type": "address"
                }
            ],
            "name": "upgrade",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        }
    ];

    // 1. Deploy ERC721 Beacon
    console.log("\nDeploying ERC721 Beacon...");
    const ERC721VaultBeaconFactory = await ethers.getContractFactory("ERC721VaultBeacon");
    const erc721Beacon = await ERC721VaultBeaconFactory.deploy(erc721ImplementationAddress, { gasLimit: 5000000 });
    await erc721Beacon.waitForDeployment();
    const erc721BeaconAddress = await erc721Beacon.getAddress();
    console.log(`ERC721 Beacon deployed to: ${erc721BeaconAddress}`);

    // 2. Deploy ERC1155 Beacon
    console.log("\nDeploying ERC1155 Beacon...");
    const ERC1155VaultBeaconFactory = await ethers.getContractFactory("ERC1155VaultBeacon");
    const erc1155Beacon = await ERC1155VaultBeaconFactory.deploy(erc1155ImplementationAddress, { gasLimit: 5000000 });
    await erc1155Beacon.waitForDeployment();
    const erc1155BeaconAddress = await erc1155Beacon.getAddress();
    console.log(`ERC1155 Beacon deployed to: ${erc1155BeaconAddress}`);

    // 3. Deploy Collection Factory
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

    // 4. Set Collection Factory in Diamond
    console.log("\nSetting Collection Factory in Diamond...");
    const collectionFacet = await ethers.getContractAt("EmblemVaultCollectionFacet", diamondAddress);
    const tx = await collectionFacet.setCollectionFactory(collectionFactoryAddress);
    await tx.wait();
    console.log("Collection Factory set in Diamond");

    // Update deployment report
    const updatedReport = report.replace(
        /## Next Steps/,
        `## Beacon System Addresses

### ERC721 Beacon
- Address: [\`${erc721BeaconAddress}\`](https://scan.merlinchain.io/address/${erc721BeaconAddress})

### ERC1155 Beacon
- Address: [\`${erc1155BeaconAddress}\`](https://scan.merlinchain.io/address/${erc1155BeaconAddress})

### Collection Factory
- Address: [\`${collectionFactoryAddress}\`](https://scan.merlinchain.io/address/${collectionFactoryAddress})

## Next Steps`
    );

    fs.writeFileSync(reportPath, updatedReport);
    console.log(`\nDeployment complete! Report updated at ${reportPath}`);

    return {
        erc721Beacon: erc721BeaconAddress,
        erc1155Beacon: erc1155BeaconAddress,
        collectionFactory: collectionFactoryAddress
    };
}

// Execute the deployment
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
