/*
 * This file was generated by MyWish Platform (https://mywish.io/)
 * The complete code could be found at https://github.com/MyWishPlatform/
 * Copyright (C) 2018 MyWish
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
pragma solidity ^0.4.23;


//sol Wallet
// Multi-sig, daily-limited account proxy/wallet.
// @authors:
// Gav Wood <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d4b394b1a0bcb0b1a2fab7bbb9">[email&#160;protected]</a>>
// inheritable "property" contract that enables methods to be protected by requiring the acquiescence of either a
// single, or, crucially, each of a number of, designated owners.
// usage:
// use modifiers onlyowner (just own owned) or onlymanyowners(hash), whereby the same hash must be provided by
// some number (specified in constructor) of the set of owners (specified in the constructor, modifiable) before the
// interior is executed.
contract WalletAbi {
  // Revokes a prior confirmation of the given operation
  function revoke(bytes32 _operation) external;

  // Replaces an owner `_from` with another `_to`.
  function changeOwner(address _from, address _to) external;

  function addOwner(address _owner) external;

  function removeOwner(address _owner) external;

  function changeRequirement(uint _newRequired) external;

  // (re)sets the daily limit. needs many of the owners to confirm. doesn&#39;t alter the amount already spent today.
  function setDailyLimit(uint _newLimit) external;

  function execute(address _to, uint _value, bytes _data) external returns (bytes32);

  function hasConfirmed(bytes32 _operation, address _owner) external view returns (bool);

  function isOwner(address _addr) public view returns (bool);

  function confirm(bytes32 _h) public returns (bool);
}



/**
 * Base logic for "soft" destruct contract. In other words - to return funds to the target user.
 */
contract SoftDestruct {
  /**
   * Target user, who will received funds in case of soft destruct.
   */
  address public targetUser;

  /**
   * Flag means that this contract is already destroyed.
   */
  bool private destroyed = false;

  constructor(address _targetUser) public {
    assert(_targetUser != address(0));
    targetUser = _targetUser;
  }

  /**
   * Accept ether only of alive.
   */
  function() public payable onlyAlive {}

  /**
   * Kill the contract and return funds to the target user.
   */
  function kill() public onlyTarget onlyAlive {
    destroyed = true;
    if (address(this).balance == 0) {
      return;
    }
    targetUser.transfer(address(this).balance);
  }

  function isTarget() internal view returns (bool) {
    return targetUser == msg.sender;
  }

  function isDestroyed() internal view returns (bool) {
    return destroyed;
  }

  // ------------ MODIFIERS -----------
  /**
   * @dev Check that contract is not destroyed.
   */
  modifier onlyAlive() {
    require(!destroyed);
    _;
  }

  /**
   * @dev Check that msg.sender is target user.
   */
  modifier onlyTarget() {
    require(isTarget());
    _;
  }
}



//sol Wallet
// Multi-sig, daily-limited account proxy/wallet.
// @authors:
// Gav Wood <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="187f587d6c707c7d6e367b7775">[email&#160;protected]</a>>
// inheritable "property" contract that enables methods to be protected by requiring the acquiescence of either a
// single, or, crucially, each of a number of, designated owners.
// usage:
// use modifiers onlyowner (just own owned) or onlymanyowners(hash), whereby the same hash must be provided by
// some number (specified in constructor) of the set of owners (specified in the constructor, modifiable) before the
// interior is executed.
contract WalletEvents {
  // EVENTS

  // this contract only has six types of events: it can accept a confirmation, in which case
  // we record owner and operation (hash) alongside it.
  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);

  // some others are in the case of an owner changing.
  event OwnerChanged(address oldOwner, address newOwner);
  event OwnerAdded(address newOwner);
  event OwnerRemoved(address oldOwner);

  // the last one is emitted if the required signatures change
  event RequirementChanged(uint newRequirement);

  // Funds has arrived into the wallet (record how much).
  event Deposit(address _from, uint value);

  // Single transaction going out of the wallet (record who signed for it, how much, and to whom it&#39;s going).
  event SingleTransact(address owner, uint value, address to, bytes data, address created);

  // Multi-sig transaction going out of the wallet
  // (record who signed for it last, the operation hash, how much, and to whom it&#39;s going).
  event MultiTransact(address owner, bytes32 operation, uint value, address to, bytes data, address created);

  // Confirmation still needed for a transaction.
  event ConfirmationNeeded(bytes32 operation, address initiator, uint value, address to, bytes data);
}


