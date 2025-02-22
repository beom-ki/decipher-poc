// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract DutchAuction {
    using Counters for Counters.Counter;

    event AuctionCreated(
        uint indexed id,
        address indexed seller,
        uint quantity,
        uint initialPrice
    );

    event AuctionEnded(
        uint indexed id,
        address indexed seller,
        uint quantity,
        uint initialPrice,
        address indexed buyer,
        uint price
    );

    enum Status {
        Created,
        Ended
    }

    struct AuctionInformation {
        // Auction Initialize Information
        uint id;
        Status status;
        address seller;
        uint quantity;
        uint256 createdAt;
        uint256 initialPrice;

        // Auction Result Information
        address buyer;
        uint256 price;
        uint256 updatedAt;
    }

    Counters.Counter private _id;
    IERC20 public token;
    AuctionInformation[] public _auctions;
    uint256 public duration;

    constructor(address _tokenAddress, uint _duration) {
        token = IERC20(_tokenAddress);
        duration = _duration; 
    }

    function getAuction(uint id) public virtual view returns (AuctionInformation memory) {
        return _auctions[id];
    }

    function getAuction() public virtual view returns (AuctionInformation memory) {
        // Returns current(last) auction.
        return _auctions[_id.current() - 1];
    }

    function createAuction(uint quantity, uint initialPrice) public virtual returns (AuctionInformation memory) {
        address seller = msg.sender;
        return _createAuction(seller, quantity, initialPrice);
    }

    function getPrice() public virtual view returns (uint256) {
        return _getPrice();
    }

    function takeAuction() public virtual payable returns (bool) {
        return _takeAuction(msg.sender, msg.value);
    }

    function _createAuction(address seller, uint quantity, uint initialPrice) internal virtual returns (AuctionInformation memory) {
        require(
            _id.current() == 0 || _auctions[_id.current() - 1].status == Status.Ended,
            "Auction: Auction creation is only available one at a time."
        );
        AuctionInformation memory auction = AuctionInformation(
            _id.current(),
            Status.Created,
            seller,
            quantity,
            block.number,
            initialPrice,
            address(0),
            0,
            block.number
        );
        _auctions.push(auction);

        emit AuctionCreated(
            _id.current(),
            msg.sender,
            quantity,
            initialPrice
        );

        _id.increment();

        return auction;
    }

    function _getPrice() internal virtual view returns (uint256) {
        // The pricing model may be implemented differently depending on the situation.
        // Default to "linear-decreasing" dutch auction.

        AuctionInformation memory currentAuction = getAuction();
        uint256 currentPrice = currentAuction.initialPrice * (duration - (block.number - currentAuction.createdAt))/duration;
        return currentPrice;
    }

    function _takeAuction(address buyer, uint max_eth_sold) internal virtual returns (bool) {
        AuctionInformation storage currentAuction = _auctions[_id.current() - 1];
        uint256 currentPrice = getPrice();

        require(currentAuction.status != Status.Ended);
        require(max_eth_sold >= currentPrice);

        currentAuction.price = currentPrice;
        currentAuction.status = Status.Ended;
        currentAuction.buyer = buyer;
        currentAuction.updatedAt = block.number;

        token.transferFrom(currentAuction.seller, buyer, currentAuction.quantity);

        payable(currentAuction.seller).transfer(currentPrice);
        if (max_eth_sold > currentPrice) {
            payable(msg.sender).transfer(max_eth_sold - currentPrice);
        }

        emit AuctionEnded(
            currentAuction.id,
            currentAuction.seller,
            currentAuction.quantity,
            currentAuction.initialPrice,
            buyer,
            currentPrice
        );

        return true;
    }
}