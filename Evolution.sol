// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "../oz/utils/structs/EnumerableSet.sol";
import "../oz/access/Ownable.sol";
import "../oz/token/ERC20/ERC20.sol";
import "../oz/token/ERC20/IERC20.sol";
import "../oz/token/ERC20/utils/SafeERC20.sol";
import "../oz/token/ERC721/utils/ERC721Holder.sol";
import '../oz/token/ERC721/IERC721.sol';
import "../oz/utils/math/SafeMath.sol";
import "./GenNFT.sol";

    
struct Param {
    uint price;
    uint bonus;
    uint winChance;
}

contract Evolution is Ownable, ERC721Holder {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    
    
    
    mapping (uint => uint) public winChances; // chance To Win evolution
    mapping (uint => uint) public prices; // minimum price for evolution
    mapping (uint => uint) public bonuses; // nftTypeId -> bonus
    mapping (address => uint) public userNFT; // user -> nftId
    
    mapping (uint256 => mapping (address => uint)) public evolutions; // evoIndex -> user -> payment
    
    uint public higherBeing = 7;
    uint public evoTime = 5 * 60 / 3;//24 * 3600 / 3;

    uint public startBlock = 0;
    mapping (uint => uint) public blockHashForEvo; // evo -> blockHash
    
    
    GenNFT public nft;
    IERC20 public gen;
    
    constructor(IERC20 _gen, GenNFT _nft) {
        gen = _gen;
        nft = _nft;
        
        bonuses[0] = 0;
        bonuses[1] = 2;
        bonuses[2] = 5;
        bonuses[3] = 9;
        bonuses[4] = 14;
        bonuses[5] = 20;
        bonuses[6] = 27;
        bonuses[7] = 35;
        bonuses[8] = 50;
        
        prices[0] = 0;
        prices[1] = 3;
        prices[2] = 5;
        prices[3] = 7;
        prices[4] = 10;
        prices[5] = 15;
        prices[6] = 20;
        prices[7] = 30;
        prices[8] = 40;
        
        winChances[0] = 0;
        winChances[1] = 50;
        winChances[2] = 35;
        winChances[3] = 25;
        winChances[4] = 16;
        winChances[5] = 10;
        winChances[6] = 5;
        winChances[7] = 3;
        winChances[8] = 2;
    }
    
    function start() public onlyOwner {
        require(startBlock == 0, "started already");   
        startBlock = block.number;
    }
    
    function evoIndex() public view returns (uint) {
        return (block.number - startBlock) / evoTime;
    }
    
    function blockForEvoClaim(uint index) public view returns (uint) {
        return startBlock + evoTime * (index + 1);
    }
    
    
    function joinEvolution(uint amount) public {
        uint nftId = userNFT[msg.sender];
        require(nftId != 0, "user should have NFT");   
        
        
        uint nftTypId = nft.getTypeByTokenId(nftId).id;
        require(nftTypId < higherBeing, "You are HIGHER BEING");   
        
        uint eIndex = evoIndex();
        require(evolutions[eIndex][msg.sender] + amount >= prices[nftTypId], "Less than minimum");   
        
        gen.transferFrom(msg.sender, address(this), amount * 1e18);
        evolutions[eIndex][msg.sender] += amount;
    }
    
    function claimLastEvolution() public {
        uint eIndex = evoIndex();
        require(eIndex > 0, "Evolution never happened");   
        claimEvolution(eIndex - 1);
    }
    
    function claimEvolution(uint eIndex) internal {
        // require(eIndex < evoIndex(), "Evolution haven't happened yet");   
        
        uint amount = evolutions[eIndex][msg.sender];
        require(amount > 0, "You didn't participate");
        
        uint nftId = userNFT[msg.sender];
        require(nftId != 0, "user should have NFT");   
        
        uint nftTypId = nft.getTypeByTokenId(nftId).id;
        require(nftTypId < higherBeing, "You are HIGHER BEING");   
        
        
        if (blockHashForEvo[eIndex] == 0) {
            blockHashForEvo[eIndex] = uint256(blockhash(blockForEvoClaim(eIndex))) % 100;
        } 
        
        uint user = uint(sha256((abi.encodePacked(msg.sender)))) % 100;
        uint blockHash = blockHashForEvo[eIndex];
        
        uint result = (blockHash + user) % 100 + 1;

        bool win = result <= (winChances[nftTypId] * amount / prices[nftTypId]);
        
        if (win) {
            gen.safeTransfer(msg.sender, 75 * 1e18 * prices[nftTypId] / winChances[nftTypId]);
            nft.changeType(nftId, nftTypId + 1);
        }
        
        evolutions[eIndex][msg.sender] = 0;
    }
    
    function depositNFT(uint _nftId) public {
        require(userNFT[msg.sender] == 0, "user already has NFT");
        
        nft.safeTransferFrom(address(msg.sender), address(this), _nftId);
        userNFT[msg.sender] = _nftId;
    }
    
    function withdrawNFT() public {
        uint nftId = userNFT[msg.sender];
        require(nftId != 0, "user already has NFT");
        
        uint nftTypId = nft.getTypeByTokenId(nftId).id;
        
        
        nft.safeTransferFrom(address(this), address(msg.sender), nftId);
        userNFT[msg.sender] = 0;
        
        uint eIndex = evoIndex();
        uint amount = evolutions[eIndex][msg.sender];
        if (amount > 0) {
            gen.safeTransfer(msg.sender, amount * 1e18);
            evolutions[eIndex][msg.sender] = 0;
        }
        
        if (eIndex > 0 && evolutions[eIndex - 1][msg.sender] > 0) {
            evolutions[eIndex - 1][msg.sender] = 0;
        }
    }
    
    function bonus(address user) public view returns (uint) {
        uint nftId = userNFT[user];
        if (nftId == 0) {
            return 0;
        }
        
        uint nftTypId = nft.getTypeByTokenId(nftId).id;
        return bonuses[nftTypId];
    }
    
    function emergencyWithdraw() public onlyOwner {
        uint amount = gen.balanceOf(address(this));
        gen.safeTransfer(msg.sender, amount);
    }
    
    function emergencyWithdrawAmount(uint amount) public onlyOwner {
        gen.safeTransfer(msg.sender, amount);
    }
    
    function updateBonus(uint nftTypeId, uint _bonus) public onlyOwner {
        bonuses[nftTypeId] = _bonus;
    }
    
    function updatePrice(uint nftTypeId, uint price) public onlyOwner {
        prices[nftTypeId] = price;
    }
    
    function updateEvoTime(uint _time) public onlyOwner {
        evoTime = _time;
    }
    
    function updateWinChance(uint nftTypeId, uint chance) public onlyOwner {
        winChances[nftTypeId] = chance;
    }
    
    function updateParams(uint _higherBeing) public onlyOwner {
        higherBeing = _higherBeing;
    }

    function getParams() public view returns(Param[] memory) {
        Param[] memory params = new Param[](higherBeing + 1);
        for (uint256 i = 0; i <= higherBeing; i++) {
            params[i] = Param(prices[i], bonuses[i], winChances[i]);
        }
        return params;
    }
}