contract WalletAbiMembers is WalletAbi {
  uint public m_required = 1; //solium-disable-line mixedcase
  uint public m_numOwners = 1; //solium-disable-line mixedcase
  uint public m_dailyLimit = 0; //solium-disable-line mixedcase
  uint public m_spentToday = 0; //solium-disable-line mixedcase

  // solium-disable-next-line mixedcase
  function m_lastDay() public view returns (uint) {
    return block.timestamp;
  }
}


contract WalletAbiFunctions is WalletAbi, SoftDestruct {
  // Revokes a prior confirmation of the given operation
  function revoke(bytes32) external onlyTarget {}

  // Replaces an owner `_from` with another `_to`.
  function changeOwner(address _from, address _to) external onlyTarget {
    require(_from == targetUser);
    targetUser = _to;
  }

  function addOwner(address) external onlyTarget {
    revert();
  }

  function removeOwner(address) external onlyTarget {
    revert();
  }

  function changeRequirement(uint) external onlyTarget {
    revert();
  }

  // (re)sets the daily limit. needs many of the owners to confirm. doesn&#39;t alter the amount already spent today.
  function setDailyLimit(uint) external onlyTarget {
    revert();
  }

  function hasConfirmed(bytes32, address) external view returns (bool) {
    return true;
  }

  function confirm(bytes32) public onlyTarget returns (bool) {
    return true;
  }

  function isOwner(address _address) public view returns (bool) {
    return targetUser == _address;
  }

  // Gets an owner by 0-indexed position (using numOwners as the count)
  function getOwner(uint ownerIndex) public view returns (address) {
    if (ownerIndex > 0) {
      return 0;
    }
    return targetUser;
  }
}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



contract Checkable {
  address private serviceAccount;
  /**
   * Flag means that contract accident already occurs.
   */
  bool private triggered = false;

  /**
   * Occurs when accident happened.
   */
  event Triggered(uint balance);
  /**
   * Occurs when check finished.
   * isAccident is accident occurred
   */
  event Checked(bool isAccident);

  constructor() public {
    serviceAccount = msg.sender;
  }

  /**
   * @dev Replace service account with new one.
   * @param _account Valid service account address.
   */
  function changeServiceAccount(address _account) public onlyService {
    require(_account != 0);
    serviceAccount = _account;
  }

  /**
   * @dev Is caller (sender) service account.
   */
  function isServiceAccount() public view returns (bool) {
    return msg.sender == serviceAccount;
  }

  /**
   * Public check method.
   */
  function check() public payable onlyService notTriggered {
    if (internalCheck()) {
      emit Triggered(address(this).balance);
      triggered = true;
      internalAction();
    }
  }

  /**
   * @dev Do inner check.
   * @return bool true of accident triggered, false otherwise.
   */
  function internalCheck() internal returns (bool);

  /**
   * @dev Do inner action if check was success.
   */
  function internalAction() internal;

  modifier onlyService {
    require(msg.sender == serviceAccount);
    _;
  }

  modifier notTriggered {
    require(!triggered);
    _;
  }
}



/**
* @title Contract that will work with ERC223 tokens.
*/
contract ERC223Receiver {
  /**
   * @dev Standard ERC223 function that will handle incoming token transfers.
   *
   * @param _from  Token sender address.
   * @param _value Amount of tokens.
   * @param _data  Transaction metadata.
   */
  function tokenFallback(address _from, uint _value, bytes _data) public;
}


contract ERC223Basic is ERC20Basic {
  function transfer(address to, uint value, bytes data) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint indexed value, bytes data);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * The base LastWill contract. Check method must be overridden.
 */
