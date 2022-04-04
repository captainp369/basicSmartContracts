// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTbuyback is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter private _tokenIds;

    //contract address of claimable/paid token
    IERC20 public token = IERC20(0xE5f2A565Ee0Aa9836B4c80a07C8b32aAd7978e22);

    struct lockInfo {
        address _address;
        uint256 _startTime;
        uint256 _claimableTime;
        uint256 _claimableReward;
    }

    bool public paused = true;
    uint256 public burnedCount = 0;

    uint256[] public timeList;
    uint256[] public rewardList;
    uint256[] public priceList;
    mapping(uint256 => lockInfo) public tokenIdToInfo;

    // put the name and symbol of your NFT collection when deploying the contract
    // string memory _collectionName, string memory _collectionSymbol
    constructor() ERC721("NFT buyback", "NFTBB") {
        timeList.push(2 minutes); // for test
        timeList.push(90 days);
        timeList.push(180 days);
        timeList.push(360 days);
        rewardList.push(1 ether); // for test
        priceList.push(0.9 ether); // for test
    }
    // timePackage -> 0:3months, 1:6months, 2:12months

    // create NFT token by providing tokenURI
    function createToken(string memory tokenURI, uint selectedTime) public returns(uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender,newItemId);
        _setTokenURI(newItemId,tokenURI);
        tokenIdToInfo[newItemId]._address = msg.sender;
        tokenIdToInfo[newItemId]._startTime = block.timestamp;
        tokenIdToInfo[newItemId]._claimableTime = tokenIdToInfo[newItemId]._startTime + timeList[selectedTime];
        tokenIdToInfo[newItemId]._claimableReward = rewardList[selectedTime];
        // need to set approve for the amount
        token.safeTransferFrom(msg.sender, address(this), priceList[selectedTime]);
        return newItemId;
    }

    function redeem(uint256 _tokenId) external {
        address _redeemer = msg.sender;
        require(_redeemer == ownerOf(_tokenId),"you are not the owner of this token");
        require(block.timestamp >= tokenIdToInfo[_tokenId]._claimableTime,"unable to redeem, the time is not reached");
        burnToken(_tokenId);
        //implement paying method here
        token.safeTransfer(_redeemer, tokenIdToInfo[_tokenId]._claimableReward);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(!paused);
        super._transfer(from,to,tokenId);
    }

    // function viewTokenOfOwner(address _owner) public view returns(uint256[] memory) {
    //     uint256 _count = balanceOf(_owner);
    //     require(_count!=0);
    //     uint256[_count] memory _tokenOfOwner;
    //     for (uint i = 1; i<=_count; i++) {
    //         if (_owner == ownerOf(i)) {
    //             _tokenOfOwner.push(i);
    //         }
    //     }
    //     return _tokenOfOwner;
    // }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // check how many NFTs were minted
    function currentId() public view returns(uint256) {
        return _tokenIds.current();
    }

    function totalSupply() public view returns(uint256) {
        return _tokenIds.current()-burnedCount;
    }

    // update/change tokenURI of the selected token
    function updateTokenURI(uint256 _selectedTokenId, string memory _newTokenURI) onlyOwner public {
        _setTokenURI(_selectedTokenId,_newTokenURI);
    }

    // permanently delete the selected token id
    // burn token is not recommended, you cannot recover the deleted token id
    // please consider using updateTokenURI instead
    function burnToken(uint256 _selectedTokenId) onlyOwner public {
        burnedCount++;
        _burn(_selectedTokenId);
    }

    // add to list
    function addTimeList(uint256 _newTime) onlyOwner public {
        timeList.push(_newTime);
    }
    function addRewardList(uint256 _newReward) onlyOwner public {
        rewardList.push(_newReward);
    }
    function addPriceList(uint256 _newPrice) onlyOwner public {
        priceList.push(_newPrice);
    }

    // transfer all of the contract balance to the owner
    function withdraw() onlyOwner public {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // transfer token to
    function tranferTokenTo(address _to, uint256 _amount) onlyOwner public {
        // (bool os, ) = payable(_to).call{value: _amount}("");
        token.safeTransfer(_to, _amount);
    }

}
