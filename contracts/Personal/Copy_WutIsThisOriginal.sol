// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Stop snooping...
// Be careful if minting from the contract, this is optimized for gas costs
// for both deploying and minting. Make sure you understand how the pricing
// works for this project before smashing your keyboard in frustration.
contract WutIsThis is ERC721, Ownable {
    using Strings for uint256;

    uint16 public constant MAX_SUPPLY =       500;        // Max 1 per TX
    uint256 public constant PRICE_FOUNDERS =   0.5 ether;  // 100 Available
    uint256 public constant PRICE_FRIENDS =    0.6 ether;  // 150 Available
    uint256 public constant PRICE_SUPPORTERS = 0.7 ether;  // 250 Available

    bool public saleIsActive = false;
    string private _baseTokenURI;

    uint16 private mintIndex;

    // Constructor, because why not? (I don't know why)
    constructor() ERC721("WutIsThis", "WITS") { 
        mintIndex = 1;
    }

    // Just mint the JPEG already! (P.S. You can only mint one at a time)
    function mint() public payable {
        require(saleIsActive, "JPEGs are not for sale yet!");

        require(mintIndex <= MAX_SUPPLY, "JPEGs are sold out!");
        require(msg.value >= currentPrice(), "Not enough ETH to buy a JPEG!");

        // Mint. That's the easy part.
        _safeMint(msg.sender, mintIndex);
        mintIndex = mintIndex + 1;
    }

    // How much is this JPEG going to cost me?
    function currentPrice() public view returns (uint256) {
        uint16 numMinted = mintIndex - 1;
        // Order return statements by descending statistical likelihood
        if (numMinted > 250) { 
            return PRICE_SUPPORTERS;
        } else if (numMinted > 100) {
            return PRICE_FRIENDS;
        } else {
            return PRICE_FOUNDERS;
        }
    }

    // I wonder how many JPEGs are left?
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - mintIndex - 1;
    }

    // All the functions you don't really care about but need to be here
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Go go go!
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // You had to expect this function, right?
    function withdrawBalance() public onlyOwner {
        payable("asdsad").transfer(address(this).balance*0.25);
        payable(msg.sender).transfer(address(this).balance);
    }

    // This is only for testing purposes (and is not part of the mainnet contract)
    // WILL BE DELETED
    function adminMint(uint256 numberOfTokens) public onlyOwner {
        
        require(mintIndex - 1 + numberOfTokens <= MAX_SUPPLY, "Exceeds max supply");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, mintIndex);
        }
    }
}