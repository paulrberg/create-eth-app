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
pragma solidity 0.8.19;

import { IERC721Metadata } from "SuperFluid/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IConstantOutflowNFT } from "../interfaces/superfluid/IConstantOutflowNFT.sol";
import { IConstantInflowNFT } from "../interfaces/superfluid/IConstantInflowNFT.sol";
import { ISuperfluid } from "../interfaces/superfluid/ISuperfluid.sol";
import { FlowNFTBase, IFlowNFTBase } from "./FlowNFTBase.sol";

/// @title ConstantInflowNFT Contract (CIF NFT)
/// @author Superfluid
/// @notice The ConstantInflowNFT contract to be minted to the flow sender on flow creation.
/// @dev This contract does not hold any storage, but references the ConstantOutflowNFT contract storage.
contract ConstantInflowNFT is FlowNFTBase, IConstantInflowNFT {
    IConstantOutflowNFT public immutable CONSTANT_OUTFLOW_NFT;

    // solhint-disable-next-line no-empty-blocks
    constructor(
        ISuperfluid host,
        IConstantOutflowNFT constantOutflowNFT
    ) FlowNFTBase(host) {
        CONSTANT_OUTFLOW_NFT = constantOutflowNFT;
    }

    function proxiableUUID() public pure override returns (bytes32) {
        return
            keccak256(
                "org.superfluid-finance.contracts.ConstantInflowNFT.implementation"
            );
    }

    /// @notice The mint function emits the "mint" `Transfer` event.
    /// @dev We don't modify storage as this is handled in ConstantOutflowNFT.sol and this function's sole purpose
    /// is to inform clients that search for events.
    /// Only callable by ConstantOutflowNFT
    /// @param to the receiver of the inflow nft and desired flow receiver
    /// @param newTokenId the new token id
    function mint(
        address to,
        uint256 newTokenId
    ) external onlyConstantOutflowNFT {
        _mint(to, newTokenId);
    }

    /// @notice This burn function emits the "burn" `Transfer` event.
    /// @dev We don't modify storage as this is handled in ConstantOutflowNFT.sol and this function's sole purpose
    /// is to inform clients that search for events.
    /// Only callable by ConstantOutflowNFT
    /// @param tokenId desired token id to burn
    function burn(uint256 tokenId) external onlyConstantOutflowNFT {
        _burn(tokenId);
    }

    function flowDataByTokenId(
        uint256 tokenId
    )
        public
        view
        override(FlowNFTBase, IFlowNFTBase)
        returns (FlowNFTData memory flowData)
    {
        flowData = CONSTANT_OUTFLOW_NFT.flowDataByTokenId(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        external
        view
        override(FlowNFTBase, IERC721Metadata)
        returns (string memory)
    {
        return _tokenURI(tokenId, true);
    }

    /// @inheritdoc FlowNFTBase
    function _ownerOf(
        uint256 tokenId
    ) internal view virtual override returns (address) {
        FlowNFTData memory flowData = flowDataByTokenId(tokenId);
        return flowData.flowReceiver;
    }

    /// @notice Transfer is currently not allowed.
    /// @dev Will revert currently.
    function _transfer(
        address, // from,
        address, // to,
        uint256 // tokenId
    ) internal virtual override {
        revert CFA_NFT_TRANSFER_IS_NOT_ALLOWED();
    }

    function _mint(address to, uint256 newTokenId) internal {
        emit Transfer(address(0), to, newTokenId);
    }

    function _burn(uint256 tokenId) internal override {
        FlowNFTData memory flowData = flowDataByTokenId(tokenId);

        super._burn(tokenId);

        emit Transfer(flowData.flowReceiver, address(0), tokenId);
    }

    modifier onlyConstantOutflowNFT() {
        if (msg.sender != address(CONSTANT_OUTFLOW_NFT)) {
            revert CIF_NFT_ONLY_CONSTANT_OUTFLOW();
        }
        _;
    }
}
