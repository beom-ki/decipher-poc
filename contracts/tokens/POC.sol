// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "./extensions/ERC20Epochs.sol";

import "@openzeppelin/contracts/access/Ownable.sol";


contract POC is ERC20Epochs, Ownable {
    constructor() ERC20Epochs("Decipher POC", "POC") {
    }

    mapping(address => bool) public _whiteLists;

    modifier transferAvailable {
        require(owner() == msg.sender || _whiteLists[msg.sender]);
        _;
    }

    function isWhiteListed(address adrs) public view returns (bool) {
        return _whiteLists[adrs];
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function transfer(address to, uint256 amount) override public onlyOwner returns (bool){
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) override public transferAvailable returns (bool){
        return super.transferFrom(from, to, amount);
    }

    function createEpoch() override public onlyOwner returns (uint256) {
        return super.createEpoch();
    }

    function addWhiteLists(address approved) public onlyOwner {
        _whiteLists[approved] = true;
    }

    // Examples for POC(Proof of Contribution) specific logics.
    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
