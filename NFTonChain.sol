// SPDX-License-Identifier: MIT

// Inspired by HashLips
/**
    if you are interested in learning about this
    please visit https://www.youtube.com/watch?v=UBGXFV1TQxc
*/
// contract 0x85983AE357f5B014115d599Fd13aAc298A08D150
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

contract NFTonChain is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string[] public wordValue = ["accompilsh","accepted","absolutely","admire","achievement","active","ABC","IT IS","HELLO","HELL NO","BELIEVER","FLY","I AM","THE ONE","0","SEE","WORLD"];

  uint256 public cost = 0.005 ether;
  uint256 public maxSupply = 10000;
  bool public paused = false;

  struct Word {
    string name;
    string description;
    string bgHue;
    string textHue;
    string value;
  }

  mapping(uint256=>Word) public words;

  constructor() ERC721("Meta WORD", "MTW") {}

  // public
  function mint() public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(supply + 1 <= maxSupply);

    Word memory newWord = Word(
      string(abi.encodePacked('MTW #',uint256(supply+1).toString())),
      string(abi.encodePacked('This is test on-chain NFTs, Yeah ..., and you have MTW #',uint256(supply+1).toString())),
      randomNum(361,block.difficulty,supply).toString(),
      randomNum(361,block.timestamp,supply).toString(),
      wordValue[randomNum(wordValue.length,block.difficulty,supply)]
    );

    if (msg.sender != owner()) {
      require(msg.value >= cost);
    }
    words[supply+1] = newWord;
    _safeMint(msg.sender, supply + 1);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function randomNum(uint256 _mod, uint256 _seed, uint256 _salt) public view returns(uint256) {
    uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,_seed,_salt))) % _mod;
    return num;
  }

  function buildImage(uint256 _tokenId) public view returns(string memory) {
    Word memory currentWord = words[_tokenId];
    return Base64.encode(bytes((abi.encodePacked(
      '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
      '<rect height="500" width="500" fill="hsl(',currentWord.bgHue,',50%,20%)"/>',
      '<text dominant-baseline="middle" text-anchor="middle" font-size="47" y="50%" x="50%" fill="hsl(',currentWord.textHue,',100%,80%)">',currentWord.value,'</text>',
      '</svg>'
    ))));
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    Word memory currentWord = words[_tokenId];

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(bytes(abi.encodePacked(
        '{"name":"',
        currentWord.name,
        '","description":"',
        currentWord.description,
        '","image": "',
        'data:image/svg+xml;base64,',
        buildImage(_tokenId),
        '"}'
      )))
    ));
  }

  //only owner
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    // This will pay HashLips 5% of the initial sale.
    // You can remove this if you want, or keep it in to support HashLips and his channel.
    // =============================================================================
    (bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{value: address(this).balance * 5 / 100}("");
    require(hs);
    // =============================================================================
    
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}