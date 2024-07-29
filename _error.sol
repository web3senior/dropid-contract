// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

error Unauthorized();
error InsufficientBalance(uint256 price, uint256 amount);
error RenewalPriceNotMet(uint256 price, uint256 amount);
error SupplyingLimitExceeded(uint256 totalSupply, uint256 maxSupply);
error Reverted();