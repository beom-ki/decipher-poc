// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./POC.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DutchAuction {
    using SafeMath for uint;
    POC token;
    uint16 auctionIndex = 0;
    uint epoch = token.epoch();
    address[] private auctionLeadMembers = [0x48B523E7910298a0D9FC1eE0fA06A639e58b4eCF];

    struct Auction {
        address seller;
        uint16 value;
        uint startPrice;
        uint currentPrice;
        uint updatePrice;
        uint createdBlockNumber;
        bool isValid;
    }

    event AuctionCreated(
        address seller,
        uint16 value,
        uint startPrice,
        uint updatePrice,
        uint createdBlockNumber
    );

    mapping(uint => mapping(uint16 => Auction)) private auctions; // key : epoch
    mapping (uint => mapping(address => uint)) private tokenVault;

    function isLeadMembers(address adrs) public view returns (bool) {
        for (uint i = 0; i < auctionLeadMembers.length; i++) {
            if (auctionLeadMembers[i] == adrs) {
                return true;
            }
        }
        return false;
    }

    function getTokenVault(address _address) public view returns (uint) {
        return tokenVault[epoch][_address];
    }

    function setTokenVault(address _address, uint value) public returns (bool) {
        token.transferFrom(_address, address(this), value);
        tokenVault[epoch][_address] += value;
        return true;
    }


    function createAuction(uint16 value, address auctionOwner, uint startPrice, uint updatePrice) public returns (bool) {
        require(isLeadMembers(msg.sender));
        require(value <= tokenVault[epoch][auctionOwner]);
        require(startPrice * 1 ether >= 1 ether);
        require(updatePrice * 100 <= startPrice);

        auctions[epoch][auctionIndex] = Auction(auctionOwner, value, startPrice, startPrice, updatePrice, block.number, true);
        tokenVault[epoch][auctionOwner] -= value;
        auctionIndex += 1;
        emit AuctionCreated(auctionOwner, value, startPrice, updatePrice, block.number);
        return true;
    }
    
    // for updating front-end page 
    function updateAuction() private returns (bool) {
        for (uint16 i=0; i<auctionIndex; i++) {
            Auction storage auction = auctions[epoch][i];
            if (auction.isValid) {
                if (block.number - auction.createdBlockNumber > 500) {
                    auction.isValid = false;
                }
                else {
                    uint newPrice = auction.currentPrice - SafeMath.div(block.number - auction.createdBlockNumber, 50) * auction.updatePrice; 
                    auction.currentPrice = newPrice;
                }
            }
        }
        return true;
    }

    function takeAuction(uint16 index) public payable returns (bool) {
        // confirm the taking price.
        Auction storage auction = auctions[epoch][index];
        uint newPrice = auction.currentPrice - SafeMath.div(block.number - auction.createdBlockNumber, 50) * auction.updatePrice; 
        auction.currentPrice = newPrice;

        require(auction.isValid);
        require(msg.value >= auction.currentPrice); // check ETH balance
        require(token.balanceOf(msg.sender) >= 7);

        auction.isValid = false;
        payable(auction.seller).transfer(auction.currentPrice);
        // eth 보내줘야 함.
        tokenVault[epoch][auction.seller] -= auction.value;
        token.transfer(msg.sender, auction.value);

        return true;
    }

    function cancelAuction(uint16 index) public returns (bool) {
        require(isLeadMembers(msg.sender));
        Auction storage auction = auctions[epoch][index];
        auction.isValid = false;
        return true;
    }
}