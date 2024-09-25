/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Synthetix?utm=code
  */
  
  pragma solidity ^0.5.16;

// Inheritence
import "./MixinResolver.sol";
import "./interfaces/ISynthRedeemer.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IIssuer.sol";

contract SynthRedeemer is ISynthRedeemer, MixinResolver {
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "SynthRedeemer";

    mapping(address => uint) public redemptions;

    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_SYNTHSUSD = "SynthsUSD";

    constructor(address _resolver) public MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](2);
        addresses[0] = CONTRACT_ISSUER;
        addresses[1] = CONTRACT_SYNTHSUSD;
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function sUSD() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTHSUSD));
    }

    function totalSupply(IERC20 synthProxy) public view returns (uint supplyInsUSD) {
        supplyInsUSD = synthProxy.totalSupply().multiplyDecimal(redemptions[address(synthProxy)]);
    }

    function balanceOf(IERC20 synthProxy, address account) external view returns (uint balanceInsUSD) {
        balanceInsUSD = synthProxy.balanceOf(account).multiplyDecimal(redemptions[address(synthProxy)]);
    }

    function redeemAll(IERC20[] calldata synthProxies) external {
        for (uint i = 0; i < synthProxies.length; i++) {
            _redeem(synthProxies[i], synthProxies[i].balanceOf(msg.sender));
        }
    }

    function redeem(IERC20 synthProxy) external {
        _redeem(synthProxy, synthProxy.balanceOf(msg.sender));
    }

    function redeemPartial(IERC20 synthProxy, uint amountOfSynth) external {
        // technically this check isn't necessary - Synth.burn would fail due to safe sub,
        // but this is a useful error message to the user
        require(synthProxy.balanceOf(msg.sender) >= amountOfSynth, "Insufficient balance");
        _redeem(synthProxy, amountOfSynth);
    }

    function _redeem(IERC20 synthProxy, uint amountOfSynth) internal {
        uint rateToRedeem = redemptions[address(synthProxy)];
        require(rateToRedeem > 0, "Synth not redeemable");
        require(amountOfSynth > 0, "No balance of synth to redeem");
        issuer().burnForRedemption(address(synthProxy), msg.sender, amountOfSynth);
        uint amountInsUSD = amountOfSynth.multiplyDecimal(rateToRedeem);
        sUSD().transfer(msg.sender, amountInsUSD);
        emit SynthRedeemed(address(synthProxy), msg.sender, amountOfSynth, amountInsUSD);
    }

    function deprecate(IERC20 synthProxy, uint rateToRedeem) external onlyIssuer {
        address synthProxyAddress = address(synthProxy);
        require(redemptions[synthProxyAddress] == 0, "Synth is already deprecated");
        require(rateToRedeem > 0, "No rate for synth to redeem");
        uint totalSynthSupply = synthProxy.totalSupply();
        uint supplyInsUSD = totalSynthSupply.multiplyDecimal(rateToRedeem);
        require(sUSD().balanceOf(address(this)) >= supplyInsUSD, "sUSD must first be supplied");
        redemptions[synthProxyAddress] = rateToRedeem;
        emit SynthDeprecated(address(synthProxy), rateToRedeem, totalSynthSupply, supplyInsUSD);
    }

    function requireOnlyIssuer() internal view {
        require(msg.sender == address(issuer()), "Restricted to Issuer contract");
    }

    modifier onlyIssuer() {
        requireOnlyIssuer();
        _;
    }

    event SynthRedeemed(address synth, address account, uint amountOfSynth, uint amountInsUSD);
    event SynthDeprecated(address synth, uint rateToRedeem, uint totalSynthSupply, uint supplyInsUSD);
}
