// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../oz/utils/structs/EnumerableSet.sol";
import "../oz/access/Ownable.sol";
import "../oz/token/ERC20/ERC20.sol";
import "../oz/token/ERC20/IERC20.sol";
import "../oz/token/ERC20/utils/SafeERC20.sol";
import "../oz/token/ERC721/utils/ERC721Holder.sol";
import '../oz/token/ERC721/IERC721.sol';
import "../oz/utils/math/SafeMath.sol";
import "./GenNFT.sol";


contract Fuse is Ownable, ERC721Holder {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    // The NFT TOKEN!
    GenNFT public nft;
    constructor(
        GenNFT _nft
    ) public {
        nft = _nft;
    }
    
    function fuseNFT(uint[] memory _nftIds) public {
        
        require(_nftIds.length == 4, "NFT amount is wrong");
        require(nft.ownerOf(_nftIds[0]) == msg.sender, "you don't own token");
        require(nft.ownerOf(_nftIds[1]) == msg.sender, "you don't own token");
        require(nft.ownerOf(_nftIds[2]) == msg.sender, "you don't own token");
        require(nft.ownerOf(_nftIds[3]) == msg.sender, "you don't own token");
        uint nftTypeId = nft.getTypeByTokenId(_nftIds[0]).id;
        
        require(nftTypeId < 7, "you are Higher being");
        require(nft.getTypeByTokenId(_nftIds[1]).id == nftTypeId, "Wrong nft type");
        require(nft.getTypeByTokenId(_nftIds[2]).id == nftTypeId, "Wrong nft type");
        require(nft.getTypeByTokenId(_nftIds[3]).id == nftTypeId, "Wrong nft type");
    
        nft.changeType(_nftIds[0], nftTypeId + 1);
        nft.changeType(_nftIds[1], 0);
        nft.changeType(_nftIds[2], 0);
        nft.changeType(_nftIds[3], 0);
    }
}