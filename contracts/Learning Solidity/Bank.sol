// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyFirstSmartcontract {
    
    struct Customer {
        string name;
        uint256 balance;
        address ethAddress;
    }

    mapping(string => Customer) customers;

    function addCustomer(string memory name, uint256 balance, address ethAddress) public {
        customers[name] = Customer(name, balance, ethAddress);
    }

    function getCustomerBalance(string memory name) public returns(uint256) {
        return customers[name].balance;
    }

    function getCustomerAddress(string memory name) public returns(address) {
        return customers[name].ethAddress;
    }

}