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
import "./GenToken.sol";
import "./GenNFT.sol";

interface IEvolution {
    function bonus(address user) external view returns (uint);
}

contract Proxy is Ownable, ERC721Holder {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    
    
    GenNFT public nft;
    IEvolution public evo;
    uint public bonusPerBurnedNFT = 50;
    
    constructor(
        GenNFT _nft,
        IEvolution _evo
    ) public {
        nft = _nft;
        evo = _evo;
    }
    
    function bonus(address user) public view returns (uint) {
        return evo.bonus(user);
    }
    
    function getNFTPowerBonusBlocks(uint nftId) external view returns (uint) {
        return nft.getTypeByTokenId(nftId).bonus % 1000000; //first 6 digits
    }
    
    function getNFTPowerBonus() external view returns (uint) {
        return bonusPerBurnedNFT;
    }
    
    function updateNFT(GenNFT _nft) public onlyOwner {
        nft = _nft;
    }
    
    function updateEvo(IEvolution _evo) public onlyOwner {
        evo = _evo;
    }
    
    function updateBonus(uint _bonusPerBurnedNFT) public onlyOwner {
        bonusPerBurnedNFT = _bonusPerBurnedNFT;
    }
}