contract LastWill is SoftDestruct, Checkable, ERC223Receiver {
    struct RecipientPercent {
        address recipient;
        uint8 percent;
    }

    /**
     * Maximum length of token contracts addresses list
     */
    uint public constant TOKEN_ADDRESSES_LIMIT = 10;

    /**
     * Addresses of token contracts
     */
    address[] private tokenAddresses;

    /**
     * Recipient addresses and corresponding % of funds.
     */
    RecipientPercent[] private percents;

    // ------------ EVENTS ----------------
    // Occurs when contract was killed.
    event Killed(bool byUser);
    // Occurs when funds were sent.
    event FundsAdded(address indexed from, uint amount);
    // Occurs when accident leads to sending funds to recipient.
    event FundsSent(address recipient, uint amount, uint percent);
    // Occurs when accident leads to sending tokens to recipient
    event TokensSent(address token, address recipient, uint amount, uint percent);

    // ------------ CONSTRUCT -------------
    constructor(
        address _targetUser,
        address[] _recipients,
        uint[] _percents
    ) public SoftDestruct(_targetUser) {
        require(_recipients.length == _percents.length);
        percents.length = _recipients.length;
        // check percents
        uint summaryPercent = 0;
        for (uint i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint percent = _percents[i];

            require(recipient != 0x0);
            summaryPercent += percent;
            percents[i] = RecipientPercent(recipient, uint8(percent));
        }
        require(summaryPercent == 100);
    }

    // ------------ FALLBACK -------------
    // Must be less than 2300 gas
    function () public payable onlyAlive() notTriggered {
        emit FundsAdded(msg.sender, msg.value);
    }

    function addTokenAddresses(address[] _contracts) external onlyTarget notTriggered {
        require(tokenAddresses.length + _contracts.length <= TOKEN_ADDRESSES_LIMIT);
        for (uint i = 0; i < _contracts.length; i++) {
            _addTokenAddress(_contracts[i]);
        }
    }

    function addTokenAddress(address _contract) public onlyTarget notTriggered {
        require(tokenAddresses.length < TOKEN_ADDRESSES_LIMIT);
        _addTokenAddress(_contract);
    }

    function deleteTokenAddress(address _contract) public onlyTarget {
        require(_contract != address(0));
        require(isTokenAddressAlreadyInList(_contract));
        for (uint i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == _contract) {
                tokenAddresses[i] = tokenAddresses[tokenAddresses.length - 1];
                delete tokenAddresses[tokenAddresses.length - 1];
                tokenAddresses.length--;
                break;
            }
        }
    }

    /**
     * Limit check execution only for alive contract.
     */
    function check() public onlyAlive payable {
        super.check();
    }

    /**
     * Extends super method to add event producing.
     */
    function kill() public {
        super.kill();
        emit Killed(true);
    }

    /**
     * Reject not listed tokens.
     */
    function tokenFallback(address, uint, bytes) public {
        require(isTokenAddressAlreadyInList(msg.sender));
    }

    function getTokenAddresses() public view returns (address[]) {
        return tokenAddresses;
    }

    // ------------ INTERNAL -------------
    function _addTokenAddress(address _contract) internal {
        require(_contract != address(0));
        require(!isTokenAddressAlreadyInList(_contract));
        tokenAddresses.push(_contract);
    }

    /**
     * Calculate amounts to transfer corresponding to the percents.
     */
    function calculateAmounts(uint balance) internal view returns (uint[] amounts) {
        uint remainder = balance;
        amounts = new uint[](percents.length);
        for (uint i = 0; i < percents.length; i++) {
            if (i + 1 == percents.length) {
                amounts[i] = remainder;
                break;
            }
            uint amount = balance * percents[i].percent / 100;
            amounts[i] = amount;
            remainder -= amount;
        }
    }

    /**
     * Distribute funds between recipients in corresponding by percents.
     */
    function distributeFunds() internal {
        uint[] memory amounts = calculateAmounts(address(this).balance);

        for (uint i = 0; i < amounts.length; i++) {
            uint amount = amounts[i];
            address recipient = percents[i].recipient;
            uint percent = percents[i].percent;

            if (amount == 0) {
                continue;
            }

            recipient.transfer(amount);
            emit FundsSent(recipient, amount, percent);
        }
    }

    function distributeTokens() internal {
        for (uint i = 0; i < tokenAddresses.length; i++) {
            ERC20Basic token = ERC20Basic(tokenAddresses[i]);
            uint[] memory amounts = calculateAmounts(token.balanceOf(this));

            for (uint j = 0; j < amounts.length; j++) {
                uint amount = amounts[j];
                address recipient = percents[j].recipient;
                uint percent = percents[j].percent;

                if (amount == 0) {
                    continue;
                }

                token.transfer(recipient, amount);
                emit TokensSent(token, recipient, amount, percent);
            }
        }
    }

    /**
     * @dev Do inner action if check was success.
     */
    function internalAction() internal {
        distributeFunds();
        distributeTokens();
    }

    function isTokenAddressAlreadyInList(address _contract) internal view returns (bool) {
        for (uint i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == _contract) return true;
        }
        return false;
    }
}


