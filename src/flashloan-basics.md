---
title: "$50M atomic uncollateralized loans do actually exist"
date: "2026-05-02T10:00:03+01:00"
layout: post
---

Flashloans are one of the most elegant concepts in DeFi. They allow you to borrow any amount of assets with 0% upfront collateral, as long as you return them within the same transaction. If you fail to repay, the entire transaction reverts effectively making the loan risk-free for the protocol. So for example you can get a flashloan for $50M and do some fancy tx with it. 

## Why they're cool

1. **No collateral required** borrow millions without putting anything down
2. **Atomic execution** everything happens in one tx or nothing happens
4. **Self-liquidation** pay off underwater positions without capital
5. **Protocol interactions** morpho, aave, uniswap all in one tx

## Morpho Flashloans

[Morpho](https://morpho.org/) provides flash loans through its bundled gateway. Here's a minimal example:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMorpho {
    function flashLoan(
        address asset,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FlashLoanArbitrage {
    IMorpho public constant MORPHO = IMorpho(0x7777777777777777777777777777777777777777);

    function executeArbitrage(
        address token,
        uint256 amount,
        address dexA,
        address dexB
    ) external {
        bytes memory data = abi.encode(dexA, dexB);
        MORPHO.flashLoan(token, amount, data);
    }

    function onMorphoFlashLoan(
        address sender,
        address asset,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external {
        (address dexA, address dexB) = abi.decode(data, (address, address));

        // tx logic in here

        uint256 repayAmount = amount + fee;
        require(IERC20(asset).balanceOf(address(this)) >= repayAmount, "repay failed");
        IERC20(asset).transfer(address(MORPHO), repayAmount);
    }
}
```

The key insight is that `onMorphoFlashLoan` gets called during the flash loan. You have `amount` to use, and you must repay `amount + fee` at the end. The beauty is in the atomicity if anything fails, the whole tx reverts and nobody loses.

**Fee example**: Morpho typically charges 0.09% (9 basis points) for flash loans.

That's it. Borrow, do your thing, repay all in one transaction. How fucking cool is that.
