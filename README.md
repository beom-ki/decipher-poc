# decipher-poc
[Decipher](https://decipher.ac/) PoC(Proof of Contribution)

## Discussion Agenda
### English Auction
기능 
  - 주문 관련 함수 : bid, cancelBid, modifyBid (기능 추가 할 것 있나?)
  - 옥션 관련 함수 : createAuction, autoEndAuction, acceptAuction, cancelAuction
  
가장 어려웠던 점 : 주문 취소와 변경에 따른 오더북 관리.
  - **가장 큰 문제** : 최고가 주문을 넣었던 사람이 취소하면 두 번째 최고가와 그 주인을 어떻게 알아낼 것인가?
    - 현재는 for loop 돌아가며 다 찾고 있음.
  - 사소한 문제는 실제로 컨트랙트를 돌려본 게 아니다 보니 syntax 맞는지 모르겠다. (payable, delete Arr element)
  - Auction 관리는 어떻게 하는 게 나을까? (주문을 각각 넣으려면 index 있는 맵핑은 필수인데 이는 옥션이 끝났을 때 끝난 것을 관리하기가 번거롭다. 현재는 isValid 라는 attribute 로 하고 있는데 그게 최선인가?)
