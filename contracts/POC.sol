// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "./extensions/ERC20Epochs.sol";

contract POC is ERC20Epochs {
    constructor() ERC20Epochs("POC", "POC") {}

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
        // only Lead member can send POC once someone fulfills the condition.
        require(isLeadMembers(msg.sender)); 
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
}