contract ERC20Wallet {
  function tokenBalanceOf(address _token) public view returns (uint) {
    return ERC20(_token).balanceOf(this);
  }

  function tokenTransfer(address _token, address _to, uint _value) public returns (bool) {
    return ERC20(_token).transfer(_to, _value);
  }

  function tokenTransferFrom(
    address _token,
    address _from,
    address _to,
    uint _value
  )
    public
    returns (bool)
  {
    return ERC20(_token).transferFrom(_from, _to, _value);
  }

  function tokenApprove(address _token, address _spender, uint256 _value) public returns (bool) {
    return ERC20(_token).approve(_spender, _value);
  }

  function tokenAllowance(address _token, address _owner, address _spender) public view returns (uint) {
    return ERC20(_token).allowance(_owner, _spender);
  }
}



library TxUtils {
  struct Transaction {
    address to;
    uint value;
    bytes data;
    uint timestamp;
  }

  function equals(Transaction self, Transaction other) internal pure returns (bool) {
    return (self.to == other.to) && (self.value == other.value) && (self.timestamp == other.timestamp);
  }

  function isNull(Transaction self) internal pure returns (bool) {
    // solium-disable-next-line arg-overflow
    return equals(self, Transaction(address(0), 0, "", 0));
  }
}


contract Wallet is WalletEvents, WalletAbiMembers, WalletAbiFunctions {
  function execute(address _to, uint _value, bytes _data) external returns (bytes32);
}


contract LostKeyERC20Wallet is LastWill, ERC20Wallet {
  uint64 public lastOwnerActivity;
  uint64 public noActivityPeriod;

  event Withdraw(address _sender, uint amount, address _beneficiary);

  constructor(
    address _targetUser,
    address[] _recipients,
    uint[] _percents,
    uint64 _noActivityPeriod
  )
    public
    LastWill(_targetUser, _recipients, _percents)
  {
    noActivityPeriod = _noActivityPeriod;
    lastOwnerActivity = uint64(block.timestamp);
  }

  function sendFunds(uint _amount, address _receiver, bytes _data) public onlyTarget onlyAlive {
    sendFundsInternal(_amount, _receiver, _data);
  }

  function sendFunds(uint _amount, address _receiver) public onlyTarget onlyAlive {
    sendFundsInternal(_amount, _receiver, "");
  }

  function check() public payable {
    // we really do not need payable in this implementation
    require(msg.value == 0);
    super.check();
  }

  function tokenTransfer(address _token, address _to, uint _value) public onlyTarget returns (bool success) {
    updateLastActivity();
    return super.tokenTransfer(_token, _to, _value);
  }

  function tokenTransferFrom(
    address _token,
    address _from,
    address _to,
    uint _value
  )
    public
    onlyTarget
    returns (bool success)
  {
    updateLastActivity();
    return super.tokenTransferFrom(
      _token,
      _from,
      _to,
      _value
    );
  }

  function tokenApprove(address _token, address _spender, uint256 _value) public onlyTarget returns (bool success) {
    updateLastActivity();
    return super.tokenApprove(_token, _spender, _value);
  }

  function internalCheck() internal returns (bool) {
    bool result = block.timestamp > lastOwnerActivity && (block.timestamp - lastOwnerActivity) >= noActivityPeriod;
    emit Checked(result);
    return result;
  }

  function updateLastActivity() internal {
    lastOwnerActivity = uint64(block.timestamp);
  }

  function sendFundsInternal(uint _amount, address _receiver, bytes _data) internal {
    require(address(this).balance >= _amount);
    if (_data.length == 0) {
      // solium-disable-next-line security/no-send
      require(_receiver.send(_amount));
    } else {
      // solium-disable-next-line security/no-call-value
      require(_receiver.call.value(_amount)(_data));
    }

    emit Withdraw(msg.sender, _amount, _receiver);
    updateLastActivity();
  }
}


