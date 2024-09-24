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

import {
    AdditionalRecipient,
    AdvancedOrder,
    BasicOrderParameters,
    ConsiderationItem,
    CriteriaResolver,
    Fulfillment,
    FulfillmentComponent,
    OfferItem,
    Order,
    OrderComponents,
    OrderParameters,
    ReceivedItem,
    SpentItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

library SeaportArrays {
    function Orders(Order memory a) internal pure returns (Order[] memory) {
        Order[] memory arr = new Order[](1);
        arr[0] = a;
        return arr;
    }

    function Orders(
        Order memory a,
        Order memory b
    ) internal pure returns (Order[] memory) {
        Order[] memory arr = new Order[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function Orders(
        Order memory a,
        Order memory b,
        Order memory c
    ) internal pure returns (Order[] memory) {
        Order[] memory arr = new Order[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function Orders(
        Order memory a,
        Order memory b,
        Order memory c,
        Order memory d
    ) internal pure returns (Order[] memory) {
        Order[] memory arr = new Order[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function Orders(
        Order memory a,
        Order memory b,
        Order memory c,
        Order memory d,
        Order memory e
    ) internal pure returns (Order[] memory) {
        Order[] memory arr = new Order[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function Orders(
        Order memory a,
        Order memory b,
        Order memory c,
        Order memory d,
        Order memory e,
        Order memory f
    ) internal pure returns (Order[] memory) {
        Order[] memory arr = new Order[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function Orders(
        Order memory a,
        Order memory b,
        Order memory c,
        Order memory d,
        Order memory e,
        Order memory f,
        Order memory g
    ) internal pure returns (Order[] memory) {
        Order[] memory arr = new Order[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function AdvancedOrders(
        AdvancedOrder memory a
    ) internal pure returns (AdvancedOrder[] memory) {
        AdvancedOrder[] memory arr = new AdvancedOrder[](1);
        arr[0] = a;
        return arr;
    }

    function AdvancedOrders(
        AdvancedOrder memory a,
        AdvancedOrder memory b
    ) internal pure returns (AdvancedOrder[] memory) {
        AdvancedOrder[] memory arr = new AdvancedOrder[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function AdvancedOrders(
        AdvancedOrder memory a,
        AdvancedOrder memory b,
        AdvancedOrder memory c
    ) internal pure returns (AdvancedOrder[] memory) {
        AdvancedOrder[] memory arr = new AdvancedOrder[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function AdvancedOrders(
        AdvancedOrder memory a,
        AdvancedOrder memory b,
        AdvancedOrder memory c,
        AdvancedOrder memory d
    ) internal pure returns (AdvancedOrder[] memory) {
        AdvancedOrder[] memory arr = new AdvancedOrder[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function AdvancedOrders(
        AdvancedOrder memory a,
        AdvancedOrder memory b,
        AdvancedOrder memory c,
        AdvancedOrder memory d,
        AdvancedOrder memory e
    ) internal pure returns (AdvancedOrder[] memory) {
        AdvancedOrder[] memory arr = new AdvancedOrder[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function AdvancedOrders(
        AdvancedOrder memory a,
        AdvancedOrder memory b,
        AdvancedOrder memory c,
        AdvancedOrder memory d,
        AdvancedOrder memory e,
        AdvancedOrder memory f
    ) internal pure returns (AdvancedOrder[] memory) {
        AdvancedOrder[] memory arr = new AdvancedOrder[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function AdvancedOrders(
        AdvancedOrder memory a,
        AdvancedOrder memory b,
        AdvancedOrder memory c,
        AdvancedOrder memory d,
        AdvancedOrder memory e,
        AdvancedOrder memory f,
        AdvancedOrder memory g
    ) internal pure returns (AdvancedOrder[] memory) {
        AdvancedOrder[] memory arr = new AdvancedOrder[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function OrderComponentsArray(
        OrderComponents memory a
    ) internal pure returns (OrderComponents[] memory) {
        OrderComponents[] memory arr = new OrderComponents[](1);
        arr[0] = a;
        return arr;
    }

    function OrderComponentsArray(
        OrderComponents memory a,
        OrderComponents memory b
    ) internal pure returns (OrderComponents[] memory) {
        OrderComponents[] memory arr = new OrderComponents[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function OrderComponentsArray(
        OrderComponents memory a,
        OrderComponents memory b,
        OrderComponents memory c
    ) internal pure returns (OrderComponents[] memory) {
        OrderComponents[] memory arr = new OrderComponents[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function OrderComponentsArray(
        OrderComponents memory a,
        OrderComponents memory b,
        OrderComponents memory c,
        OrderComponents memory d
    ) internal pure returns (OrderComponents[] memory) {
        OrderComponents[] memory arr = new OrderComponents[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function OrderComponentsArray(
        OrderComponents memory a,
        OrderComponents memory b,
        OrderComponents memory c,
        OrderComponents memory d,
        OrderComponents memory e
    ) internal pure returns (OrderComponents[] memory) {
        OrderComponents[] memory arr = new OrderComponents[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function OrderComponentsArray(
        OrderComponents memory a,
        OrderComponents memory b,
        OrderComponents memory c,
        OrderComponents memory d,
        OrderComponents memory e,
        OrderComponents memory f
    ) internal pure returns (OrderComponents[] memory) {
        OrderComponents[] memory arr = new OrderComponents[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function OrderComponentsArray(
        OrderComponents memory a,
        OrderComponents memory b,
        OrderComponents memory c,
        OrderComponents memory d,
        OrderComponents memory e,
        OrderComponents memory f,
        OrderComponents memory g
    ) internal pure returns (OrderComponents[] memory) {
        OrderComponents[] memory arr = new OrderComponents[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function OrderParametersArray(
        OrderParameters memory a
    ) internal pure returns (OrderParameters[] memory) {
        OrderParameters[] memory arr = new OrderParameters[](1);
        arr[0] = a;
        return arr;
    }

    function OrderParametersArray(
        OrderParameters memory a,
        OrderParameters memory b
    ) internal pure returns (OrderParameters[] memory) {
        OrderParameters[] memory arr = new OrderParameters[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function OrderParametersArray(
        OrderParameters memory a,
        OrderParameters memory b,
        OrderParameters memory c
    ) internal pure returns (OrderParameters[] memory) {
        OrderParameters[] memory arr = new OrderParameters[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function OrderParametersArray(
        OrderParameters memory a,
        OrderParameters memory b,
        OrderParameters memory c,
        OrderParameters memory d
    ) internal pure returns (OrderParameters[] memory) {
        OrderParameters[] memory arr = new OrderParameters[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function OrderParametersArray(
        OrderParameters memory a,
        OrderParameters memory b,
        OrderParameters memory c,
        OrderParameters memory d,
        OrderParameters memory e
    ) internal pure returns (OrderParameters[] memory) {
        OrderParameters[] memory arr = new OrderParameters[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function OrderParametersArray(
        OrderParameters memory a,
        OrderParameters memory b,
        OrderParameters memory c,
        OrderParameters memory d,
        OrderParameters memory e,
        OrderParameters memory f
    ) internal pure returns (OrderParameters[] memory) {
        OrderParameters[] memory arr = new OrderParameters[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function OrderParametersArray(
        OrderParameters memory a,
        OrderParameters memory b,
        OrderParameters memory c,
        OrderParameters memory d,
        OrderParameters memory e,
        OrderParameters memory f,
        OrderParameters memory g
    ) internal pure returns (OrderParameters[] memory) {
        OrderParameters[] memory arr = new OrderParameters[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function OfferItems(
        OfferItem memory a
    ) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory arr = new OfferItem[](1);
        arr[0] = a;
        return arr;
    }

    function OfferItems(
        OfferItem memory a,
        OfferItem memory b
    ) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory arr = new OfferItem[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function OfferItems(
        OfferItem memory a,
        OfferItem memory b,
        OfferItem memory c
    ) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory arr = new OfferItem[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function OfferItems(
        OfferItem memory a,
        OfferItem memory b,
        OfferItem memory c,
        OfferItem memory d
    ) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory arr = new OfferItem[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function OfferItems(
        OfferItem memory a,
        OfferItem memory b,
        OfferItem memory c,
        OfferItem memory d,
        OfferItem memory e
    ) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory arr = new OfferItem[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function OfferItems(
        OfferItem memory a,
        OfferItem memory b,
        OfferItem memory c,
        OfferItem memory d,
        OfferItem memory e,
        OfferItem memory f
    ) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory arr = new OfferItem[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function OfferItems(
        OfferItem memory a,
        OfferItem memory b,
        OfferItem memory c,
        OfferItem memory d,
        OfferItem memory e,
        OfferItem memory f,
        OfferItem memory g
    ) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory arr = new OfferItem[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function ConsiderationItems(
        ConsiderationItem memory a
    ) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory arr = new ConsiderationItem[](1);
        arr[0] = a;
        return arr;
    }

    function ConsiderationItems(
        ConsiderationItem memory a,
        ConsiderationItem memory b
    ) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory arr = new ConsiderationItem[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function ConsiderationItems(
        ConsiderationItem memory a,
        ConsiderationItem memory b,
        ConsiderationItem memory c
    ) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory arr = new ConsiderationItem[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function ConsiderationItems(
        ConsiderationItem memory a,
        ConsiderationItem memory b,
        ConsiderationItem memory c,
        ConsiderationItem memory d
    ) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory arr = new ConsiderationItem[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function ConsiderationItems(
        ConsiderationItem memory a,
        ConsiderationItem memory b,
        ConsiderationItem memory c,
        ConsiderationItem memory d,
        ConsiderationItem memory e
    ) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory arr = new ConsiderationItem[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function ConsiderationItems(
        ConsiderationItem memory a,
        ConsiderationItem memory b,
        ConsiderationItem memory c,
        ConsiderationItem memory d,
        ConsiderationItem memory e,
        ConsiderationItem memory f
    ) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory arr = new ConsiderationItem[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function ConsiderationItems(
        ConsiderationItem memory a,
        ConsiderationItem memory b,
        ConsiderationItem memory c,
        ConsiderationItem memory d,
        ConsiderationItem memory e,
        ConsiderationItem memory f,
        ConsiderationItem memory g
    ) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory arr = new ConsiderationItem[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function SpentItems(
        SpentItem memory a
    ) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory arr = new SpentItem[](1);
        arr[0] = a;
        return arr;
    }

    function SpentItems(
        SpentItem memory a,
        SpentItem memory b
    ) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory arr = new SpentItem[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function SpentItems(
        SpentItem memory a,
        SpentItem memory b,
        SpentItem memory c
    ) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory arr = new SpentItem[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function SpentItems(
        SpentItem memory a,
        SpentItem memory b,
        SpentItem memory c,
        SpentItem memory d
    ) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory arr = new SpentItem[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function SpentItems(
        SpentItem memory a,
        SpentItem memory b,
        SpentItem memory c,
        SpentItem memory d,
        SpentItem memory e
    ) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory arr = new SpentItem[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function SpentItems(
        SpentItem memory a,
        SpentItem memory b,
        SpentItem memory c,
        SpentItem memory d,
        SpentItem memory e,
        SpentItem memory f
    ) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory arr = new SpentItem[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function SpentItems(
        SpentItem memory a,
        SpentItem memory b,
        SpentItem memory c,
        SpentItem memory d,
        SpentItem memory e,
        SpentItem memory f,
        SpentItem memory g
    ) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory arr = new SpentItem[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function ReceivedItems(
        ReceivedItem memory a
    ) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory arr = new ReceivedItem[](1);
        arr[0] = a;
        return arr;
    }

    function ReceivedItems(
        ReceivedItem memory a,
        ReceivedItem memory b
    ) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory arr = new ReceivedItem[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function ReceivedItems(
        ReceivedItem memory a,
        ReceivedItem memory b,
        ReceivedItem memory c
    ) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory arr = new ReceivedItem[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function ReceivedItems(
        ReceivedItem memory a,
        ReceivedItem memory b,
        ReceivedItem memory c,
        ReceivedItem memory d
    ) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory arr = new ReceivedItem[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function ReceivedItems(
        ReceivedItem memory a,
        ReceivedItem memory b,
        ReceivedItem memory c,
        ReceivedItem memory d,
        ReceivedItem memory e
    ) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory arr = new ReceivedItem[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function ReceivedItems(
        ReceivedItem memory a,
        ReceivedItem memory b,
        ReceivedItem memory c,
        ReceivedItem memory d,
        ReceivedItem memory e,
        ReceivedItem memory f
    ) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory arr = new ReceivedItem[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function ReceivedItems(
        ReceivedItem memory a,
        ReceivedItem memory b,
        ReceivedItem memory c,
        ReceivedItem memory d,
        ReceivedItem memory e,
        ReceivedItem memory f,
        ReceivedItem memory g
    ) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory arr = new ReceivedItem[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](1);
        arr[0] = a;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d,
        FulfillmentComponent memory e
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d,
        FulfillmentComponent memory e,
        FulfillmentComponent memory f
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d,
        FulfillmentComponent memory e,
        FulfillmentComponent memory f,
        FulfillmentComponent memory g
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](1);
        arr[0] = a;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d,
        FulfillmentComponent[] memory e
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d,
        FulfillmentComponent[] memory e,
        FulfillmentComponent[] memory f
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d,
        FulfillmentComponent[] memory e,
        FulfillmentComponent[] memory f,
        FulfillmentComponent[] memory g
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function CriteriaResolvers(
        CriteriaResolver memory a
    ) internal pure returns (CriteriaResolver[] memory) {
        CriteriaResolver[] memory arr = new CriteriaResolver[](1);
        arr[0] = a;
        return arr;
    }

    function CriteriaResolvers(
        CriteriaResolver memory a,
        CriteriaResolver memory b
    ) internal pure returns (CriteriaResolver[] memory) {
        CriteriaResolver[] memory arr = new CriteriaResolver[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function CriteriaResolvers(
        CriteriaResolver memory a,
        CriteriaResolver memory b,
        CriteriaResolver memory c
    ) internal pure returns (CriteriaResolver[] memory) {
        CriteriaResolver[] memory arr = new CriteriaResolver[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function CriteriaResolvers(
        CriteriaResolver memory a,
        CriteriaResolver memory b,
        CriteriaResolver memory c,
        CriteriaResolver memory d
    ) internal pure returns (CriteriaResolver[] memory) {
        CriteriaResolver[] memory arr = new CriteriaResolver[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function CriteriaResolvers(
        CriteriaResolver memory a,
        CriteriaResolver memory b,
        CriteriaResolver memory c,
        CriteriaResolver memory d,
        CriteriaResolver memory e
    ) internal pure returns (CriteriaResolver[] memory) {
        CriteriaResolver[] memory arr = new CriteriaResolver[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function CriteriaResolvers(
        CriteriaResolver memory a,
        CriteriaResolver memory b,
        CriteriaResolver memory c,
        CriteriaResolver memory d,
        CriteriaResolver memory e,
        CriteriaResolver memory f
    ) internal pure returns (CriteriaResolver[] memory) {
        CriteriaResolver[] memory arr = new CriteriaResolver[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function CriteriaResolvers(
        CriteriaResolver memory a,
        CriteriaResolver memory b,
        CriteriaResolver memory c,
        CriteriaResolver memory d,
        CriteriaResolver memory e,
        CriteriaResolver memory f,
        CriteriaResolver memory g
    ) internal pure returns (CriteriaResolver[] memory) {
        CriteriaResolver[] memory arr = new CriteriaResolver[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function AdditionalRecipients(
        AdditionalRecipient memory a
    ) internal pure returns (AdditionalRecipient[] memory) {
        AdditionalRecipient[] memory arr = new AdditionalRecipient[](1);
        arr[0] = a;
        return arr;
    }

    function AdditionalRecipients(
        AdditionalRecipient memory a,
        AdditionalRecipient memory b
    ) internal pure returns (AdditionalRecipient[] memory) {
        AdditionalRecipient[] memory arr = new AdditionalRecipient[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function AdditionalRecipients(
        AdditionalRecipient memory a,
        AdditionalRecipient memory b,
        AdditionalRecipient memory c
    ) internal pure returns (AdditionalRecipient[] memory) {
        AdditionalRecipient[] memory arr = new AdditionalRecipient[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function AdditionalRecipients(
        AdditionalRecipient memory a,
        AdditionalRecipient memory b,
        AdditionalRecipient memory c,
        AdditionalRecipient memory d
    ) internal pure returns (AdditionalRecipient[] memory) {
        AdditionalRecipient[] memory arr = new AdditionalRecipient[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function AdditionalRecipients(
        AdditionalRecipient memory a,
        AdditionalRecipient memory b,
        AdditionalRecipient memory c,
        AdditionalRecipient memory d,
        AdditionalRecipient memory e
    ) internal pure returns (AdditionalRecipient[] memory) {
        AdditionalRecipient[] memory arr = new AdditionalRecipient[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function AdditionalRecipients(
        AdditionalRecipient memory a,
        AdditionalRecipient memory b,
        AdditionalRecipient memory c,
        AdditionalRecipient memory d,
        AdditionalRecipient memory e,
        AdditionalRecipient memory f
    ) internal pure returns (AdditionalRecipient[] memory) {
        AdditionalRecipient[] memory arr = new AdditionalRecipient[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function AdditionalRecipients(
        AdditionalRecipient memory a,
        AdditionalRecipient memory b,
        AdditionalRecipient memory c,
        AdditionalRecipient memory d,
        AdditionalRecipient memory e,
        AdditionalRecipient memory f,
        AdditionalRecipient memory g
    ) internal pure returns (AdditionalRecipient[] memory) {
        AdditionalRecipient[] memory arr = new AdditionalRecipient[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function BasicOrderParametersArray(
        BasicOrderParameters memory a
    ) internal pure returns (BasicOrderParameters[] memory) {
        BasicOrderParameters[] memory arr = new BasicOrderParameters[](1);
        arr[0] = a;
        return arr;
    }

    function BasicOrderParametersArray(
        BasicOrderParameters memory a,
        BasicOrderParameters memory b
    ) internal pure returns (BasicOrderParameters[] memory) {
        BasicOrderParameters[] memory arr = new BasicOrderParameters[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function BasicOrderParametersArray(
        BasicOrderParameters memory a,
        BasicOrderParameters memory b,
        BasicOrderParameters memory c
    ) internal pure returns (BasicOrderParameters[] memory) {
        BasicOrderParameters[] memory arr = new BasicOrderParameters[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function BasicOrderParametersArray(
        BasicOrderParameters memory a,
        BasicOrderParameters memory b,
        BasicOrderParameters memory c,
        BasicOrderParameters memory d
    ) internal pure returns (BasicOrderParameters[] memory) {
        BasicOrderParameters[] memory arr = new BasicOrderParameters[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function BasicOrderParametersArray(
        BasicOrderParameters memory a,
        BasicOrderParameters memory b,
        BasicOrderParameters memory c,
        BasicOrderParameters memory d,
        BasicOrderParameters memory e
    ) internal pure returns (BasicOrderParameters[] memory) {
        BasicOrderParameters[] memory arr = new BasicOrderParameters[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function BasicOrderParametersArray(
        BasicOrderParameters memory a,
        BasicOrderParameters memory b,
        BasicOrderParameters memory c,
        BasicOrderParameters memory d,
        BasicOrderParameters memory e,
        BasicOrderParameters memory f
    ) internal pure returns (BasicOrderParameters[] memory) {
        BasicOrderParameters[] memory arr = new BasicOrderParameters[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function BasicOrderParametersArray(
        BasicOrderParameters memory a,
        BasicOrderParameters memory b,
        BasicOrderParameters memory c,
        BasicOrderParameters memory d,
        BasicOrderParameters memory e,
        BasicOrderParameters memory f,
        BasicOrderParameters memory g
    ) internal pure returns (BasicOrderParameters[] memory) {
        BasicOrderParameters[] memory arr = new BasicOrderParameters[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](1);
        arr[0] = a;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a,
        Fulfillment memory b
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d,
        Fulfillment memory e
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d,
        Fulfillment memory e,
        Fulfillment memory f
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d,
        Fulfillment memory e,
        Fulfillment memory f,
        Fulfillment memory g
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }
}
