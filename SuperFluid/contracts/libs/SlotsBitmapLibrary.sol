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

import {ISuperfluidToken} from "../interfaces/superfluid/ISuperfluidToken.sol";

/**
 * @title Slots Bitmap library
 * @author Superfluid
 * @dev A library implements slots bitmap on Superfluid Token storage
 * NOTE:
 * - A slots bitmap allows you to iterate through a list of data efficiently.
 * - A data slot can be enabled or disabled with the help of bitmap.
 * - MAX_NUM_SLOTS is 256 in this implementation (using one uint256)
 * - Superfluid token storage usage:
 *   - getAgreementStateSlot(bitmapStateSlotId) stores the bitmap of enabled data slots
 *   - getAgreementStateSlot(dataStateSlotIDStart + stotId) stores the data of the slot
 */
library SlotsBitmapLibrary {

    uint32 internal constant _MAX_NUM_SLOTS = 256;

    function findEmptySlotAndFill(
        ISuperfluidToken token,
        address account,
        uint256 bitmapStateSlotId,
        uint256 dataStateSlotIDStart,
        bytes32 data
    )
        public
        returns (uint32 slotId)
    {
        uint256 subsBitmap = uint256(token.getAgreementStateSlot(
            address(this),
            account,
            bitmapStateSlotId, 1)[0]);
        for (slotId = 0; slotId < _MAX_NUM_SLOTS; ++slotId) {
            if ((uint256(subsBitmap >> slotId) & 1) == 0) {
                // update slot data
                bytes32[] memory slotData = new bytes32[](1);
                slotData[0] = data;
                token.updateAgreementStateSlot(
                    account,
                    dataStateSlotIDStart + slotId,
                    slotData);
                // update slot map
                slotData[0] = bytes32(subsBitmap | (1 << uint256(slotId)));
                token.updateAgreementStateSlot(
                    account,
                    bitmapStateSlotId,
                    slotData);
                // update the slots
                break;
            }
        }
        require(slotId < _MAX_NUM_SLOTS, "SlotBitmap out of bound");
    }

    function clearSlot(
        ISuperfluidToken token,
        address account,
        uint256 bitmapStateSlotId,
        uint32 slotId
    )
        public
    {
        uint256 subsBitmap = uint256(token.getAgreementStateSlot(
            address(this),
            account,
            bitmapStateSlotId, 1)[0]);
        bytes32[] memory slotData = new bytes32[](1);
        // [SECURITY] NOTE: We do not allow clearing of nonexistent slots
        assert(subsBitmap & (1 << uint256(slotId)) != 0);
        slotData[0] = bytes32(subsBitmap & ~(1 << uint256(slotId)));
        // zero the data
        token.updateAgreementStateSlot(
            account,
            bitmapStateSlotId,
            slotData);
    }

    function listData(
       ISuperfluidToken token,
       address account,
       uint256 bitmapStateSlotId,
       uint256 dataStateSlotIDStart
    )
        public view
        returns (
            uint32[] memory slotIds,
            bytes32[] memory dataList)
    {
        uint256 subsBitmap = uint256(token.getAgreementStateSlot(
            address(this),
            account,
            bitmapStateSlotId, 1)[0]);

        slotIds = new uint32[](_MAX_NUM_SLOTS);
        dataList = new bytes32[](_MAX_NUM_SLOTS);
        // read all slots
        uint nSlots;
        for (uint32 slotId = 0; slotId < _MAX_NUM_SLOTS; ++slotId) {
            if ((uint256(subsBitmap >> slotId) & 1) == 0) continue;
            slotIds[nSlots] = slotId;
            dataList[nSlots] = token.getAgreementStateSlot(
                address(this),
                account,
                dataStateSlotIDStart + slotId, 1)[0];
            ++nSlots;
        }
        // resize memory arrays
        assembly {
            mstore(slotIds, nSlots)
            mstore(dataList, nSlots)
        }
    }
}
