// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./PeripheryImmutableState.sol";
import "../utils/Constants.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ERC721 } from "solmate/tokens/ERC721.sol";
import { ERC1155 } from "solmate/tokens/ERC1155.sol";

/// @author Uniswap Foundation
abstract contract PeripheryPayments is PeripheryImmutableState {
  function approveERC20(address token, address spender, uint256 amount) public {
    uint256 balance = ERC20(token).balanceOf(address(this));
    amount = amount == Constants.MAX_BALANCE ? balance : amount;
    require(amount <= balance, "Error: Insufficient ERC20 balance");

    SafeTransferLib.safeApprove(ERC20(token), spender, amount);
  }

  function sweep(address token, address recipient, uint256 amountMinimum)
    public
  {
    uint256 balance;
    if (token == Constants.ETH) {
      balance = address(this).balance;
      require(balance >= amountMinimum, "Error: Insufficient ETH balance");

      if (balance > 0) {
        SafeTransferLib.safeTransferETH(recipient, balance);
      }
    } else {
      balance = ERC20(token).balanceOf(address(this));
      require(balance >= amountMinimum, "Error: Insufficient ERC20 balance");

      if (balance > 0) {
        SafeTransferLib.safeTransfer(ERC20(token), recipient, balance);
      }
    }
  }

  function sweepERC721(address token, address recipient, uint256 id) public {
    ERC721(token).safeTransferFrom(address(this), recipient, id);
  }

  function sweepERC1155(
    address token,
    address recipient,
    uint256 id,
    uint256 amountMinimum
  ) public {
    uint256 balance = ERC1155(token).balanceOf(address(this), id);
    require(balance >= amountMinimum, "Error: Insufficient ERC1155 balance");
    ERC1155(token).safeTransferFrom(
      address(this), recipient, id, balance, bytes("")
    );
  }

  function pay(address token, address payer, address recipient, uint256 value)
    public
  {
    if (token == Constants.ETH && payer == address(this)) {
      value = value == Constants.MAX_BALANCE ? address(this).balance : value;
      SafeTransferLib.safeTransferETH(recipient, value);
    } else {
      value =
        value == Constants.MAX_BALANCE ? ERC20(token).balanceOf(payer) : value;
      if (payer == address(this)) {
        SafeTransferLib.safeTransfer(ERC20(token), recipient, value);
      } else {
        SafeTransferLib.safeTransferFrom(ERC20(token), payer, recipient, value);
      }
    }
  }

  function payPortion(address token, address recipient, uint256 bips) public {
    require(bips != 0 && bips <= Constants.FEE_BIPS_BASE, "Error: invalid bips");
    if (token == Constants.ETH) {
      uint256 balance = address(this).balance;
      uint256 amount = (balance * bips) / Constants.FEE_BIPS_BASE;
      SafeTransferLib.safeTransferETH(recipient, amount);
    } else {
      uint256 balance = ERC20(token).balanceOf(address(this));
      uint256 amount = (balance * bips) / Constants.FEE_BIPS_BASE;
      SafeTransferLib.safeTransfer(ERC20(token), recipient, amount);
    }
  }

  function wrapETH(address recipient, uint256 amount) public {
    amount = amount == Constants.MAX_BALANCE ? address(this).balance : amount;
    require(amount <= address(this).balance, "Error: Insufficient ETH");

    if (amount > 0) {
      WETH9.deposit{ value: amount }();
      if (recipient != address(this)) {
        WETH9.transfer(recipient, amount);
      }
    }
  }

  function unwrapWETH9(address recipient, uint256 amountMinimum) public {
    uint256 value = WETH9.balanceOf(address(this));
    require(value >= amountMinimum, "Error: Insufficient ETH");
    if (value > 0) {
      WETH9.withdraw(value);
      if (recipient != address(this)) {
        SafeTransferLib.safeTransferETH(recipient, value);
      }
    }
  }
}
