const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("Deploying Diamond System to Merlin Chain...");

    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying with account: ${deployer.address}`);

    // 1. Deploy all facets
    console.log("\nDeploying facets...");

    console.log("Deploying DiamondCutFacet...");
    const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
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
    const EmblemVaultCoreFacet = await ethers.getContractFactory("EmblemVaultCoreFacet");
    const vaultCoreFacet = await EmblemVaultCoreFacet.deploy();
    await vaultCoreFacet.waitForDeployment();
    const vaultCoreFacetAddress = await vaultCoreFacet.getAddress();
    console.log(`EmblemVaultCoreFacet deployed to: ${vaultCoreFacetAddress}`);

    console.log("Deploying EmblemVaultUnvaultFacet...");
    const EmblemVaultUnvaultFacet = await ethers.getContractFactory("EmblemVaultUnvaultFacet");
    const unvaultFacet = await EmblemVaultUnvaultFacet.deploy();
    await unvaultFacet.waitForDeployment();
    const unvaultFacetAddress = await unvaultFacet.getAddress();
    console.log(`EmblemVaultUnvaultFacet deployed to: ${unvaultFacetAddress}`);

    console.log("Deploying EmblemVaultMintFacet...");
    const EmblemVaultMintFacet = await ethers.getContractFactory("EmblemVaultMintFacet");
    const mintFacet = await EmblemVaultMintFacet.deploy();
    await mintFacet.waitForDeployment();
    const mintFacetAddress = await mintFacet.getAddress();
    console.log(`EmblemVaultMintFacet deployed to: ${mintFacetAddress}`);

    console.log("Deploying EmblemVaultCollectionFacet...");
    const EmblemVaultCollectionFacet = await ethers.getContractFactory("EmblemVaultCollectionFacet");
    const collectionFacet = await EmblemVaultCollectionFacet.deploy();
    await collectionFacet.waitForDeployment();
    const collectionFacetAddress = await collectionFacet.getAddress();
    console.log(`EmblemVaultCollectionFacet deployed to: ${collectionFacetAddress}`);

    console.log("Deploying EmblemVaultInitFacet...");
    const EmblemVaultInitFacet = await ethers.getContractFactory("EmblemVaultInitFacet");
    const initFacet = await EmblemVaultInitFacet.deploy();
    await initFacet.waitForDeployment();
    const initFacetAddress = await initFacet.getAddress();
    console.log(`EmblemVaultInitFacet deployed to: ${initFacetAddress}`);

    // 2. Deploy Diamond
    console.log("\nDeploying Diamond...");
    const EmblemVaultDiamond = await ethers.getContractFactory("EmblemVaultDiamond");
    const diamond = await EmblemVaultDiamond.deploy(deployer.address, diamondCutFacetAddress);
    await diamond.waitForDeployment();
    const diamondAddress = await diamond.getAddress();
    console.log(`Diamond deployed to: ${diamondAddress}`);

    // 3. Build cut struct for adding facets
    console.log("\nPreparing diamond cut...");

    // Helper function to safely get function selectors
    const getFunctionSelectors = (contract, functionSignatures) => {
        const selectors = [];
        for (const signature of functionSignatures) {
            try {
                const func = contract.interface.getFunction(signature);
                if (func) {
                    selectors.push(func.selector);
                } else {
                    console.warn(`Warning: Function ${signature} not found in interface`);
                }
            } catch (error) {
                console.warn(`Error getting selector for ${signature}: ${error.message}`);
            }
        }
        return selectors;
    };

    // Helper function to get function selectors directly from the contract ABI
    const getSelectorsFromABI = (contract) => {
        const selectors = [];
        const selectorToName = {};
        for (const item of contract.interface.fragments) {
            if (item.type === 'function') {
                selectors.push(item.selector);
                selectorToName[item.selector] = item.name;
            }
        }
        return { selectors, selectorToName };
    };

    // Get selectors from contract ABIs
    const diamondLoupeResult = getSelectorsFromABI(diamondLoupeFacet);
    const ownershipResult = getSelectorsFromABI(ownershipFacet);
    const vaultCoreResult = getSelectorsFromABI(vaultCoreFacet);
    const unvaultResult = getSelectorsFromABI(unvaultFacet);
    const mintResult = getSelectorsFromABI(mintFacet);
    const collectionResult = getSelectorsFromABI(collectionFacet);
    const initResult = getSelectorsFromABI(initFacet);

    const diamondLoupeSelectors = diamondLoupeResult.selectors;
    const ownershipSelectors = ownershipResult.selectors;
    const vaultCoreSelectors = vaultCoreResult.selectors;
    const unvaultSelectors = unvaultResult.selectors;
    const mintSelectors = mintResult.selectors;
    const collectionSelectors = collectionResult.selectors;
    const initSelectors = initResult.selectors;

    console.log(`Found ${diamondLoupeSelectors.length} selectors for DiamondLoupeFacet`);
    console.log(`Found ${ownershipSelectors.length} selectors for OwnershipFacet`);
    console.log(`Found ${vaultCoreSelectors.length} selectors for VaultCoreFacet`);
    console.log(`Found ${unvaultSelectors.length} selectors for UnvaultFacet`);
    console.log(`Found ${mintSelectors.length} selectors for MintFacet`);
    console.log(`Found ${collectionSelectors.length} selectors for CollectionFacet`);
    console.log(`Found ${initSelectors.length} selectors for InitFacet`);

    // Check for duplicate selectors
    const allSelectors = [
        ...diamondLoupeSelectors,
        ...ownershipSelectors,
        ...vaultCoreSelectors,
        ...unvaultSelectors,
        ...mintSelectors,
        ...collectionSelectors,
        ...initSelectors
    ];

    const selectorToName = {
        ...diamondLoupeResult.selectorToName,
        ...ownershipResult.selectorToName,
        ...vaultCoreResult.selectorToName,
        ...unvaultResult.selectorToName,
        ...mintResult.selectorToName,
        ...collectionResult.selectorToName,
        ...initResult.selectorToName
    };

    const selectorCounts = {};
    const selectorFacets = {};

    // Track which facets have each selector
    for (const selector of diamondLoupeSelectors) {
        selectorCounts[selector] = (selectorCounts[selector] || 0) + 1;
        selectorFacets[selector] = [...(selectorFacets[selector] || []), 'DiamondLoupeFacet'];
    }

    for (const selector of ownershipSelectors) {
        selectorCounts[selector] = (selectorCounts[selector] || 0) + 1;
        selectorFacets[selector] = [...(selectorFacets[selector] || []), 'OwnershipFacet'];
    }

    for (const selector of vaultCoreSelectors) {
        selectorCounts[selector] = (selectorCounts[selector] || 0) + 1;
        selectorFacets[selector] = [...(selectorFacets[selector] || []), 'VaultCoreFacet'];
    }

    for (const selector of unvaultSelectors) {
        selectorCounts[selector] = (selectorCounts[selector] || 0) + 1;
        selectorFacets[selector] = [...(selectorFacets[selector] || []), 'UnvaultFacet'];
    }

    for (const selector of mintSelectors) {
        selectorCounts[selector] = (selectorCounts[selector] || 0) + 1;
        selectorFacets[selector] = [...(selectorFacets[selector] || []), 'MintFacet'];
    }

    for (const selector of collectionSelectors) {
        selectorCounts[selector] = (selectorCounts[selector] || 0) + 1;
        selectorFacets[selector] = [...(selectorFacets[selector] || []), 'CollectionFacet'];
    }

    for (const selector of initSelectors) {
        selectorCounts[selector] = (selectorCounts[selector] || 0) + 1;
        selectorFacets[selector] = [...(selectorFacets[selector] || []), 'InitFacet'];
    }

    const duplicates = Object.entries(selectorCounts)
        .filter(([_, count]) => count > 1)
        .map(([selector, count]) => ({
            selector,
            count,
            facets: selectorFacets[selector],
            name: selectorToName[selector]
        }));

    if (duplicates.length > 0) {
        console.log("\nWarning: Found duplicate selectors:");
        for (const { selector, count, facets, name } of duplicates) {
            console.log(`  ${selector} (${name}): ${count} occurrences in ${facets.join(', ')}`);
        }
    }

    // Check for the specific problematic selector
    if (selectorFacets["0xcfdbf254"]) {
        console.log("\nProblematic selector 0xcfdbf254 found in:", selectorFacets["0xcfdbf254"].join(", "));
        console.log("Function name:", selectorToName["0xcfdbf254"]);
    }

    // Filter out the MAX_BATCH_SIZE selector from MintFacet to avoid collision with UnvaultFacet
    // Both facets have this constant defined, but we only need it from one facet
    const MAX_BATCH_SIZE_SELECTOR = "0xcfdbf254"; // Selector for MAX_BATCH_SIZE()

    // Keep the selector in UnvaultFacet and remove it from MintFacet
    const filteredMintSelectors = mintSelectors.filter(selector => selector !== MAX_BATCH_SIZE_SELECTOR);

    console.log(`Removed MAX_BATCH_SIZE selector from MintFacet to avoid collision with UnvaultFacet`);
    console.log(`Original MintFacet selectors: ${mintSelectors.length}, Filtered: ${filteredMintSelectors.length}`);

    // Create the cut array
    const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };
    const cut = [
        {
            facetAddress: diamondLoupeFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: diamondLoupeSelectors
        },
        {
            facetAddress: ownershipFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        },
        {
            facetAddress: vaultCoreFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: vaultCoreSelectors
        },
        {
            facetAddress: unvaultFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: unvaultSelectors
        },
        {
            facetAddress: mintFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: filteredMintSelectors
        },
        {
            facetAddress: collectionFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: collectionSelectors
        },
        {
            facetAddress: initFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: initSelectors
        }
    ];

    // 4. Add facets to diamond
    console.log("\nAdding facets to diamond...");
    const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);
    const tx = await diamondCut.diamondCut(cut, ethers.ZeroAddress, "0x");
    await tx.wait();
    console.log("Facets added to diamond");

    // 5. Initialize the diamond
    console.log("\nInitializing diamond...");
    const initFacetContract = await ethers.getContractAt("EmblemVaultInitFacet", diamondAddress);
    const initTx = await initFacetContract.initialize(deployer.address);
    await initTx.wait();
    console.log("Diamond initialized");

    // Create deployment report
    const deploymentReport = {
        network: hre.network.name,
        chainId: hre.network.config.chainId,
        diamond: diamondAddress,
        diamondCutFacet: diamondCutFacetAddress,
        diamondLoupeFacet: diamondLoupeFacetAddress,
        ownershipFacet: ownershipFacetAddress,
        vaultCoreFacet: vaultCoreFacetAddress,
        unvaultFacet: unvaultFacetAddress,
        mintFacet: mintFacetAddress,
        collectionFacet: collectionFacetAddress,
        initFacet: initFacetAddress,
        timestamp: new Date().toISOString()
    };

    // Save deployment report
    const reportDir = path.join(__dirname, "../deployment-reports");
    if (!fs.existsSync(reportDir)) {
        fs.mkdirSync(reportDir, { recursive: true });
    }

    const networkName = hre.network.name.toUpperCase();

    fs.writeFileSync(
        path.join(reportDir, `HARDHAT_DEPLOYMENT_REPORT_${networkName}.md`),
        `# ${networkName} Deployment Report (Hardhat)

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
`
    );

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
