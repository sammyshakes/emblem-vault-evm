const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("Deploying Vault Implementations to Merlin Chain...");

    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying with account: ${deployer.address}`);

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

    // Create deployment report
    const deploymentReport = {
        network: hre.network.name,
        chainId: hre.network.config.chainId,
        erc721Implementation: erc721ImplementationAddress,
        erc1155Implementation: erc1155ImplementationAddress,
        timestamp: new Date().toISOString()
    };

    // Save deployment report
    const reportDir = path.join(__dirname, "../deployment-reports");
    if (!fs.existsSync(reportDir)) {
        fs.mkdirSync(reportDir, { recursive: true });
    }

    const networkName = hre.network.name.toUpperCase();

    // Try to read existing Hardhat deployment report
    let existingReport = "";
    const reportPath = path.join(reportDir, `HARDHAT_DEPLOYMENT_REPORT_${networkName}.md`);
    if (fs.existsSync(reportPath)) {
        existingReport = fs.readFileSync(reportPath, 'utf8');
    }

    if (existingReport) {
        // Update existing report with vault implementation addresses
        const updatedReport = existingReport.replace(
            /## Next Steps/,
            `## Vault Implementation Addresses

### ERC721 Implementation
- Address: [\`${erc721ImplementationAddress}\`](https://scan.merlinchain.io/address/${erc721ImplementationAddress})

### ERC1155 Implementation
- Address: [\`${erc1155ImplementationAddress}\`](https://scan.merlinchain.io/address/${erc1155ImplementationAddress})

## Next Steps`
        );

        fs.writeFileSync(reportPath, updatedReport);
    } else {
        // Create new report if one doesn't exist
        fs.writeFileSync(
            reportPath,
            `# ${networkName} Vault Implementations Deployment Report (Hardhat)

## Network Information
- Network: ${hre.network.name}
- Chain ID: ${hre.network.config.chainId}

## Vault Implementation Addresses

### ERC721 Implementation
- Address: [\`${erc721ImplementationAddress}\`](https://scan.merlinchain.io/address/${erc721ImplementationAddress})

### ERC1155 Implementation
- Address: [\`${erc1155ImplementationAddress}\`](https://scan.merlinchain.io/address/${erc1155ImplementationAddress})

## Deployment Timestamp
${new Date().toISOString()}

## Next Steps
1. Deploy Beacon System (ERC721 & ERC1155 Beacons)
2. Deploy Collection Factory
3. Connect Factory to Diamond
4. Deploy Priority Collections
`
        );
    }

    console.log(`\nDeployment complete! Report saved to deployment-reports/HARDHAT_DEPLOYMENT_REPORT_${networkName}.md`);

    return deploymentReport;
}

// Execute the deployment
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
