pragma solidity ^0.4.16;

/* interface: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md */
interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);

  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }

  /**
   * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Lockable is Ownable {
    uint256 public creationTime;
    bool public tokenTransferLocker;
    mapping(address => bool) lockaddress;

    event Locked(address lockaddress);
    event Unlocked(address lockaddress);
    event TokenTransferLocker(bool _setto);

    // if Token transfer
    modifier isTokenTransfer {
        // only contract holder can send token during locked period
        if(msg.sender != owner) {
        // if token transfer is not allow
            require(!tokenTransferLocker);
            if(lockaddress[msg.sender]){
                revert();
            }
        }
        _;
    }

  // This modifier check whether the contract should be in a locked
  // or unlocked state, then acts and updates accordingly if
  // necessary
    modifier checkLock {
        if (lockaddress[msg.sender]) {
            revert();
        }
        _;
    }

    constructor() public {
        creationTime = now;
        owner = msg.sender;
    }

    function isTokenTransferLocked() external view
    returns (bool)
    {
        return tokenTransferLocker;
    }

    function enableTokenTransfer() external onlyOwner
    {
        delete tokenTransferLocker;
        emit TokenTransferLocker(false);
    }

    function disableTokenTransfer() external onlyOwner
    {
        tokenTransferLocker = true;
        emit TokenTransferLocker(true);
    }
}

contract PaoToken is ERC20, Lockable {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_ = 10000000000 * 1000000000000000000;
    string public name = "PA0Token";
    uint8 public decimals = 18;
    string public symbol = "PA0";

    uint256 public sellPrice;
    uint256 public buyPrice;

    // constructor
    constructor() public {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return balances[_addr];
    }

    function allowance(address _from, address _spender) external view returns (uint256) {
        return allowed[_from][_spender];
    }

    function transfer(address _to, uint256 _value)  isTokenTransfer external
    returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)  isTokenTransfer  public
    returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value)  isTokenTransfer external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = msg.value / buyPrice;               // calculates the amount
        transferFrom(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        transferFrom(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }

}