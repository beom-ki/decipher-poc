// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./POC.sol";

contract EnglishAuction {
    POC token;
    uint16 auctionIndex = 0;
    uint epoch = token.epoch();
    address[] private auctionLeadMembers = [0x48B523E7910298a0D9FC1eE0fA06A639e58b4eCF];

    struct Auction {
        address seller;
        uint16 value;
        uint highestBid;
        address highestBidder;
        uint durationBlockNumber;
        uint createdBlockNumber;
        bool isValid;
    }

    event AuctionCreated(
        address seller,
        uint16 value,
        uint durationBlockNumber
    );

    event BidCreated(
        address bidder,
        uint price
    );

    mapping(uint => mapping(uint16 => Auction)) private auctions; // key : epoch
    mapping(uint => mapping(uint16 => mapping(address => uint))) private bids; // epoch => auction_index => address => bidPrice
    mapping(uint => mapping(uint16 => mapping(uint => address))) private reverse_bids;
    mapping(uint => mapping(uint16 => uint[])) private bids_arr;
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


    function createAuction(uint16 value, address auctionOwner, uint durationBlockNumber) public returns (bool) {
        require(isLeadMembers(msg.sender));
        require(value <= tokenVault[epoch][auctionOwner]);
        require(durationBlockNumber >= 50);
        require(durationBlockNumber <= 500);

        auctions[epoch][auctionIndex] = Auction(auctionOwner, value, 0, address(this), durationBlockNumber, block.number, true);
        tokenVault[epoch][auctionOwner] -= value;
        auctionIndex += 1;
        emit AuctionCreated(auctionOwner, value, durationBlockNumber);
        return true;
    }
    
    function bid(uint16 index) public payable returns (bool) {
        Auction storage auction = auctions[epoch][index];
        mapping(address => uint) storage auction_bids = bids[epoch][index];
        uint[] storage auction_bids_arr = bids_arr[epoch][index];
        for (uint i=0; i<auction_bids_arr.length; i++){
            require(msg.value != auction_bids_arr[i], "Bid at same price already exists");
        }
        uint prev_bid = auction_bids[msg.sender];
        auction_bids[msg.sender] = msg.value;
        
        reverse_bids[epoch][index][msg.value] = msg.sender;
        if (prev_bid == 0){
            // first bid
            auction_bids_arr.push(msg.value);
        } else {
            // change pre-existed bid
            delete reverse_bids[epoch][index][prev_bid];
            for (uint i=0; i<auction_bids_arr.length; i++){
                if (auction_bids_arr[i] == prev_bid) {
                    auction_bids_arr[i] = msg.value;
                    break;
                }
            }
        }
        
        if (msg.value > auction.highestBid) {
            auction.highestBid = msg.value;
            auction.highestBidder = msg.sender;
        } 
        return true;
    }

    function cancelBid(uint16 index) public returns (bool) {
        Auction storage auction = auctions[epoch][index];
        mapping(address => uint) storage auction_bids = bids[epoch][index];
        uint[] storage auction_bids_arr = bids_arr[epoch][index];
        require(auction_bids[msg.sender] > 0);

        mapping(uint => address) storage auction_reverse_bids = reverse_bids[epoch][index];
        uint delete_idx;

        if (auction_bids[msg.sender] == auction.highestBid) {
            // need to update highestBid (hardest part)
            uint secondHighestBid = 0;
            address secondHighestBidder = address(this);
            
            for (uint i=0; i < auction_bids_arr.length; i++) {
                if (auction_bids_arr[i] == auction.highestBid) {
                    delete_idx = i;
                    delete auction_reverse_bids[auction.highestBid];
                    continue;
                }
                if (secondHighestBid < auction_bids_arr[i]) {
                    secondHighestBid = auction_bids_arr[i];
                    secondHighestBidder = auction_reverse_bids[auction_bids_arr[i]];
                }
            }

            delete auction_bids_arr[delete_idx]; // maybe should delete outside of loop to prevent from length changing
            delete auction_bids[msg.sender];
        } else {
            // only need to delete data
            delete auction_reverse_bids[auction_bids[msg.sender]];
            for (uint i=0; i < auction_bids_arr.length; i++) {
                if (auction_bids_arr[i] == auction_bids[msg.sender]) {
                    delete auction_bids_arr[i];
                    delete auction_bids[msg.sender];
                    break;
                }
            }
        }

        return true;
    }

    // cannot capture exact ending time (can improve it?)
    function autoEndAuction() private returns (bool) {
        for (uint16 i=0; i<auctionIndex; i++) {
            Auction storage auction = auctions[epoch][i];
            if (auction.isValid) {
                if (block.number - auction.createdBlockNumber > auction.durationBlockNumber) {
                    auction.isValid = false; // 여기도 나중에 delete 로 바꾸기?
                    if (auction.highestBid == 0) {
                        tokenVault[epoch][auction.seller] -= auction.value;
                        token.transfer(auction.seller, auction.value);
                    } else {
                        tokenVault[epoch][auction.seller] -= auction.value;
                        token.transfer(auction.highestBidder, auction.value);
                        payable(auction.seller).transfer(auction.highestBid); // syntax right?
                    }
                }
            }
        }
        return true;
    }

    function acceptAuction(uint16 index) public returns (bool) {
        // End auction before time end
        Auction storage auction = auctions[epoch][index];
        require(msg.sender == auction.seller);
        require(auction.isValid);
        require(auction.highestBid > 0); // if highestBid == 0, should use cancleAuction

        auction.isValid = false;
        payable(auction.seller).transfer(auction.highestBid);
        tokenVault[epoch][auction.seller] -= auction.value;
        token.transfer(auction.highestBidder, auction.value);

        return true;
    }

    function cancelAuction(uint16 index) public returns (bool) {
        Auction storage auction = auctions[epoch][index];
        require(isLeadMembers(msg.sender) || msg.sender == auction.seller);
        require(auction.highestBid == 0); // if someone already bid, cannot cancel
        auction.isValid = false;
        tokenVault[epoch][auction.seller] -= auction.value;
        token.transfer(auction.seller, auction.value);
        return true;
    }
}