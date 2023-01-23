// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "./DutchAuction.sol";


contract POCDutchAuction is DutchAuction {
    constructor(address _tokenAddress) DutchAuction(_tokenAddress, 7200) {
        // Duration 7,200 means 1 Day/86,400s(average 12s/block) in average.
    }
}