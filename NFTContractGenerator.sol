// SPDX-License-Identifier: MIT

/*
    **!DISCLAIMER!**
    PLEASE CHECK & REVEAL THE CONTRACT ON YOUR OWN 
    BEFORE DEPLOYING ON THE MAINNET (USING REAL MONEY)
    The developer will not be responsible or liable for all loss or 
    damage whatsoever caused by using the code.
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTContractGenerator is Ownable {
    address[] public deployedContracts;

    function createContract(string memory _collectionName, string memory _collectionSymbol) public {
        basicNFT newContract = new basicNFT(_collectionName,_collectionSymbol);
        deployedContracts.push(address(newContract));
    }

    function getAllDeployedContracts() public view returns(address[] memory) {
        return deployedContracts;
    }

    //onlyOwner
    function withdraw() onlyOwner public {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}

contract basicNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // put the name and symbol of your NFT collection when deploying the contract
    constructor(string memory _collectionName, string memory _collectionSymbol)
        ERC721(_collectionName, _collectionSymbol) {
            transferOwnership(tx.origin);
        }

    // create NFT token by providing tokenURI
    function createToken(string memory tokenURI) onlyOwner public returns(uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender,newItemId);
        _setTokenURI(newItemId,tokenURI);
        return newItemId;
    }

    // check how many NFTs were minted
    function currentSupply() public view returns(uint256) {
        return _tokenIds.current();
    }

    // update/change tokenURI of the selected token
    function updateTokenURI(uint256 _selectedTokenId, string memory _newTokenURI) onlyOwner public {
        _setTokenURI(_selectedTokenId,_newTokenURI);
    }

    // permanently delete the selected token id
    // burn token is not recommended, you cannot recover the deleted token id
    // please consider using updateTokenURI instead
    function burnToken(uint256 _selectedTokenId) onlyOwner public {
        _tokenIds.decrement();
        _burn(_selectedTokenId);
    }

    // transfer all of the contract balance to the owner
    function withdraw() onlyOwner public {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}
