# delegation-registry

<img src="https://raw.githubusercontent.com/delegatexyz/delegate-registry/main/vault.png" width="300" />

## Finalized Deployment

|Mainnet Chain|Address|
|---|---|
|Ethereum|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://etherscan.io/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Polygon|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://polygonscan.com/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Optimism|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://optimistic.etherscan.io/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Celo|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://explorer.celo.org/mainnet/address/0x00000000000076A84feF008CDAbe6409d2FE638B)|
|Avalanche|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://snowtrace.io/address/0x00000000000076A84feF008CDAbe6409d2FE638B)|
|BSC|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://bscscan.com/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Gnosis|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://gnosisscan.io/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Fantom|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://ftmscan.com/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Arbitrum|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://arbiscan.io/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Arbitrum (Nova)|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://nova.arbiscan.io/address/0x00000000000076a84fef008cdabe6409d2fe638b)|

|Testnet Chain|Address|
|---|---|
|Ethereum (Goerli)|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://goerli.etherscan.io/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Polygon (Mumbai)|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://mumbai.polygonscan.com/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Optimism (Goerli)|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://goerli-optimism.etherscan.io/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Celo (Alfajores)|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://alfajores-forno.celo-testnet.org/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Avalanche (Fuji)|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://testnet.snowtrace.io/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|BSC (testnet)|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://testnet.bscscan.com/address/0x00000000000076a84fef008cdabe6409d2fe638b)|
|Gnosis (Chiado)|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://blockscout.chiadochain.net/address/0x00000000000076A84feF008CDAbe6409d2FE638B)|
|Fantom (testnet)|[0x00000000000076A84feF008CDAbe6409d2FE638B](https://testnet.ftmscan.com/address/0x00000000000076a84fef008cdabe6409d2fe638b)|


If you'd like to get the DelegationRegistry on another EVM chain, anyone in the community can deploy to the same address! Simply run the script in [Deploy.s.sol](script/Deploy.s.sol) with the specified salt. The CREATE2 factory must be deployed at `0x0000000000FFe8B47B3e2130213B802212439497`, but this factory exists on 19 separate chains so shouldn't be an issue. If you've run a community deployment, open a PR adding the link to the above table.

## Overview

Welcome! If you're a programmer, view [the specific registry code here](src/DelegationRegistry.sol). If you want to discuss specific open questions, click on the "Issues" tab to leave a comment. If you're interested in integrating this standard into your token project or marketplace, we're in the process of creating example templates - or reach out directly via a [Twitter DM](https://twitter.com/0xfoobar).

We have an exciting group of initial people circling around this standard, including foobar (hi!), punk6529 (open metaverse), loopify (loopiverse), andy8052 (fractional), purplehat (artblocks), emiliano (nftrentals), arran (proof), james (collabland), john (gnosis safe), wwhchung (manifoldxyz) tally labs and many more. The dream is to move from a fragmented world where no individual deployment gets serious use to a global registry where users can register their vault once and use it safely for a variety of airdrops & other claims! Please reach out if interested in helping make this a reality on either the technical, social, or integration side.

## Standardization

In the interest of broader visibility and adoption around this registry, we've started the process for considering this effort for an EIP (Ethereum Improvement Proposal), which can be found here: https://eips.ethereum.org/EIPS/eip-5639

## Why delegation?

Proving ownership of an asset to a third party application in the Ethereum ecosystem is common. Common examples include claiming airdrops, minting from collection whitelists, and verifying token ownership for a gated discord/telegram channel. Users frequently sign payloads of data to authenticate themselves before gaining access to perform some operation. However, this introduces the danger of accidentally signing a malicious transaction from a cold wallet vault.

While a technical solution that "just works" may appear easy to code up, there's a reason no existing approaches have delighted users and hit mass adoption yet.
- EIP712 signatures are not smart contract compatible. 
- ENS names are a dangerous & clunky dependency not suitable for an EIP standard.
- Some solutions are too specific or hardcoded for general reuse.

## What features does this include?

### Fully Onchain, No EIP 712 signatures
Why? This is critical for smart contract composability, which cannot produce a private key signature. And while we could have two separate paths for delegation setup, one with smart contract calls and one with signature calls, this fragments adoption and developer use. Not to mention that allowing offchain signatures encourages people to interact with their vault and hotwallet in rapid succession, and accidental signatures can float around offchain with no easy way to revoke as we saw with the OpenSea "old ape offer" attack vector.

### Fully Immutable, No Admin Powers
Why? Because governance is an attack vector. There should be none of it in a neutral trustless delegation standard. The standard is designed to be as flexible as possible, but upgrades are always possible by deploying a new registry with different functionality.

### Fully Standalone, No External Dependencies
Why? Because external dependencies are an unnecessary attack vector. 

### Fully Identifiable, Clear Unique Method Names
Why? Delegation is distinct from token ownership. Delegation implies the ability to claim or act on behalf of a token owner, but it does not imply the ability to move the token. So method names such as `balanceOf()` and `ownerOf()` should be avoided at all costs, replaced with clear method names that make it clear the hotwallet has delegation powers but not token ownership powers.

### Reusable Global Registry w/ Same Address Across Multiple EVM Chains
Why? For ease of use and adoption. It should also be a vanity address that's clearly distinguishable from others via CREATE2, either leading zeros or some fun prefix/postfix.

## Why not existing solutions?

Sincere appreciation for everyone who's taken a crack at this problem in the past with different tradeoffs. Comparison is done not to denigrate, but with the goal of hitting the best unified standard for mass adoption.

ENS delegation via [EIP-5131](https://eips.ethereum.org/EIPS/eip-5131): ENS is an offshore foundation with a for-profit token that charges rent for every new domain registration. We applaud the widespread adoption it's gotten, however this is a dangerous dependency for what should be a timeless standard. Additionally, delegations for a fresh wallet should be free (only gas) rather than costing additional economic rents.

wenew's approach via [HotWalletProxy](https://github.com/wenewlabs/public/blob/main/HotWalletProxy/HotWalletProxy.sol): This is the right directional approach, with an onchain registry that can be set via either a vault transaction or a vault signature submitted from a hot wallet. However it doesn't provide enough generalizability of drilling down into specific collections or specific tokens, the `ownerOf()` method naming overlaps with existing standards, and doesn't generalize to other types of delegation such as governance-specific standards. Delegation should be explicit rather than overwriting existing ERC721 method names.

## How do I use it?

Check out the [IDelegationRegistry.sol](src/IDelegationRegistry.sol) file. This is the interface to interact with, and contains the following methods:

```code
/// WRITE ///
function delegateForAll(address delegate, bool value) external;
function delegateForContract(address delegate, address contract_, bool value) external;
function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;
function revokeAllDelegates() external;
function revokeDelegate(address delegate) external;
function revokeSelf(address vault) external;
/// READ ///
function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);
function getDelegatesForAll(address vault) external view returns (address[] memory);
function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);
function getDelegatesForToken(address vault, address contract_, uint256 tokenId) external view returns (address[] memory);
function checkDelegateForAll(address delegate, address vault) external view returns (bool);
function checkDelegateForContract(address delegate, address vault, address contract_) external view returns (bool);
function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool);
```

As an NFT creator, the important ones to pay attention to are `getDelegationsByDelegate()`, which you can use on the website frontend to enumerate which vaults a specific hotwallet is delegated to act on behalf of, and `checkDelegateForToken()`, which can be called in your smart contract to ensure a hotwallet is acting on behalf of the proper vaults.
