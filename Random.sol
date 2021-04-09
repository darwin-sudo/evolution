// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;
library Random {

  struct Seed {
    uint blockNumber;
  }

  function isInitialized(Seed memory seed) internal pure returns (bool) {
    return seed.blockNumber > 0;
  }
  
  function isReady(Seed memory seed) internal view returns (bool) {
    return block.number > seed.blockNumber;
  }
    
  function init(Seed storage seed) internal {
    require(!isInitialized(seed), "Seed already initialized");
    seed.blockNumber = block.number;
  }
  
  function get(Seed storage seed) internal view returns (bytes32) {
    require(isInitialized(seed), "Seed is not initialized");
    require(block.number > seed.blockNumber, "Wait one more block to open this Seed");
    return blockhash(seed.blockNumber);
  }

  function reset(Seed storage seed) internal {
    seed.blockNumber = 0;
  }

}