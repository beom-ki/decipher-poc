// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "./extensions/ERC20Epochs.sol";

import "@openzeppelin/contracts/access/Ownable.sol";


contract POC is ERC20Epochs, Ownable {
    constructor() ERC20Epochs("Decipher POC", "POC") {
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function createEpoch() override public onlyOwner returns (uint256) {
        return super.createEpoch();
    }

    // Examples for POC(Proof of Contribution) specific logics.
    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
