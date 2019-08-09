// Implement the smart contract SupplyChain following the provided instructions.
// Look at the tests in SupplyChain.test.js and run 'truffle test' to be sure that your contract is working properly.
// Only this file (SupplyChain.sol) should be modified, otherwise your assignment submission may be disqualified.

pragma solidity ^0.5.0;

contract SupplyChain {

  uint PAY_FEE = 1 finney;
  address payable owner = msg.sender;

  // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
  uint itemIdCount;

  // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
  enum State { ForSale, Sold, Shipped, Received }

  // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'.
  struct Item {
    string name;
    uint price;
    State state;
    address payable seller;
    address buyer;
  }

  // Create a variable named 'items' to map itemIds to Items.
  mapping(uint => Item) items;

  // Create an event to log all state changes for each item.
  event SupplyChainEvent(
    uint itemId,
    string name,
    uint price,
    State state,
    address payable seller,
    address buyer
  );


  // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can proceed with the execution.");
    _;
  }

  // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
  modifier checkState(uint _itemId, State _state) {
    require(items[_itemId].state == _state, "Given item state is in unsatisfied state.");
    _;
  }

  // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
  modifier checkCaller(address _caller) {
    require(msg.sender == _caller, "Only the buyer can proceed receiving process, and only the seller can proceed the shipping process");
    _;
  }

  // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.
  modifier checkValue(uint _value) {
    require(msg.value >= _value, "The caller did not send enough Ether to pay for a specific Item or fee");
    _;
  }


  // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
  function addItem(string memory _name, uint _price) public payable checkValue(PAY_FEE) returns(uint){
    itemIdCount++;
    uint itemId = itemIdCount;
    uint balance = 0;

    items[itemId].name = _name;
    items[itemId].price = _price;
    items[itemId].state = State.ForSale;
    items[itemId].seller = msg.sender;

    balance = msg.value - PAY_FEE;

    if (balance > 0) {
      msg.sender.transfer(balance);
    }

    emit SupplyChainEvent(
      itemId,
      items[itemId].name,
      items[itemId].price,
      items[itemId].state,
      items[itemId].seller,
      items[itemId].buyer
    );

    return itemId;
  }

  // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
  function buyItem(uint _itemId) public payable checkState(_itemId, State.ForSale) checkValue(items[_itemId].price){
    uint balance = msg.value - items[_itemId].price;

    items[_itemId].state = State.Sold;
    items[_itemId].buyer = msg.sender;
    items[_itemId].seller.transfer(items[_itemId].price);

    if (balance > 0) {
      msg.sender.transfer(balance);
    }

    emit SupplyChainEvent(
      _itemId,
      items[_itemId].name,
      items[_itemId].price,
      items[_itemId].state,
      items[_itemId].seller,
      items[_itemId].buyer
    );
  }

  // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
  function shipItem(uint _itemId) public checkCaller(items[_itemId].seller) {
    items[_itemId].state = State.Shipped;

    emit SupplyChainEvent(
      _itemId,
      items[_itemId].name,
      items[_itemId].price,
      items[_itemId].state,
      items[_itemId].seller,
      items[_itemId].buyer
    );
  }

  // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
  function receiveItem(uint _itemId) public checkCaller(items[_itemId].buyer) {
    items[_itemId].state = State.Received;

    emit SupplyChainEvent(
      _itemId,
      items[_itemId].name,
      items[_itemId].price,
      items[_itemId].state,
      items[_itemId].seller,
      items[_itemId].buyer
    );
  }

  // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item.
  function getItem(uint _itemId) public view returns (string memory, uint, State, address, address) {
    string memory name = items[_itemId].name;
    uint price = items[_itemId].price;
    State state = items[_itemId].state;
    address seller = items[_itemId].seller;
    address buyer = items[_itemId].buyer;

    return (name, price, state, seller, buyer);
  }

  // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
  function withdrawFunds() public onlyOwner() {
    owner.transfer(address(this).balance);
  }
}
