/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/OpenSea-Seaport?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FulfillmentComponent} from "../../SeaportStructs.sol";

struct MatchComponent {
    uint256 amount;
    uint8 orderIndex;
    uint8 itemIndex;
}

library MatchComponentType {
    using MatchComponentType for MatchComponent;

    uint256 private constant AMOUNT_SHL_OFFSET = 16;
    uint256 private constant ORDER_INDEX_SHL_OFFSET = 8;
    uint256 private constant BYTE_MASK = 0xFF;
    uint256 private constant AMOUNT_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000;
    uint256 private constant ORDER_INDEX_MASK = 0xFF00;
    uint256 private constant ITEM_INDEX_MASK = 0xFF;
    uint256 private constant NOT_AMOUNT_MASK = 0xFFFF;
    uint256 private constant NOT_ORDER_INDEX_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FF;
    uint256 private constant NOT_ITEM_INDEX_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00;

    function createMatchComponent(uint256 amount, uint8 orderIndex, uint8 itemIndex)
        internal
        pure
        returns (MatchComponent memory component)
    {
        component.amount = amount;
        component.orderIndex = orderIndex;
        component.itemIndex = itemIndex;
        // assembly {
        //     component := or(
        //         shl(AMOUNT_SHL_OFFSET, amount),
        //         or(shl(ORDER_INDEX_SHL_OFFSET, orderIndex), itemIndex)
        //     )
        // }
    }

    function getAmount(MatchComponent memory component) internal pure returns (uint256 amount) {
        return component.amount;
    }

    function copy(MatchComponent memory component) internal pure returns (MatchComponent memory copy_) {
        copy_.amount = component.amount;
        copy_.orderIndex = component.orderIndex;
        copy_.itemIndex = component.itemIndex;
    }

    function setAmount(MatchComponent memory component, uint256 amount)
        internal
        pure
        returns (MatchComponent memory newComponent)
    {
        newComponent = component.copy();
        newComponent.amount = amount;
    }

    function getOrderIndex(MatchComponent memory component) internal pure returns (uint8 orderIndex) {
        return component.orderIndex;
    }

    function setOrderIndex(MatchComponent memory component, uint8 orderIndex)
        internal
        pure
        returns (MatchComponent memory newComponent)
    {
        newComponent = component.copy();
        newComponent.orderIndex = orderIndex;
    }

    function getItemIndex(MatchComponent memory component) internal pure returns (uint8 itemIndex) {
        return component.itemIndex;
    }

    function setItemIndex(MatchComponent memory component, uint8 itemIndex)
        internal
        pure
        returns (MatchComponent memory newComponent)
    {
        newComponent = component.copy();
        newComponent.itemIndex = itemIndex;
    }

    function unpack(MatchComponent memory component)
        internal
        pure
        returns (uint256 amount, uint8 orderIndex, uint8 itemIndex)
    {
        return (component.amount, component.orderIndex, component.itemIndex);
    }

    function subtractAmount(MatchComponent memory minuend, MatchComponent memory subtrahend)
        internal
        pure
        returns (MatchComponent memory newComponent)
    {
        uint256 minuendAmount = minuend.getAmount();
        uint256 subtrahendAmount = subtrahend.getAmount();
        uint256 newAmount = uint256(minuendAmount - subtrahendAmount);
        return minuend.setAmount(newAmount);
    }

    function addAmount(MatchComponent memory target, MatchComponent memory ref)
        internal
        pure
        returns (MatchComponent memory)
    {
        uint256 targetAmount = target.getAmount();
        uint256 refAmount = ref.getAmount();
        uint256 newAmount = uint256(targetAmount + refAmount);
        return target.setAmount(newAmount);
    }

    function toFulfillmentComponent(MatchComponent memory component)
        internal
        pure
        returns (FulfillmentComponent memory)
    {
        (, uint8 orderIndex, uint8 itemIndex) = component.unpack();
        return FulfillmentComponent({orderIndex: orderIndex, itemIndex: itemIndex});
    }

    function toFulfillmentComponents(MatchComponent[] memory components)
        internal
        pure
        returns (FulfillmentComponent[] memory)
    {
        FulfillmentComponent[] memory fulfillmentComponents = new FulfillmentComponent[](
                components.length
            );
        for (uint256 i = 0; i < components.length; i++) {
            fulfillmentComponents[i] = components[i].toFulfillmentComponent();
        }
        return fulfillmentComponents;
    }

    function toStruct(MatchComponent memory component) internal pure returns (MatchComponent memory) {
        (uint256 amount, uint8 orderIndex, uint8 itemIndex) = component.unpack();
        return MatchComponent({amount: amount, orderIndex: orderIndex, itemIndex: itemIndex});
    }

    function toStructs(MatchComponent[] memory components) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory structs = new MatchComponent[](
            components.length
        );
        for (uint256 i = 0; i < components.length; i++) {
            structs[i] = components[i].toStruct();
        }
        return structs;
    }

    function equals(MatchComponent memory left, MatchComponent memory right) internal pure returns (bool) {
        return left.amount == right.amount && left.orderIndex == right.orderIndex && left.itemIndex == right.itemIndex;
    }
}
