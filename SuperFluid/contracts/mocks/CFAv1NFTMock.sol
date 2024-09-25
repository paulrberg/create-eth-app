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
  
  // SPDX-License-Identifier: AGPLv3
// solhint-disable reason-string
pragma solidity 0.8.19;

import { IERC20 } from "SuperFluid/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "SuperFluid/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { UUPSProxiable } from "../upgradability/UUPSProxiable.sol";
import { ERC777Helper } from "../libs/ERC777Helper.sol";
import { SuperfluidToken } from "../superfluid/SuperfluidToken.sol";
import { ISuperfluid, IConstantInflowNFT, IConstantOutflowNFT } from "../interfaces/superfluid/ISuperfluid.sol";
import { ConstantInflowNFT } from "../superfluid/ConstantInflowNFT.sol";
import { ConstantOutflowNFT } from "../superfluid/ConstantOutflowNFT.sol";

contract ConstantOutflowNFTMock is ConstantOutflowNFT {
    constructor(
        ISuperfluid host,
        IConstantInflowNFT constantInflowNFT
    ) ConstantOutflowNFT(host, constantInflowNFT) {}

    /// @dev a mock mint function that exposes the internal _mint function
    function mockMint(
        address _superToken,
        address _to,
        address _flowReceiver,
        uint256 _newTokenId
    ) public {
        _mint(_superToken, _to, _flowReceiver, _newTokenId);
    }

    /// @dev a mock burn function that exposes the internal _burn function
    function mockBurn(uint256 _tokenId) public {
        _burn(_tokenId);
    }

    /// @dev this ownerOf doesn't revert if _tokenId doesn't exist
    function mockOwnerOf(uint256 _tokenId) public view returns (address) {
        return _ownerOf(_tokenId);
    }

    /// @dev This exposes the _tokenApprovals storage without the requireMinted call
    function mockGetApproved(uint256 _tokenId) public view returns (address) {
        return _tokenApprovals[_tokenId];
    }
}

contract ConstantInflowNFTMock is ConstantInflowNFT {
    constructor(
        ISuperfluid host,
        IConstantOutflowNFT constantOutflowNFT
    ) ConstantInflowNFT(host, constantOutflowNFT) {}

    /// @dev a mock mint function to emit the mint Transfer event
    function mockMint(address _to, uint256 _newTokenId) public {
        _mint(_to, _newTokenId);
    }

    /// @dev a mock burn function to emit the burn Transfer event
    function mockBurn(uint256 _tokenId) public {
        _burn(_tokenId);
    }

    // @dev this ownerOf doesn't revert if _tokenId doesn't exist
    function mockOwnerOf(uint256 _tokenId) public view returns (address) {
        return _ownerOf(_tokenId);
    }

    /// @dev this exposes the internal flow data by token id for testing purposes
    function mockFlowNFTDataByTokenId(
        uint256 _tokenId
    ) public view returns (FlowNFTData memory flowData) {
        return flowDataByTokenId(_tokenId);
    }

    /// @dev This exposes the _tokenApprovals storage without the requireMinted call
    function mockGetApproved(uint256 _tokenId) public view returns (address) {
        return _tokenApprovals[_tokenId];
    }
}

/// @title NoNFTSuperTokenMock
/// @author Superfluid
/// @notice Minimal SuperToken implementation to test flow creation if no NFT proxy contract variable exists.
/// Storage layout is made to mimic SuperToken.
contract NoNFTSuperTokenMock is UUPSProxiable, SuperfluidToken {
    using SafeERC20 for IERC20;

    /// @dev The underlying ERC20 token
    IERC20 internal _underlyingToken;

    /// @dev Decimals of the underlying token
    uint8 internal _underlyingDecimals;

    /// @dev IERC20Metadata Name property
    string internal _name;

    /// @dev IERC20Metadata Symbol property
    string internal _symbol;

    /// @dev ERC20 Allowances Storage
    mapping(address => mapping(address => uint256)) internal _allowances;

    /// @dev ERC777 operators support data
    ERC777Helper.Operators internal _operators;

    constructor(ISuperfluid host) SuperfluidToken(host) {}

    /// @dev Initialize the Super Token proxy
    function initialize(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        string calldata n,
        string calldata s
    )
        external
        initializer // OpenZeppelin Initializable
    {
        _underlyingToken = underlyingToken;
        _underlyingDecimals = underlyingDecimals;

        _name = n;
        _symbol = s;

        // register interfaces
        ERC777Helper.register(address(this));
    }

    /// @dev ISuperToken.upgrade implementation
    function upgrade(uint256 amount) external {
        _upgrade(msg.sender, msg.sender, msg.sender, amount, "", "");
    }

    /**
     * @dev Handle decimal differences between underlying token and super token
     */
    function _toUnderlyingAmount(
        uint256 amount
    ) private view returns (uint256 underlyingAmount, uint256 adjustedAmount) {
        uint256 factor;
        if (_underlyingDecimals < 18) {
            // if underlying has less decimals
            // one can upgrade less "granualar" amount of tokens
            factor = 10 ** (18 - _underlyingDecimals);
            underlyingAmount = amount / factor;
            // remove precision errors
            adjustedAmount = underlyingAmount * factor;
        } else if (_underlyingDecimals > 18) {
            // if underlying has more decimals
            // one can upgrade more "granualar" amount of tokens
            factor = 10 ** (_underlyingDecimals - 18);
            underlyingAmount = amount * factor;
            adjustedAmount = amount;
        } else {
            underlyingAmount = adjustedAmount = amount;
        }
    }

    function _upgrade(
        address operator,
        address account,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        if (address(_underlyingToken) == address(0)) revert();

        (
            uint256 underlyingAmount,
            uint256 adjustedAmount
        ) = _toUnderlyingAmount(amount);

        uint256 amountBefore = _underlyingToken.balanceOf(address(this));
        _underlyingToken.safeTransferFrom(
            account,
            address(this),
            underlyingAmount
        );
        uint256 amountAfter = _underlyingToken.balanceOf(address(this));
        uint256 actualUpgradedAmount = amountAfter - amountBefore;
        if (underlyingAmount != actualUpgradedAmount) revert();

        _mint(
            operator,
            to,
            adjustedAmount,
            // if `userData.length` than 0, we requireReceptionAck
            userData.length != 0,
            userData,
            operatorData
        );
    }

    /// dummy impl
    function _mint(
        address, // operator,
        address account,
        uint256 amount,
        bool, // requireReceptionAck,
        bytes memory, // userData,
        bytes memory // operatorData
    ) internal {
        if (account == address(0)) {
            revert();
        }

        SuperfluidToken._mint(account, amount);
    }

    function proxiableUUID() public pure override returns (bytes32) {
        return
            keccak256(
                "org.superfluid-finance.contracts.SuperToken.implementation"
            );
    }

    // solhint-disable-next-line no-empty-blocks
    function updateCode(address newAddress) external override {
        // dummy impl
    }
}
