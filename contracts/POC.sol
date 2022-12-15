// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "./extensions/ERC20Epochs.sol";
import "./Dutch_Auction.sol";

contract POC is ERC20Epochs {
    constructor() ERC20Epochs("POC", "POC") {
    }
    DutchAuction dutch;

    // Examples for POC(Proof of Contribution) specific logics.
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    // Restrict transfer
    address[] private tokenLeadMembers = [0x48B523E7910298a0D9FC1eE0fA06A639e58b4eCF];
    
    function isLeadMembers(address adrs) public view returns (bool) {
        for (uint i = 0; i < tokenLeadMembers.length; i++) {
            if (tokenLeadMembers[i] == adrs) {
                return true;
            }
        }
        return false;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        // only can send to Auction contract or Lead member can send POC once someone fulfills the condition.
        require(to == 0xd9145CCE52D386f254917e481eB44e9943F39138 || isLeadMembers(msg.sender)); 
        address owner = msg.sender;
        _transfer(owner, to, amount);
        if (to == 0xd9145CCE52D386f254917e481eB44e9943F39138) {
            // 어차피 현재 epoch 상태의 토큰들만 이동 가능한 거인듯
            dutch.setTokenVault(owner, amount);
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(isLeadMembers(msg.sender)); // only lead members can execute others token
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
}