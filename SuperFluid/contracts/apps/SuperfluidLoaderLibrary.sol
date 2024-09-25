/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/SuperFluid?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity >= 0.8.11;

library SuperfluidLoaderLibrary {
    error UnsupportedNetwork();

    // mainnet
    uint256 private constant ETH_MAINNET = 1;
    uint256 private constant OPTIMISM_MAINNET = 10;
    uint256 private constant BSC_MAINNET = 56;
    uint256 private constant XDAI_MAINNET = 100;
    uint256 private constant POLYGON_MAINNET = 137;
    uint256 private constant ARBITRUM_ONE = 42161;
    uint256 private constant CELO_MAINNET = 42220;
    uint256 private constant AVALANCHE_C = 43114;

    // testnets
    uint256 private constant ETH_GOERLI = 5;
    uint256 private constant ETH_SEPOLIA = 11155111;
    uint256 private constant BASE_GOERLI = 84531;
    uint256 private constant POLYGON_MUMBAI = 80001;
    uint256 private constant ARBITRUM_GOERLI = 421613;
    uint256 private constant OPTIMISM_GOERLI = 420;
    uint256 private constant AVALANCHE_FUJI = 43113;
    uint256 private constant ZKEVM_TESTNET = 1442;
    

    function getHost() public view returns (address) {
        if (block.chainid == ETH_MAINNET) {
            return 0x4E583d9390082B65Bef884b629DFA426114CED6d;
        } else if (block.chainid == OPTIMISM_MAINNET) {
            return 0x567c4B141ED61923967cA25Ef4906C8781069a10;
        } else if (block.chainid == BSC_MAINNET) {
            return 0xd1e2cFb6441680002Eb7A44223160aB9B67d7E6E;
        } else if (block.chainid == XDAI_MAINNET) {
            return 0x2dFe937cD98Ab92e59cF3139138f18c823a4efE7;
        } else if (block.chainid == POLYGON_MAINNET) {
            return 0x3E14dC1b13c488a8d5D310918780c983bD5982E7;
        } else if (block.chainid == ARBITRUM_ONE) {
            return 0xCf8Acb4eF033efF16E8080aed4c7D5B9285D2192;
        } else if (block.chainid == CELO_MAINNET) {
            return 0xA4Ff07cF81C02CFD356184879D953970cA957585;
        } else if (block.chainid == AVALANCHE_C) {
            return 0x60377C7016E4cdB03C87EF474896C11cB560752C;
        } else if (block.chainid == ETH_GOERLI) {
            return 0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9;
        } else if (block.chainid == ARBITRUM_GOERLI) {
            return 0xE40983C2476032A0915600b9472B3141aA5B5Ba9;
        } else if (block.chainid == OPTIMISM_GOERLI) {
            return 0xE40983C2476032A0915600b9472B3141aA5B5Ba9;
        } else if (block.chainid == AVALANCHE_FUJI) {
            return 0x85Fe79b998509B77BF10A8BD4001D58475D29386;
        } else if (block.chainid == POLYGON_MUMBAI) {
            return 0xEB796bdb90fFA0f28255275e16936D25d3418603;
        } else if (block.chainid == ETH_SEPOLIA) {
            return 0x109412E3C84f0539b43d39dB691B08c90f58dC7c;
        } else if (block.chainid == BASE_GOERLI) {
            return 0x507c3a7C6Ccc253884A2e3a3ee2A211cC7E796a6;
        } else if (block.chainid == ZKEVM_TESTNET) {
            return 0xe64f81d5dDdA1c7172e5C6d964E8ef1BD82D8704;
        } else {
            revert UnsupportedNetwork();
        }
    }
}