library QueueUtils {
  using TxUtils for TxUtils.Transaction;

  struct Queue {
    uint length;
    uint head;
    uint tail;
    mapping(uint => Node) list;
  }

  struct Node {
    uint prev;
    uint next;
    TxUtils.Transaction data; // key == data.timestamp
  }

  function size(Queue storage _self) internal view returns (uint) {
    return _self.length;
  }

  function isEmpty(Queue storage _self) internal view returns (bool) {
    return size(_self) == 0;
  }

  function getTransaction(Queue storage _self, uint _index) internal view returns (TxUtils.Transaction) {
    uint count = 0;
    for (uint i = _self.head; i <= _self.tail; i = _self.list[i].prev) {
      Node memory node = _self.list[i];
      if (count == _index) {
        return node.data;
      }
      count++;
    }
  }

  function push(Queue storage _self, TxUtils.Transaction _tx) internal {
    require(_self.list[_tx.timestamp].data.isNull(), "Cannot push transaction with same timestamp");

    Node memory node;
    if (_self.list[_self.tail].data.isNull()) {
      node = Node(0, 0, _tx);
      _self.head = _tx.timestamp;
    } else {
      _self.list[_self.tail].prev = _tx.timestamp;
      Node storage nextNode = _self.list[_self.tail];
      node = Node(0, nextNode.data.timestamp, _tx);
      nextNode.prev = _tx.timestamp;
    }
    _self.list[_tx.timestamp] = node;
    _self.tail = _tx.timestamp;
    _self.length++;
  }

  function peek(Queue storage _self) internal view returns (TxUtils.Transaction) {
    // solium-disable-next-line arg-overflow
    return isEmpty(_self) ? TxUtils.Transaction(0, 0, "", 0) : _self.list[_self.head].data;
  }

  function pop(Queue storage _self) internal returns (TxUtils.Transaction) {
    if (isEmpty(_self)) {
      // solium-disable-next-line arg-overflow
      return TxUtils.Transaction(0, 0, "", 0);
    }

    if (size(_self) == 1) {
      _self.tail = 0;
    }

    Node memory current = _self.list[_self.head];
    uint newHead = current.prev;
    delete _self.list[_self.head];
    _self.head = newHead;
    _self.length--;

    return current.data;
  }

  function remove(Queue storage _self, TxUtils.Transaction _tx) internal returns (bool) {
    require(size(_self) > 0, "Queue is empty");

    uint iterator = _self.tail;
    while (iterator != 0) {
      Node memory node = _self.list[iterator];
      if (node.data.equals(_tx)) {
        if (node.prev != 0 && node.next != 0) {
          _self.list[node.prev].next = _self.list[node.next].data.timestamp;
          _self.list[node.next].prev = _self.list[node.next].data.timestamp;
        } else if (node.prev != 0) {
          _self.list[node.prev].next = 0;
          _self.head = node.prev;
        } else if (node.next != 0) {
          _self.list[node.next].prev = 0;
          _self.tail = node.next;
        }

        delete _self.list[iterator];
        _self.length--;
        return true;
      }
      iterator = _self.list[iterator].next;
    }

    return false;
  }
}


