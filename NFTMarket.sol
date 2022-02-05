//SPDX-License-Identifier: MIT

/* 
    basic NFT Marketplace contract
    no royalty fee implemented yet
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarket is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds ;
    Counters.Counter private _itemsSold ;
    uint256 listingPrice; //= 0.025 ether; up to the network and can be change later
    uint256 marketFee; // divide by 100
    address public Deployer;

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable currentOwner;
        address payable creator;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    constructor() {
        Deployer = msg.sender;
    }

    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address payable currentOwner,
        address payable creator,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createMarketItem(address nftContract, uint256 tokenId)
        public payable nonReentrant {
            _itemIds.increment();
            uint256 itemId = _itemIds.current();
            idToMarketItem[itemId] = MarketItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(msg.sender),
                0,
                false
            );
            emit MarketItemCreated(itemId, nftContract, tokenId, payable(msg.sender), payable(msg.sender), 0, false);
        }
    
    function listItem(address nftContract, uint256 itemId, uint256 _price) public payable nonReentrant {
        require(idToMarketItem[itemId].currentOwner == msg.sender);
        require(_price>0,"price must be at least 1 wei");
        require(msg.value >= listingPrice,"need to pay listing price");
        uint tokenId = idToMarketItem[itemId].tokenId;
        idToMarketItem[itemId].price = _price;
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }

    function unlistItem(address nftContract, uint256 itemId) public nonReentrant {
        require(idToMarketItem[itemId].currentOwner == msg.sender);
        uint tokenId = idToMarketItem[itemId].tokenId;
        idToMarketItem[itemId].price = 0;
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    }

    function getItemPrice(uint256 itemId) public view returns(uint256) {
        uint price = idToMarketItem[itemId].price;
        uint _marketFee = (marketFee * price) / 100;
        return price+_marketFee;
    }

    function createMarketSale(address nftContract, uint256 itemId)
        public payable nonReentrant {
            require(msg.sender!=idToMarketItem[itemId].currentOwner);
            uint price = idToMarketItem[itemId].price;
            uint tokenId = idToMarketItem[itemId].tokenId;
            // uint _marketFee = (marketFee * price) / 100;
            uint totalpay = getItemPrice(itemId);
            require(msg.value >= totalpay,"submit the asking price to complete the purchase");
            idToMarketItem[itemId].currentOwner.transfer(price);
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
            //idToMarketItem[itemId].creator = payable(msg.sender); for implement royalty fee
            idToMarketItem[itemId].sold = true;
            idToMarketItem[itemId].currentOwner = payable(msg.sender);
            idToMarketItem[itemId].price = 0;
            _itemsSold.increment();
    }

    function transfer(address nftContract, uint256 itemId, address payable _to) public nonReentrant {
        require(idToMarketItem[itemId].currentOwner == msg.sender);
        uint tokenId = idToMarketItem[itemId].tokenId;
        IERC721(nftContract).transferFrom(msg.sender, _to, tokenId);
        idToMarketItem[itemId].currentOwner = _to;
    }

    // fetch data
    function fetchMarketItems() public view returns(MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        // uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;
        // MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0;i<itemCount;i++) {
            // if (idToMarketItem[i+1].creator == address(0)) {
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1 ;
            // }
        }
        return items;
    }

    function fetchMyNFTs() public view returns(MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i=0;i<totalItemCount;i++) {
            if(idToMarketItem[i+1].currentOwner==msg.sender) {
                itemCount+=1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i=0;i<totalItemCount;i++) {
            if(idToMarketItem[i+1].currentOwner==msg.sender){
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex+=1;
            }
        }
        return items;
    }

    function fetchItemsCreated() public view returns(MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i=0;i<totalItemCount;i++) {
            if(idToMarketItem[i+1].creator==msg.sender) {
                itemCount+=1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i=0;i<totalItemCount;i++) {
            if(idToMarketItem[i+1].creator==msg.sender){
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex+=1;
            }
        }
        return items;
    }

    // only owner
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function setListingPrice(uint256 _listingPrice) external onlyOwner {
        listingPrice = _listingPrice;
    }

    function setMarketFee(uint256 _marketFee) external onlyOwner {
        marketFee = _marketFee;
    }
}