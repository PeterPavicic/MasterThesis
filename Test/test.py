#!/usr/bin/python

from enum import EnumDict

class SQ(EnumDict):
    OrdersMatchedGlobal = {
        "name": "testName",
        "returnVariables": [
            "tradesQuantity",
            "buysQuantity",
            "sellsQuantity",
            "collateralVolume",
            "scaledCollateralVolume",
            "collateralBuyVolume",
            "scaledCollateralBuyVolume",
            "collateralSellVolume",
            "scaledCollateralSellVolume"
        ]
    }
    """
    Exchange - all trades aggregated
    Input: Filtering
    Returns: tradesQuantity, buysQuantity, sellsQuantity, collateralVolume, scaledCollateralVolume, collateralBuyVolume, scaledCollateralBuyVolume, collateralSellVolume, scaledCollateralSellVolume
    """


if __name__ == "__main__":
    print(SQ.OrdersMatchedGlobal)
    print(SQ.OrdersMatchedGlobal["name"])


