pragma solidity ^0.4.23;

contract Recovery {

  //generate tokens
  function generateToken(string _name, uint256 _initialSupply) public {
    new SimpleToken(_name, msg.sender, _initialSupply);
  
  }
}

contract SimpleToken {

  // public variables
  string public name;
  mapping (address => uint) public balances;

  // constructor
  constructor(string _name, address _creator, uint256 _initialSupply) public {
    name = _name;
    balances[_creator] = _initialSupply;
  }

  // collect ether in return for tokens
  function() public payable {
    balances[msg.sender] = msg.value*10;
  }

  // allow transfers of tokens
  function transfer(address _to, uint _amount) public { 
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] -= _amount;
    balances[_to] = _amount;
  }

  // clean up after ourselves
  function destroy(address _to) public {
    selfdestruct(_to);
  }
}