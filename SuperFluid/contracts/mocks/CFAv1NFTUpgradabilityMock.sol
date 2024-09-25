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

import { ISuperfluid } from "../interfaces/superfluid/ISuperfluid.sol";
import { ConstantInflowNFT, IConstantInflowNFT } from "../superfluid/ConstantInflowNFT.sol";
import { ConstantOutflowNFT, IConstantOutflowNFT } from "../superfluid/ConstantOutflowNFT.sol";
import { FlowNFTBase } from "../superfluid/FlowNFTBase.sol";

/*//////////////////////////////////////////////////////////////////////////
                                FlowNFTBase Mocks
//////////////////////////////////////////////////////////////////////////*/

interface IFlowNFTBaseMockErrors {
    error STORAGE_LOCATION_CHANGED(string _name);
}

/// @title FlowNFTBaseStorageLayoutMock
/// @author Superfluid
/// @notice A mock FlowNFTBase contract for testing storage layout.
/// @dev This contract *MUST* have the same storage layout as FlowNFTBase.sol
contract FlowNFTBaseStorageLayoutMock is FlowNFTBase {

    error STORAGE_LOCATION_CHANGED(string _name);

    constructor(
        ISuperfluid host
    ) FlowNFTBase(host) {}

    /// @notice Validates storage layout
    /// @dev This function is used by all the FlowNFTBase mock contracts to validate the layout
    function validateStorageLayout() public virtual {
        uint256 slot;
        uint256 offset; // in bytes

        // slot 0 taken is occupied by these variables:
        // Initializable._initialized (uint8) 1byte
        // Initializable._initializing (bool) 1byte

        assembly { slot := _name.slot offset := _name.offset }
        if (slot != 1 || offset != 0) revert STORAGE_LOCATION_CHANGED("_name");

        assembly { slot := _symbol.slot offset := _symbol.offset }
        if (slot != 2 || offset != 0) revert STORAGE_LOCATION_CHANGED("_symbol");

        assembly { slot := _tokenApprovals.slot offset := _tokenApprovals.offset }
        if (slot != 3 || offset != 0) revert STORAGE_LOCATION_CHANGED("_tokenApprovals");

        assembly { slot := _operatorApprovals.slot offset := _operatorApprovals.offset }
        if (slot != 4 || offset != 0) revert STORAGE_LOCATION_CHANGED("_operatorApprovals");

        assembly { slot := _reserve5.slot offset := _reserve5.offset }
        if (slot != 5 || offset != 0) revert STORAGE_LOCATION_CHANGED("_reserve5");

        assembly { slot := _reserve21.slot offset := _reserve21.offset }
        if (slot != 21 || offset != 0) revert STORAGE_LOCATION_CHANGED("_reserve21");
    }

    // Dummy implementations for abstract functions
    function flowDataByTokenId(
        uint256 //tokenId
    ) public pure override returns (FlowNFTData memory flowData) {
        return flowData;
    }
    // Dummy implementations for abstract functions
    function _ownerOf(
        uint256 //tokenId
        ) internal pure override returns (address) {
        return address(0);
    }
    function _transfer(
        address, //from,
        address, //to,
        uint256  //tokenId
    ) internal pure override {
        return;
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory // data
    ) internal pure override {
        _transfer(from, to, tokenId);
    }
    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("");
    }

    function tokenURI(uint256 /* tokenId */) external pure override returns (string memory) {
        return "";
    }
}


