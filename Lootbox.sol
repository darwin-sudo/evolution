// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "../oz/utils/structs/EnumerableSet.sol";
import "../oz/access/Ownable.sol";
import "./GenNFT.sol";
import "./Random.sol";
import "../oz/token/ERC20/ERC20.sol";
import "../oz/token/ERC20/IERC20.sol";
import "../oz/token/ERC20/utils/SafeERC20.sol";

contract Lootbox is Ownable {
    
    using Random for Random.Seed;
    using SafeERC20 for IERC20;
    
    struct Config {
        uint packPrice;
        uint maxPacksPerPurchase;
    }
    
    struct Purchase {
        uint numPacks;
        Random.Seed seed;
        uint[] nftIds;
    }
    
    event RewardRedeemed(address buyer);
    event Purchased(address buyer, uint numPacks);

    IERC20 public gen;
    GenNFT public nft;
    address private dead;
    uint[] public chances;
 
    mapping(address=>Purchase) public purchases;
    
    Config config = Config(2, 50);
    
    constructor(IERC20 _gen, GenNFT _nft) {
        gen = _gen;
        nft = _nft;
        dead = 0x000000000000000000000000000000000000dEaD;
        
        chances = [6700, 8700, 9500, 9900, 9990, 9999];
    }

    function buy(uint numPacks) public {
        Purchase storage purchase = purchases[msg.sender];
        require(numPacks > 0, "numPacks should be more than 0");
        require(purchase.numPacks == 0, "open packs before making another purchase");
        require(numPacks <= config.maxPacksPerPurchase, "exceeded maximum packs per purchase");
        
        uint price = numPacks * config.packPrice * 1e18;
        
        gen.transferFrom(msg.sender, dead, price);
        
        purchases[msg.sender].numPacks = numPacks;
        purchases[msg.sender].seed = Random.Seed(block.number);
        
        emit Purchased(msg.sender, numPacks);
    }
    
    function redeem() public {
        Purchase storage purchase = purchases[msg.sender];
        
        require(purchase.numPacks > 0, "purchase packs first");
        require(purchase.seed.isReady(), "purchase packs first");
    
        bytes32 seed = purchase.seed.get();
        uint nftSeedIterator = uint(seed) % 100000000000000000000;
        for(uint i = 0; i < purchase.numPacks; ++i) {
            uint luckyNumber = nftSeedIterator % 10000;
            uint nftTypeId = 1;
            for (uint j = 0; j < chances.length; ++j)
            if (chances[j] <= luckyNumber) {
                nftTypeId = j + 2;
            }
             
            uint tokenId = nft.createToken(msg.sender, nftTypeId);
                
            purchase.nftIds.push(tokenId);
            
            nftSeedIterator = nftSeedIterator / 10000;
            if (nftSeedIterator < 10000) {
                seed = rehash(seed);
                nftSeedIterator = uint(seed) % 100000000000000000000;    
            }
        }
        
        purchase.numPacks = 0;
        
        emit RewardRedeemed(msg.sender);
    }
    
    function rehash(bytes32 b32) internal pure returns (bytes32) {
      return sha256(abi.encodePacked(b32));
    }
    
    //Configuration
    
    function setConfig(Config memory _config) public onlyOwner {
        config = _config;
    }
    
    function getConfig() external view returns (Config memory) {
        return config;
    }
    
    function setChances(uint[] memory _chances) public onlyOwner {
        chances = _chances;
    }
}