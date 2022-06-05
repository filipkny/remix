// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyFirstSmartcontract {

    uint256 val;

    function setVal(uint256 newVal) external {
        val = newVal;
    }

    function getVal() view public returns (uint256) {
        return val;
    }
}