contract LostKeyDelayedPaymentWallet is Wallet, LostKeyERC20Wallet {
  using QueueUtils for QueueUtils.Queue;

  // Threshold value, when sending more, the transaction will be postponed.
  // If the value is zero, then all transactions will be sent immediately.
  uint public transferThresholdWei;
  // The value of the delay to which the transaction will be postponed if the sum of the threshold value is exceeded.
  uint public transferDelaySeconds;
  // Transaction queue.
  QueueUtils.Queue internal queue;

  // Occurs when contract was killed.
  event Killed(bool byUser);
  // Occurs when founds were sent.
  event FundsAdded(address indexed from, uint amount);
  // Occurs when accident leads to sending funds to recipient.
  event FundsSent(address recipient, uint amount, uint percent);

  /**
   * @param _targetUser           Contract owner.
   * @param _recipients           A list of users between which the funds will be divided in the case of some period of
   *                              inactivity of the target user.
   * @param _percents             Percentages corresponding to users. How many users will receive from the total number
   *                              of shared funds.
   * @param _noActivityPeriod     The period of inactivity, after which the funds will be divided between the heirs.
   * @param _transferThresholdWei Threshold value. If you try to send an amount more than which the transaction will
   *                              be added to the queue and will be sent no earlier than _transferDelaySeconds
   *                              seconds. If the value is zero, then all transactions will be sent immediately.
   * @param _transferDelaySeconds The number of seconds that the sending of funds will be delayed if you try to send
   *                              an amount greater than _transferThresholdWei.
   */
  constructor(
    address _targetUser,
    address[] _recipients,
    uint[] _percents,
    uint64 _noActivityPeriod,
    uint _transferThresholdWei,
    uint _transferDelaySeconds
  )
    public
    LostKeyERC20Wallet(
      _targetUser,
      _recipients,
      _percents,
      _noActivityPeriod
    )
  {
    transferThresholdWei = _transferThresholdWei;
    transferDelaySeconds = _transferDelaySeconds;
  }

  /**
   * @notice  Same as sendFunds but for wallet compatibility. Sending funds to the recipient or delaying the
   *          transaction for a certain time. In case of a delay, the sendDelayedTransactions() function can send the
   *          transaction after the delay time has elapsed.
   *
   * @param _to     Recipient of funds.
   * @param _value  Amount of funds.
   * @param _data   Call data.
   */
  function execute(address _to, uint _value, bytes _data) external returns (bytes32) {
    sendFunds(_to, _value, _data);
    return keccak256(abi.encodePacked(msg.data, block.number));
  }

  /**
   * @notice  Sending funds to the recipient or delaying the transaction for a certain time. In case of a delay, the
   *          sendDelayedTransactions() function can send the transaction after the delay time has elapsed.
   *
   * @param _to     Recipient of funds.
   * @param _amount Amount of funds.
   * @param _data   Call data.
   */
  function sendFunds(address _to, uint _amount, bytes _data) public onlyTarget onlyAlive {
    require(_to != address(0), "Address should not be 0");
    if (_data.length == 0) {
      require(_amount != 0, "Amount should not be 0");
    }

    if (_amount < transferThresholdWei || transferThresholdWei == 0) {
      sendFundsInternal(_amount, _to, _data);
    } else {
      queue.push(TxUtils.Transaction(
          _to,
          _amount,
          _data,
          now + transferDelaySeconds
        ));
    }
  }

  /**
   * @notice Returns pending transaction data with the specified index.
   *
   * @param _index        Transaction index in the queue.
   * @return to           Recipient of funds.
   * @return value        Amount sent to the recipient.
   * @return timestamp    Timestamp not earlier than which funds are allowed to be sent.
   */
  function getTransaction(uint _index) public view returns (address to, uint value, bytes data, uint timestamp) {
    TxUtils.Transaction memory t = queue.getTransaction(_index);
    return (t.to, t.value, t.data, t.timestamp);
  }

  /**
   * @notice Cancellation of a queued transaction.
   *
   * @param _to         The recipient of the transaction funds to be canceled.
   * @param _value      Amount of transaction funds to be canceled.
   * @param _data       Call data of transaction to be canceled.
   * @param _timestamp  Timestamp, not before that will be available to send the transaction to be canceled.
   */
  function reject(
    address _to,
    uint _value,
    bytes _data,
    uint _timestamp
  )
    public
    onlyTarget
  {
    TxUtils.Transaction memory transaction = TxUtils.Transaction(
      _to,
      _value,
      _data,
      _timestamp
    );
    require(queue.remove(transaction), "Transaction not found in queue");
  }

  /**
   * @notice Send all delayed transactions that are already allowed to send.
   *
   * @return isSent At least one transaction was sent.
   */
  function sendDelayedTransactions() public returns (bool isSent) {
    for (uint i = 0; i < queue.size(); i++) {
      if (queue.peek().timestamp > now) {
        break;
      }
      internalSendTransaction(queue.pop());
      isSent = true;
    }
  }

  /**
   * @return size Number of transactions in the queue.
   */
  function queueSize() public view returns (uint size) {
    return queue.size();
  }

  /**
   * @dev Immediate transaction sending.
   *
   * @param _tx The transaction to be sent.
   */
  function internalSendTransaction(TxUtils.Transaction _tx) internal {
    sendFundsInternal(_tx.value, _tx.to, _tx.data);
  }
}