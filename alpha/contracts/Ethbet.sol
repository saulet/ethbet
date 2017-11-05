pragma solidity ^0.4.11;


import './EthbetToken.sol';


//TODO: This works if we count on only one bet at a time for a user
contract Ethbet {
  using SafeMath for uint256;

  /*
  * Events
  */

  event Deposit(address indexed user, uint amount, uint balance);

  event Withdraw(address indexed user, uint amount, uint balance);

  event ExecutedBet(address indexed winner, address indexed loser, uint256 value);


  /*
   * Storage
   */
  address public creator;

  address public admin;

  address public relay;

  address public feeAddress;

  // the fee paid by the maker in EBET
  uint256 public makerFee;
  // the fee paid by the caller in EBET
  uint256 public callerFee;

  EthbetToken public token;

  mapping (address => uint256) balances;

  /*
  * Modifiers
  */

  modifier isAdmin() {
    require(msg.sender == admin);
    _;
  }

  modifier isRelay() {
    require(msg.sender == relay);
    _;
  }

  /*
  * Public functions
  */

  /// @dev Contract constructor
  function Ethbet(address _admin, address _relay, address tokenAddress, uint256 _makerFee, uint256 _callerFee) public {
    creator = msg.sender;
    admin = _admin;
    relay = _relay;
    makerFee = _makerFee;
    callerFee = _callerFee;
    token = EthbetToken(tokenAddress);
  }

  /**
   * @dev deposit EBET tokens into the contract
   * @param _amount Amount to deposit
   */
  function deposit(uint _amount) {
    require(_amount > 0);

    // token.approve needs to be called beforehand
    // transfer tokens from the user to the contract
    require(token.transferFrom(msg.sender, this, _amount));

    // add the tokens to the user's balance
    balances[msg.sender] = balances[msg.sender].add(_amount);

    Deposit(msg.sender, _amount, balances[msg.sender]);
  }

  //TODO: disable a withdraw while a bet is still in place
  /**
   * @dev withdraw EBET tokens from the contract
   * @param _amount Amount to withdraw
   */
  function withdraw(uint _amount) public {
    require(balances[msg.sender] >= _amount);

    // subtract the tokens from the user's balance
    balances[msg.sender] = balances[msg.sender].sub(_amount);

    // transfer tokens from the contract to the user
    require(token.transfer(msg.sender, _amount));

    Withdraw(msg.sender, _amount, balances[msg.sender]);
  }




  //Only the realy server will call this and choose a winer
  function executeBet(address _winner, address _loser, uint _amount) isRelay public {

    //The loser must have enough money to pay out the winner
    require(balances[_loser] >= _amount);

    //Add tokens to the winners account
    balances[_winner] += _amount;

    //Remove tokens from the losers account
    balances[_loser] -= _amount;

    //Log the event
    ExecutedBet(_winner, _loser, _amount);
  }

  function setAdmin(address _admin) isAdmin public {
    admin = _admin;
  }

  function setMakerFee(uint256 _makerFee) isAdmin public {
    makerFee = _makerFee;
  }

  function setCallerFee(uint256 _callerFee) isAdmin public {
    callerFee = _callerFee;
  }

  function setFeeAddress(address _feeAddress) isAdmin public {
    feeAddress = _feeAddress;
  }

  function balanceOf(address sender) constant public returns (uint256) {
    return balances[sender];
  }

}