// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyFirstSmartcontract {
    
    int256 val;

    function setVal(int256 newVal) external {
        val = newVal;
    }

    function getVal() view public returns (int256) {
        return val;
    }

}