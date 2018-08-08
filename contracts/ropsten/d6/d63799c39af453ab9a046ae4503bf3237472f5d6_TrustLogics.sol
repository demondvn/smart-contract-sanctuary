pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath 
{

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */

  function mul(uint256 a, uint256 b) internal pure returns(uint256 c) 
  {
     if (a == 0) 
     {
     	return 0;
     }
     c = a * b;
     assert(c / a == b);
     return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */

  function div(uint256 a, uint256 b) internal pure returns(uint256) 
  {
     return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */

  function sub(uint256 a, uint256 b) internal pure returns(uint256) 
  {
     assert(b <= a);
     return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */

  function add(uint256 a, uint256 b) internal pure returns(uint256 c) 
  {
     c = a + b;
     assert(c >= a);
     return c;
  }
}

contract ERC20
{
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

/**
 * @title Basic token
 */

contract TrustLogics is ERC20
{
    using SafeMath for uint256;
   
    uint256 constant public TOKEN_DECIMALS = 10 ** 18;
    uint256 public totalCrowdsaleSupply    = 234973535; 
    uint256 public totalOwnerSupply        = 192251075;     
    string public constant name            = "TrustLogics Token";
    string public constant symbol          = "TLT";
    uint256 public totalTokenSupply        = 427224610 * TOKEN_DECIMALS;  
    address public owner;
    address public trustLogicsCrowdsale;
    bool public mintedCrowdsale;
    bool transferEnabled =false;
    
    struct investorDetail{
        address investorAddress;
        bool transferEnabled;
        uint startTime;
        uint endTime;
    }

    /** mappings **/ 
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) balances;
    mapping(address => investorDetail) investorDetails;
 
    /**
     * @dev Throws if called by any account other than the owner.
     */

    modifier onlyOwner() 
    {
       require(msg.sender == owner);
       _;
    }
   /**
     * @dev Throws if called by any account other than the owner or if the transfer is enabled.
     */

        modifier onlyWhenTransferAllowed() {
        require(investorDetails[tx.origin].transferEnabled || tx.origin == owner||(balances[tx.origin]>0 &&investorDetails[tx.origin].investorAddress !=tx.origin));
        _;
    }
    
    /** constructor **/

    constructor() public
    {
       owner =msg.sender;
       balances[owner] = totalOwnerSupply.mul(TOKEN_DECIMALS);
       emit Transfer(address(0), owner, balances[owner]);
    }
    
    function mint(address _trustlogicsCrowdSale) public onlyOwner
    {
       require(!mintedCrowdsale);

       trustLogicsCrowdsale = _trustlogicsCrowdSale;
       balances[trustLogicsCrowdsale] = totalCrowdsaleSupply.mul(TOKEN_DECIMALS);
       mintedCrowdsale = true;
       emit Transfer(address(0), trustLogicsCrowdsale, balances[trustLogicsCrowdsale]);
    }

    /**
     * @dev total number of tokens in existence
     */

    function totalSupply() public view returns(uint256 _totalSupply) 
    {
       _totalSupply = totalTokenSupply;
       return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of. 
     * @return An uint256 representing the amount owned by the passed address.
     */

    function balanceOf(address _owner) public view returns (uint256 balance) 
    {
       return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool)     
    {

      require(balances[_from] >= _value && allowed[_from][tx.origin] >= _value && _value >= 0);
        allowed[_from][tx.origin] = allowed[_from][tx.origin].sub(_value);
        return _transfer(_from, _to, _value);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _tokens The amount of tokens to be spent.
    */

    function approve(address _spender, uint256 _tokens)public returns(bool)
    {
       require(_spender != address(0));

           allowed[tx.origin][_spender] = _tokens;
       emit Approval(tx.origin, _spender, _tokens);
       return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifing the amount of tokens still avaible for the spender.
     */

    function allowance(address _owner, address _spender) public view returns(uint256)
    {
       require(_owner != address(0) && _spender != address(0));

       return allowed[_owner][_spender];
    }

  

   
        function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
             if (_value == 0) 
      {
          emit Transfer(_from, _to, _value);  // Follow the spec to launch the event when value is equal to 0
          return;
      }

       require(_to != address(0));
            
        require(balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
	
   /**
    * @dev transfer token for a specified address
    * @param _address The address to transfer to.
    * @param _tokens The amount to be transferred.
    */
    function transfer(address _address, uint256 _tokens) public onlyWhenTransferAllowed returns (bool) {
        return _transfer(tx.origin, _address, _tokens);
    }
    
    function transferBy(address _to, uint256 _amount) external onlyOwner returns(bool) 
    {
        return _transfer(trustLogicsCrowdsale, _to, _amount);
    }
	
	  /**
     * Enable transfers
     */

    function enableInvestorTransfer(address _investorAddress) external  {
        require(now >= (investorDetails[_investorAddress].startTime).add(investorDetails[_investorAddress].endTime));
        investorDetails[_investorAddress].transferEnabled = true;
        
    }
    
    function changeOwnership(address _newOwner)public onlyOwner
    {
       require( _newOwner != address(0));

       balances[_newOwner] = (balances[_newOwner]).add(balances[owner]);
       balances[owner] = 0;
       owner = _newOwner;
       emit Transfer(msg.sender, _newOwner, balances[_newOwner]);
   }
   
   function investor(address _investorAddress,uint _lockPeriod,uint _tokens) public onlyOwner{
       require( _investorAddress != address(0));
       investorDetails[_investorAddress].investorAddress = _investorAddress;
       investorDetails[_investorAddress].startTime = now;
       investorDetails[_investorAddress].endTime = _lockPeriod * 1 days;
       investorDetails[_investorAddress].transferEnabled = false;
       transfer(_investorAddress,_tokens);
       
   }
   function getInvestorDetails(address _investorAddress) view public returns (uint,uint,bool){
       
       return(investorDetails[_investorAddress].startTime,investorDetails[_investorAddress].endTime,investorDetails[_investorAddress].transferEnabled);
   }
}