/// @title ConstantInflowNFTStorageLayoutMock
/// @author Superfluid
/// @notice A mock ConstantOutflowNFT contract for testing storage layout.
/// @dev This contract *MUST* have the same storage layout as ConstantOutflowNFT.sol
contract ConstantInflowNFTStorageLayoutMock is ConstantInflowNFT {

    error STORAGE_LOCATION_CHANGED(string _name);


    constructor(
        ISuperfluid host,
        IConstantOutflowNFT constantOutflowNFT
    ) ConstantInflowNFT(host, constantOutflowNFT) {}

    /// @notice Validates storage layout
    /// @dev This function is used to validate storage layout of ConstantInflowNFT
    function validateStorageLayout() public virtual {
        uint256 slot;
        uint256 offset; // in bytes

        // slot 0 taken is occupied by these variables:
        // Initializable._initialized (uint8) 1byte
        // Initializable._initializing (bool) 1byte

        assembly { slot := _name.slot offset := _name.offset }
        if (slot != 1 || offset != 0) revert STORAGE_LOCATION_CHANGED("_name");

        assembly { slot := _symbol.slot offset := _symbol.offset }
        if (slot != 2 || offset != 0) revert STORAGE_LOCATION_CHANGED("_symbol");

        assembly { slot := _tokenApprovals.slot offset := _tokenApprovals.offset }
        if (slot != 3 || offset != 0) revert STORAGE_LOCATION_CHANGED("_tokenApprovals");

        assembly { slot := _operatorApprovals.slot offset := _operatorApprovals.offset }
        if (slot != 4 || offset != 0) revert STORAGE_LOCATION_CHANGED("_operatorApprovals");

        assembly { slot := _reserve5.slot offset := _reserve5.offset }
        if (slot != 5 || offset != 0) revert STORAGE_LOCATION_CHANGED("_reserve5");

        assembly { slot := _reserve21.slot offset := _reserve21.offset }
        if (slot != 21 || offset != 0) revert STORAGE_LOCATION_CHANGED("_reserve21");
    }

    // Dummy implementations for abstract functions
    function _ownerOf(
        uint256 //tokenId
        ) internal pure override returns (address) {
        return address(0);
    }
    function _transfer(
        address, //from,
        address, //to,
        uint256  //tokenId
    ) internal pure override {
        return;
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory // data
    ) internal override pure {
        _transfer(from, to, tokenId);
    }
}

/// @title ConstantOutflowNFTStorageLayoutMock
/// @author Superfluid
/// @notice A mock ConstantOutflowNFT contract for testing storage layout.
/// @dev This contract *MUST* have the same storage layout as ConstantOutflowNFT.sol
contract ConstantOutflowNFTStorageLayoutMock is ConstantOutflowNFT {

    error STORAGE_LOCATION_CHANGED(string _name);


    constructor(
        ISuperfluid host,
        IConstantInflowNFT constantInflowNFT
    ) ConstantOutflowNFT(host, constantInflowNFT) {}

    /// @notice Validates storage layout
    /// @dev This function is used to validate storage layout of ConstantOutflowNFT
    function validateStorageLayout() public virtual {
        uint256 slot;
        uint256 offset; // in bytes

        // slot 0 taken is occupied by these variables:
        // Initializable._initialized (uint8) 1byte
        // Initializable._initializing (bool) 1byte

        assembly { slot := _name.slot offset := _name.offset }
        if (slot != 1 || offset != 0) revert STORAGE_LOCATION_CHANGED("_name");

        assembly { slot := _symbol.slot offset := _symbol.offset }
        if (slot != 2 || offset != 0) revert STORAGE_LOCATION_CHANGED("_symbol");

        assembly { slot := _tokenApprovals.slot offset := _tokenApprovals.offset }
        if (slot != 3 || offset != 0) revert STORAGE_LOCATION_CHANGED("_tokenApprovals");

        assembly { slot := _operatorApprovals.slot offset := _operatorApprovals.offset }
        if (slot != 4 || offset != 0) revert STORAGE_LOCATION_CHANGED("_operatorApprovals");

        assembly { slot := _reserve5.slot offset := _reserve5.offset }
        if (slot != 5 || offset != 0) revert STORAGE_LOCATION_CHANGED("_reserve5");

        assembly { slot := _reserve21.slot offset := _reserve21.offset }
        if (slot != 21 || offset != 0) revert STORAGE_LOCATION_CHANGED("_reserve21");

        assembly { slot := _flowDataByTokenId.slot offset := _flowDataByTokenId.offset }
    }

    // Dummy implementations for abstract functions
    function _ownerOf(
        uint256 //tokenId
        ) internal pure override returns (address) {
        return address(0);
    }
    function _transfer(
        address, //from,
        address, //to,
        uint256  //tokenId
    ) internal pure override {
        return;
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory // data
    ) internal pure override {
        _transfer(from, to, tokenId);
    }
}
