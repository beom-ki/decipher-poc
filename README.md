# decipher-poc
[Decipher](https://decipher.ac/) PoC(Proof of Contribution)

## Discussion Agenda
### English Auction
가장 어려웠던 점 : 주문 취소와 변경에 따른 오더북 관리.
  - 주문 관련 함수 : bid, cancelBid
    - 현재 modifyBid 함수 기능이 bid 안에 합쳐져 있다. (의식의 흐름에 따라 짜서 생략해버림. 추가 안 할 이유가 없는 것 같다.)
    - modifyBid 가 있더라도 cancelBid 와 그냥 bid 의 혼합된 함수 형태일 것이다.
  - **가장 큰 문제** : 최고가 주문을 넣었던 사람이 취소하면 두 번째 최고가와 그 주인을 어떻게 알아낼 것인가?
    - 이 문제를 해결하려고 별의 별 mapping 을 다 만들었다. (https://github.com/beom-ki/decipher-poc/blob/13f52c88f23ce196957fc8fcb80f7beb907f73d0/contracts/English_Auction.sol#L33-L36)
    - 그리고 이 맵핑이 성립되기 위해 약간 넌센스한 제약들도 어쩔 수 없이 들어갔다. (한 사람 당 주문 1개만 가능, 사람들끼리 주문 금액 같으면 안됨.)
   
