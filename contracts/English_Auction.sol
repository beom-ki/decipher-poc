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

    struct Bid{
        address bidder;
        uint price;
    }

    event BidCreated(
        address bidder,
        uint price
    );

    mapping(uint => mapping(uint16 => Auction)) private auctions; // key : epoch
    mapping(uint => mapping(uint16 => Bid[])) private bids; // epoch => auction_index => array of Bid
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

    function checkAlreadyBid(address adr, uint16 index) public view returns (bool, uint) {
        Bid[] storage auction_bids = bids[epoch][index];
        for (uint i=0; i < auction_bids.length; i++){
            if(adr == auction_bids[i].bidder) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function bid(uint16 index) public payable returns (bool) {
        bool check;
        (check, ) = checkAlreadyBid(msg.sender, index);
        require(!check, "You already have previous bid, Please modify your order");

        Auction storage auction = auctions[epoch][index];
        Bid[] storage auction_bids = bids[epoch][index];

        auction_bids.push(Bid(msg.sender, msg.value));
        
        if (msg.value > auction.highestBid) {
            auction.highestBid = msg.value;
            auction.highestBidder = msg.sender;
        } 
        return true;
    }

    function cancelBid(uint16 index) public returns (bool) {
        bool check;
        uint idx;
        (check, idx) = checkAlreadyBid(msg.sender, index);
        require(check, "You haven't bidded before");

        Auction storage auction = auctions[epoch][index];
        Bid[] storage auction_bids = bids[epoch][index];

        delete auction_bids[idx];
        if (auction_bids[idx].price == auction.highestBid) {
            // need to update highestBid (hardest part)
            uint secondHighestBid = 0;
            address secondHighestBidder = address(this);
            
            for (uint i=0; i < auction_bids.length; i++) {
                if (secondHighestBid < auction_bids[i].price) {
                    secondHighestBid = auction_bids[i].price;
                    secondHighestBidder = auction_bids[i].bidder;
                }
            }
        } 
        return true;
    }

    function modifyBid(uint16 index) public payable returns (bool) {
        bool check;
        uint idx;
        (check, idx) = checkAlreadyBid(msg.sender, index);
        require(check, "Please use new bid");

        cancelBid(index);
        bid(index);

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
