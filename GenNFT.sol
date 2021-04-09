// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "../oz/utils/structs/EnumerableSet.sol";
import "../oz/access/Ownable.sol";
import "../oz/token/ERC721/extensions/ERC721Enumerable.sol";

contract GenNFT is ERC721Enumerable, Ownable  {
    
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;
    
       //Trusted
    mapping(address=>bool) private _isTrusted;
    modifier onlyTrusted {
        require(_isTrusted[msg.sender] || msg.sender == owner(), "not trusted");
        _;
    }
    
    function addTrusted(address user) public onlyOwner {
        _isTrusted[user] = true;
    }
    
    function removeTrusted(address user) public onlyOwner {
        _isTrusted[user] = false;
    }
    
    struct Type {
        uint id;
        uint bonus;
        uint rarity;
    }
    
    constructor() ERC721("Gen NFT","GenNFT") {} 
    
    // Token.Type data
    EnumerableSet.UintSet typeIds;
    
    mapping (uint=>Type) typesById;
    mapping (uint=>EnumerableSet.UintSet) private typeIdsByRarity;
    mapping (uint=>uint) private mintIndexByTokenId;
    
    uint nextTokenId = 0;
    mapping (uint=>uint) private typeIdByTokenId;
    
    function createToken(address holder, uint typeId) public onlyTrusted returns (uint tokenId) {
        tokenId = ++nextTokenId;
        typeIdByTokenId[tokenId] = typeId;
        _mint(holder, tokenId);
    }
    
    function createRandomNFT(address holder, uint rarity, uint seed) public onlyTrusted returns (uint) {
        EnumerableSet.UintSet storage filter = typeIdsByRarity[rarity];
        require(filter.length() > 0, "there are no types with that rarity");
        uint typeId = filter.at(seed % filter.length());
        return createToken(holder, typeId);
    }
    
    function changeType(uint tokenId, uint toTypeId) public onlyTrusted {
        typeIdByTokenId[tokenId] = toTypeId;
    }
    
    function addType(uint id, uint bonus, uint rarity) public onlyOwner {
        require(!typeIds.contains(id), "id already exists");
        typeIds.add(id);
        typesById[id] = Type(id, bonus, rarity);
        typeIdsByRarity[rarity].add(id);
    }
    
    function removeType(uint id) public onlyOwner {
        require(typeIds.contains(id), "id does not exist");
        typeIds.remove(id);
        typeIdsByRarity[typesById[id].rarity].remove(id);
    }
    
    function replaceType(uint id, uint bonus, uint rarity) public onlyOwner {
        removeType(id);
        addType(id, bonus, rarity);
    }
    
    function getTypeById(uint id) public view returns (Type memory) { return typesById[id]; }
    
    function getTypeByTokenId(uint id) public view returns (Type memory) { return typesById[typeIdByTokenId[id]]; }
    
    function getTypeCount() public view returns (uint) {
        return typeIds.length();
    }
    
    function getTypeIdAtIndex(uint index) public view returns (uint) {
        return typeIds.at(index);
    }
    
    function getTypeAtIndex(uint index) public view returns (Type memory tokenType) {
        tokenType = typesById[typeIds.at(index)];
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://nft.bscrunner.com/";
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = ERC721.tokenURI(tokenId);
        Type memory tokenType = getTypeByTokenId(tokenId);
        return string(abi.encodePacked(
            baseURI, "/",
            tokenId.toString(), "/",
            tokenType.bonus.toString(), "/",
            tokenType.rarity.toString()));
    }
}