// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "../tokens/extensions/ERC20Epochs.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DutchAuction {
    using SafeMath for uint;
    using Counters for Counters.Counter;
    uint public startPrice = 1e18; // 1eth
    uint public minimumPrice = 1e16; // 0.01eth

    
    struct Auction {
        uint index;
        address token;
        address seller;
        uint quantity;
        uint currentPrice;
        uint createdBlockNumber;
        bool isSold;
    }

    // 시작 가격과 최소 가격 지금은 항상 고정. 수요에 따라 바꿀 수 있게 자동으로 식 구성해도 되겠다.
    // 수명은 항상 총 24시간 -> block number 로 바꾸면 대강 (1분에 5블록) = 7200블록
    event AuctionCreated(
        uint id,
        address token,
        address seller,
        uint quantity,
        uint createdBlockNumber
    );

    event AuctionSold(
        uint id,
        address token,
        address seller,
        address buyer,
        uint quantity,
        uint price,
        uint duration
    );

    event AuctionTimeOut(
        uint id,
        address seller
    );

    event AuctionCancelled(
        uint id,
        address seller
    );

    Counters.Counter private _id;
    Auction[] private _auctions; 
    
    function auctionLength() public view returns(uint256) {
        return _auctions.length;
    }

    function getAuction(uint index) public view returns(Auction memory) {
        require(index < _auctions.length, "Indexing error");
        return _auctions[index];
    }

    function getAuction() public view returns(Auction memory) {
        require(_id.current() > 0, "No auction has been created");
        return _auctions[_id.current() - 1];
    }


    // POC 개인이 임의로 옥션 생성할 수 있고, 동시에 여러 옥션이 진행되지 못 하게 기획이 정해졌다.
    // 동시에 여러 옥션이 진행되지 못하므로, vault 도 이제 필요 없을 것 같다.
    function createAuction(address token, uint quantity) public returns (bool) {
        bool isSold = true;
        uint currentId = _id.current();
        if (currentId > 0) {
            isSold = _auctions[currentId - 1].isSold;
            startPrice += _auctions[currentId - 1].currentPrice * 3; // 저번 팔린 가격 참고해서 startPrice 증가.
        }
        require(isSold, "There is another pending auction.");
        require(ERC20Epochs(token).balanceOf(msg.sender) > 10, "You don't have enough POC for creating auction.");
        require(quantity <= ERC20Epochs(token).balanceOf(msg.sender) - 10, "You tried to create auction with too many quantity.");

        Auction memory new_auction = Auction(currentId, token, msg.sender, quantity, startPrice, block.number, false);
        _auctions.push(new_auction);
        emit AuctionCreated(currentId, token, msg.sender, quantity, block.number);
        _id.increment();
        return true;
    }
    
    // for updating front-end page 
    function updateAuction() public returns (bool) {
        uint currentId = _id.current();
        require(currentId > 0, "No auction has created.");
        require(!_auctions[currentId - 1].isSold, "No auction has been pending.");
        Auction storage auction = _auctions[currentId - 1]; // 값 업데이트 하려면 storage 써야 한다.

        if (block.number - auction.createdBlockNumber > 7200) {
            auction.isSold = true; // time-out
            auction.currentPrice = 0;
            emit AuctionTimeOut(currentId, auction.seller);
        } else {
            uint newPrice = startPrice - SafeMath.div((startPrice - minimumPrice) * (block.number - auction.createdBlockNumber), 7200);
            auction.currentPrice  = newPrice;
        }
        return true;
    }

    function takeAuction(address token) public payable returns (bool) {
        // accept the current price.
        updateAuction(); // 혹시 모르니까 사기 전에 업데이트 한 번 더
        uint currentId = _id.current();
        Auction storage auction = _auctions[currentId - 1];
        uint totalPrice = auction.currentPrice * auction.quantity;
        require(!auction.isSold, "There is no valid auction.");    
        require(msg.sender != auction.seller, "You cannot buy your own auction.");    
        require(msg.value >= totalPrice); // check ETH balance
        require(ERC20Epochs(token).balanceOf(msg.sender) >= 7, "You can buy POC only if you have more than 7 POC.");

        // Maker gets {price} amount of Ethers from Taker.(Ethers: Taker → Maker)
        payable(auction.seller).transfer(totalPrice);
        // approve 를 auction contract 에만 해줘야 한다.
        ERC20Epochs(token).transferFrom(
            auction.seller,
            msg.sender,
            auction.quantity
        );
        auction.isSold = true;
        emit AuctionSold(
            currentId, 
            token,
            auction.seller, 
            msg.sender, 
            auction.quantity, 
            auction.currentPrice, 
            block.number - auction.createdBlockNumber);
            
        // msg.value 가 가격보다 크면 남은 것 돌려주기
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        return true;
    }

    function cancelAuction() public returns (bool) {
        uint currentId = _id.current();
        require(currentId > 0, "No auction has created.");
        require(!_auctions[currentId - 1].isSold, "No auction has been pending.");
        
        Auction storage auction = _auctions[currentId - 1];
        auction.isSold = true;
        auction.currentPrice = 0;
        emit AuctionCancelled(currentId, auction.seller);
        return true;
    }
}
