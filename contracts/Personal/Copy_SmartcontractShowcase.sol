// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "erc721a/contracts/ERC721A.sol";


contract SmartcontractShowcase is ERC721A, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    uint256 MAX_SUPPLY = 10000;
    bool isAllowListActive = false;
    bool saleIsActive = false;

    address signingAddress = 0x97266528bB155FC0B0D817d1011D22D3e05bf20D;

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

    // BaseURI
    string private _baseURIextended;
    mapping(uint256 => string) private _tokenURIs;

    // Events
    event DecodingMessage(address decodedAddress, address sender);

    // Royalties
    address public artist;
    address public txFeeToken;
    uint256 public txFeeAmount;
    mapping(address => bool) public excludedList;

    modifier isApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC 721: Transfer caller not owner or approved"
        );
        _;
    }
    modifier paysRoyalty(address from) {
        if (excludedList[from] == false) {
            _payTxFee(from);
        }
        _;
    }

    constructor(string memory name, string memory symbol, uint256 saleStart) ERC721A(name, symbol) {
        REVEAL_TIMESTAMP = saleStart + (86400 * 9);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner{
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setExcluded(address add, bool status) external {
        require(msg.sender == artist, "Only artist can change excluded status");
        excludedList[add] = status;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(_baseURIextended, _tokenURIs[tokenId]));
    }

    function flipIsAllowListActive() public onlyOwner {
        isAllowListActive = !isAllowListActive;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
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

        _safeMint(msg.sender, numTokens);

        _allowList[msg.sender] -= numTokens;
    }

    function _isApprovedOrOwner(address sender, uint256 tokenId) internal returns (bool) {
        return ownerOf(tokenId) == sender;
    }
    function transferFrom(address from, address to, uint256 tokenId)  
        isApprovedOrOwner(tokenId)
        paysRoyalty(from) public override {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        paysRoyalty(from) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) 
        isApprovedOrOwner(tokenId)
        paysRoyalty(from)
        public override {
            safeTransferFrom(from, to, tokenId, _data);
        }

    function _payTxFee(address from) internal {
        IERC20 token = IERC20(txFeeToken);
        token.transferFrom(from, artist, txFeeAmount);
    }


    // Token tiers
    // Provenance hash
    function mint(uint numberOfTokens, bytes calldata signature) public payable {
        require(saleIsActive, "Sale is not active");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Exceeded max limit of allowed token mints");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Not enough ETH to mint the provided number of tokens");

        address decodedAddress = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature);

        emit DecodingMessage(decodedAddress, msg.sender);
        require(signingAddress == decodedAddress, "Signer address mismatch.");

        _safeMint(msg.sender, numberOfTokens);

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    // Token tiers
    // Provenance hash
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Exceeded max limit of allowed token mints");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Not enough ETH to mint the provided number of tokens");

        _safeMint(msg.sender, numberOfTokens);

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