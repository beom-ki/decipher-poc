// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "./extensions/ERC20Epochs.sol";

contract POC is ERC20Epochs {
    constructor() ERC20Epochs("POC", "POC") {
        _mint(msg.sender, 100);
    }

    // Examples for POC(Proof of Contribution) specific logics.
    function decimals() public pure override returns (uint8) {
        return 0;
    }
}