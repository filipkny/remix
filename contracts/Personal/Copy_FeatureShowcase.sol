// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "erc721a/contracts/ERC721A.sol";


contract FeatureShowcase is ERC721A, Ownable {
    using SafeMath for uint256;

    uint256 MAX_SUPPLY = 10000;
    bool isAllowListActive = false;
    bool saleIsActive = false;

    // Minimum price
    uint256 public tokenPrice = 0.08 ether;

    // Provenance hash
    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    // Whitelist/Airdrops: mapping with whitelisted addresses and 
    // the number of tokens they are allowed to mint
    mapping(address => uint8) private _allowList;

    // Reveal
    uint256 public REVEAL_TIMESTAMP;

    constructor(string memory name, string memory symbol, uint256 saleStart) ERC721A(name, symbol) {
        REVEAL_TIMESTAMP = saleStart + (86400 * 9);
    }
    // Why are we using an external function here instead of, maybe, public? 
    // Well, because external functions are sometimes more efficient when they receive large arrays of data.
    // (from https://ethereum.stackexchange.com/questions/19380/external-vs-public-best-practices)
    // Calldata variables are special (more efficient) data locations that contain function arguments.
    // They are only available for external functions.
    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function mintAllowList(uint8 numTokens) external payable {
        uint256 ts = totalSupply();

        require(isAllowListActive, "Allow list is not active");
        require(numTokens <= _allowList[msg.sender], "Exceeded max limit of allowed token mints");
        require(ts + numTokens <= MAX_SUPPLY, "Exceeded max supply");
        require(tokenPrice * numTokens <= msg.value, "Not enough ETH to mint the provided number of tokens");

        for (uint16 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }

        _allowList[msg.sender] -= numTokens;
    }

    // Token tiers
    // Provenance hash
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Ape");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply of Apes");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (mintIndex < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    // Pay to adresses
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}