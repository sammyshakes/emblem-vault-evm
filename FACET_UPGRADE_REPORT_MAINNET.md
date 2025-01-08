# Emblem Vault Facet Upgrade Report (Mainnet)

## Diamond System

**Diamond Address:** 0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60

## Facet Upgrades (Block 21570962-21570967)

| Contract        | Address                                    | Etherscan Link                                                                                     | Gas Used  | Cost (ETH) |
| --------------- | ------------------------------------------ | -------------------------------------------------------------------------------------------------- | --------- | ---------- |
| CoreFacet       | 0xEE483847aa8E52887A1C5477b8F5b0af28922681 | [Link](https://etherscan.io/address/0xEE483847aa8E52887A1C5477b8F5b0af28922681)                    | 942,481   | 0.003908   |
| MintFacet       | 0xA137e2d3DeC0874512C8A71E7Ab176b6FaCB165d | [Link](https://etherscan.io/address/0xA137e2d3DeC0874512C8A71E7Ab176b6FaCB165d)                    | 1,214,976 | 0.005654   |
| UnvaultFacet    | 0x79B66cf2f6b90f2Ee837c7eB41163F7725B56B25 | [Link](https://etherscan.io/address/0x79B66cf2f6b90f2Ee837c7eB41163F7725B56B25)                    | 1,222,689 | 0.006265   |
| InitFacet       | 0x5657a10c1AAe46Ae383342d7516290B4FecD9295 | [Link](https://etherscan.io/address/0x5657a10c1AAe46Ae383342d7516290B4FecD9295)                    | 563,826   | 0.002651   |
| CollectionFacet | 0x76060779BF7164B40A63588C01d0E632B213A726 | [Link](https://etherscan.io/address/0x76060779BF7164B40A63588C01d0E632B213A726)                    | 908,911   | 0.004402   |
| Diamond Cut     | 0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60 | [Link](https://etherscan.io/tx/0xb36d22aac82b693fc8122ee435d903a1189cb56d12a585f60b879104edd5460e) | 1,060,800 | 0.005140   |

**Total Upgrade:**

- Gas Used: 5,913,683
- Cost: 0.028021 ETH
- Average Gas Price: 4.719165074 gwei

## Upgrade Details

- All contracts were successfully verified on Etherscan
- Upgrade was performed across blocks 21570962-21570967
- Diamond Cut transaction included 9 cuts for function selector updates

## ClaimFacet Removal

- Block: 21571103
- Transaction: [0xf34f93af605bc62df986a74add9671b053547848a353c1deb69966a628afde21](https://etherscan.io/tx/0xf34f93af605bc62df986a74add9671b053547848a353c1deb69966a628afde21)
- Gas Used: 57,924
- Cost: 0.000264352031911404 ETH
- Average Gas Price: 4.563773771 gwei

Removed Functions:

- claim(uint256,bytes)
- claimWithSignedPrice(uint256,uint256,bytes)
- isTokenClaimed(uint256)
