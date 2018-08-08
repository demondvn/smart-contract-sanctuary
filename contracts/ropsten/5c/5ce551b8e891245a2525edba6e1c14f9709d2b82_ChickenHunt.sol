pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
  }

  function square(uint256 a) internal pure returns (uint256) {
    return mul(a, a);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
  }

}

contract ERC20Interface {

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  function totalSupply() public view returns (uint256);
  function balanceOf(address _owner) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function allowance( address _owner, address _spender) public view returns (uint256);

}

/**
 * @title CHStock
 * @author M.H. Kang
 */
contract CHStock is ERC20Interface {

  using SafeMath for uint256;

  /* EVENT */

  event Exit(
    address indexed _user,
    uint256 _shares,
    uint256 _value
  );

  /* STORAGE */

  string public name = "ChickenHuntStock";
  string public symbol = "CHS";
  uint8 public decimals = 18;
  uint256 public totalShares;
  uint256 public dividendsPerShare;
  uint256 constant correction = 1 << 64; // TODO CHECK 64 or 128 ?
  mapping (address => uint256) public ethBalance;
  mapping (address => uint256) internal shares;
  mapping (address => uint256) internal refund;
  mapping (address => uint256) internal deduction;
  mapping (address => mapping (address => uint256)) internal allowed;

  /* FUNCTION */

  function exit() public {
    uint256 _shares = shares[msg.sender];
    uint256 _dividends = dividendsOf(msg.sender);

    delete shares[msg.sender];
    delete refund[msg.sender];
    delete deduction[msg.sender];
    totalShares = totalShares.sub(_shares);
    ethBalance[msg.sender] = ethBalance[msg.sender].add(_dividends);

    emit Exit(msg.sender, _shares, _dividends);
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool)
  {
    require(_value <= allowed[_from][msg.sender]);
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function dividendsOf(address _shareholder) public view returns (uint256) {
    return dividendsPerShare.mul(shares[_shareholder]).add(refund[_shareholder]).sub(deduction[_shareholder]) / correction;
  }

  function totalSupply() public view returns (uint256) {
    return totalShares;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return shares[_owner];
  }

  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /* INTERNAL FUNCTION */

  function _giveShares(address _user, uint256 _ether) internal {
    if (_ether > 0) {
      totalShares = totalShares.add(_ether);
      deduction[_user] = deduction[_user].add(dividendsPerShare.mul(_ether));
      shares[_user] = shares[_user].add(_ether);
      dividendsPerShare = dividendsPerShare.add(_ether.mul(correction) / totalShares);

      emit Transfer(address(0), _user, _ether);
    }
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    require(_value <= shares[_from]);
    uint256 _rawProfit = dividendsPerShare.mul(_value);

    // TODO TEST
    uint256 _refund = refund[_from].add(_rawProfit);
    uint256 _min = _refund < deduction[_from] ? _refund : deduction[_from];
    refund[_from] = _refund.sub(_min);
    deduction[_from] = deduction[_from].sub(_min);
    deduction[_to] = deduction[_to].add(_rawProfit);

    shares[_from] = shares[_from].sub(_value);
    shares[_to] = shares[_to].add(_value);

    emit Transfer(_from, _to, _value);
  }

}

/**
 * @title CHGameBase
 * @author M.H. Kang
 */
contract CHGameBase is CHStock {

  /* DATA STRUCT */

  struct House {
    Hunter hunter;
    Barrier barrier;
    uint256 huntingPower;
    uint256 offensePower;
    uint256 defensePower;
    uint256 huntingMultiplier;
    uint256 offenseMultiplier;
    uint256 defenseMultiplier;
    uint256 depots;
  }

  struct Hunter {
    uint256 strength;
    uint256 dexterity;
  }

  struct Barrier {
    uint256 structure;
    uint256 material;
  }

  struct Store {
    address owner;
    uint256 cut;
    uint256 cost;
    uint256 balance;
  }

  /* STORAGE */

  Store public store;
  uint256 public devCut;
  uint256 public devFee;
  uint256 public altarCut;
  uint256 public altarFund;
  uint256 public dividendRate;
  uint256 public totalChicken;
  address public chickenTokenDelegator;
  mapping (address => uint256) public lastSaveTime;
  mapping (address => uint256) public savedChickenOf;
  mapping (address => House) internal houses;
  mapping (address => uint256[]) internal petsOf;

  /* FUNCTION */

  function saveChickenOf(address _user) public returns (uint256) {
    uint256 _unclaimedChicken = _unclaimedChickenOf(_user);
    totalChicken = totalChicken.add(_unclaimedChicken);
    uint256 _chicken = savedChickenOf[_user].add(_unclaimedChicken);
    savedChickenOf[_user] = _chicken;
    lastSaveTime[_user] = block.timestamp;
    return _chicken;
  }

  function transferChickenFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(msg.sender == chickenTokenDelegator);
    require(saveChickenOf(_from) >= _value);
    savedChickenOf[_from] = savedChickenOf[_from] - _value;
    savedChickenOf[_to] = savedChickenOf[_to].add(_value);

    return true;
  }

  function chickenOf(address _user) public view returns (uint256) {
    return savedChickenOf[_user].add(_unclaimedChickenOf(_user));
  }

  /* INTERNAL FUNCTION */

  function _payChicken(address _user, uint256 _chicken) internal {
    uint256 _unclaimedChicken = _unclaimedChickenOf(_user);
    uint256 _extraChicken;

    if (_chicken > _unclaimedChicken) {
      _extraChicken = _chicken - _unclaimedChicken;
      require(savedChickenOf[_user] >= _extraChicken);
      savedChickenOf[_user] -= _extraChicken;
      totalChicken -= _extraChicken;
    } else {
      _extraChicken = _unclaimedChicken - _chicken;
      totalChicken = totalChicken.add(_extraChicken);
      savedChickenOf[_user] += _extraChicken;
    }

    lastSaveTime[_user] = block.timestamp;
  }

  function _payEtherAndDistribute(uint256 _cost) internal {
    require(_cost * 100 / 100 == _cost);
    _payEther(_cost);

    uint256 _toShareholders = _cost * dividendRate / 100;
    uint256 _toAltar = _cost * altarCut / 100;
    uint256 _toStore = _cost * store.cut / 100;
    devFee = devFee.add(_cost - _toShareholders - _toAltar - _toStore);

    _giveShares(msg.sender, _toShareholders);
    altarFund = altarFund.add(_toAltar);
    store.balance = store.balance.add(_toStore);
  }

  function _payEther(uint256 _cost) internal {
    uint256 _extra;
    if (_cost > msg.value) {
      _extra = _cost - msg.value;
      require(ethBalance[msg.sender] >= _extra);
      ethBalance[msg.sender] -= _extra;
    } else {
      _extra = msg.value - _cost;
      ethBalance[msg.sender] = ethBalance[msg.sender].add(_extra);
    }
  }

  function _unclaimedChickenOf(address _user) internal view returns (uint256) {
    uint256 _timestamp = lastSaveTime[_user];
    if (_timestamp > 0 && _timestamp < block.timestamp) {
      return houses[_user].huntingPower.mul(
        houses[_user].huntingMultiplier
      ).mul(block.timestamp - _timestamp) / 100;
    } else {
      return 0;
    }
  }

  function _houseOf(address _user)
    internal
    view
    returns (House storage _house)
  {
    _house = houses[_user];
    require(lastSaveTime[msg.sender] > 0);
  }

}

/**
 * @title CHHunter
 * @author M.H. Kang
 */
contract CHHunter is CHGameBase {

  /* EVENT */

  event Upgrade(
    address indexed _user,
    string _type,
    uint256 _to
  );

  /* DATA STRUCT */

  struct Config {
    uint256 chicken;
    uint256 eth;
    uint256 max;
  }

  /* STORAGE */

  Config public typeA;
  Config public typeB;

  /* FUNCTION */

  function upgradeStrength(uint256 _to) external payable {
    House storage _house = _houseOf(msg.sender);
    uint256 _from = _house.hunter.strength;
    require(typeA.max >= _to && _to > _from);
    _payForUpgrade(_from, _to, typeA);

    uint256 _increment = _house.hunter.dexterity.mul(2).add(8).mul(_to.square() - _from ** 2);
    _house.hunter.strength = _to;
    _house.huntingPower = _house.huntingPower.add(_increment);
    _house.offensePower = _house.offensePower.add(_increment);

    emit Upgrade(msg.sender, "strength", _to);
  }

  function upgradeDexterity(uint256 _to) external payable {
    House storage _house = _houseOf(msg.sender);
    uint256 _from = _house.hunter.dexterity;
    require(typeB.max >= _to && _to > _from);
    _payForUpgrade(_from, _to, typeB);

    uint256 _increment = _house.hunter.strength.square().mul((_to - _from).mul(2));
    _house.hunter.dexterity = _to;
    _house.huntingPower = _house.huntingPower.add(_increment);
    _house.offensePower = _house.offensePower.add(_increment);

    emit Upgrade(msg.sender, "dexterity", _to);
  }

  function upgradeStructure(uint256 _to) external payable {
    House storage _house = _houseOf(msg.sender);
    uint256 _from = _house.barrier.structure;
    require(typeA.max >= _to && _to > _from);
    _payForUpgrade(_from, _to, typeA);

    uint256 _increment = _house.barrier.material.mul(2).add(8).mul(_to.square() - _from ** 2);
    _house.barrier.structure = _to;
    _house.defensePower = _house.defensePower.add(_increment);

    emit Upgrade(msg.sender, "structure", _to);
  }

  function upgradeMaterial(uint256 _to) external payable {
    House storage _house = _houseOf(msg.sender);
    uint256 _from = _house.barrier.material;
    require(typeB.max >= _to && _to > _from);
    _payForUpgrade(_from, _to, typeB);

    uint256 _increment = _house.barrier.structure.square().mul((_to - _from).mul(2));
    _house.barrier.material = _to;
    _house.defensePower = _house.defensePower.add(_increment);

    emit Upgrade(msg.sender, "material", _to);
  }

  /* INTERNAL FUNCTION */

  function _payForUpgrade(
    uint256 _from,
    uint256 _to,
    Config _type
  )
    internal
  {
    uint256 _chickenCost = _type.chicken.mul(_gapOfCubeSum(_from, _to));
    _payChicken(msg.sender, _chickenCost);
    uint256 _ethCost = _type.eth.mul(_gapOfSquareSum(_from, _to));
    _payEtherAndDistribute(_ethCost);
  }

  function _gapOfSquareSum(uint256 _before, uint256 _after)
    internal
    pure
    returns (uint256)
  {
    require(_after == uint256(uint32(_after)));
    return (_after * (_after - 1) * ( 2 * _after - 1) - _before * (_before - 1) * ( 2 * _before - 1)) / 6;
  }

  function _gapOfCubeSum(uint256 _before, uint256 _after)
    internal
    pure
    returns (uint256)
  {
    require(_after == uint256(uint32(_after)));
    return ((_after * (_after - 1)) ** 2 - (_before * (_before - 1)) ** 2) >> 2;
  }

}

/**
 * @title CHHouse
 * @author M.H. Kang
 */
contract CHHouse is CHHunter {

  /* EVENT */

  event UpgradePet(
    address indexed _user,
    uint256 _id,
    uint256 _value
  );

  event UpgradeDepot(
    address indexed _user,
    uint256 _value
  );

  event BuyItem(
    address indexed _from,
    address indexed _to,
    uint256 indexed _id,
    uint256 _cost
  );

  event BuyStore(
    address indexed _from,
    address indexed _to,
    uint256 _cost
  );

  /* DATA STRUCT */

  struct Pet {
    uint256 huntingPower;
    uint256 offensePower;
    uint256 defensePower;
    uint256 chicken;
    uint256 eth;
    uint256 max;
  }

  struct Item {
    address owner;
    uint256 huntingMultiplier;
    uint256 offenseMultiplier;
    uint256 defenseMultiplier;
    uint256 cost;
  }

  struct Depot {
    uint256 eth;
    uint256 max;
  }

  /* STORAGE */

  uint256 constant incrementRate = 12; // 120% for Item and Store
  Depot public depot;
  Pet[] public pets;
  Item[] public items;

  /* FUNCTION */

  function buyDepots(uint256 _amount) external payable {
    House storage _house = _houseOf(msg.sender);
    _house.depots = _house.depots.add(_amount);
    require(_house.depots <= depot.max);
    _payEtherAndDistribute(_amount.mul(depot.eth));

    emit UpgradeDepot(msg.sender, _house.depots);
  }

  function buyPets(uint256 _id, uint256 _amount) external payable {
    require(_id < pets.length);
    Pet memory _pet = pets[_id];
    uint256 _chickenCost = _amount * _pet.chicken;
    _payChicken(msg.sender, _chickenCost);
    uint256 _ethCost = _amount * _pet.eth;
    _payEtherAndDistribute(_ethCost);

    House storage _house = _houseOf(msg.sender);
    uint256[] storage _userPets = petsOf[msg.sender];
    if (_userPets.length < _id + 1) {
      _userPets.length = _id + 1;
    }
    _userPets[_id] = _userPets[_id].add(_amount);
    require(_userPets[_id] <= _pet.max);

    _house.huntingPower = _house.huntingPower.add(_pet.huntingPower * _amount);
    _house.offensePower = _house.offensePower.add(_pet.offensePower * _amount);
    _house.defensePower = _house.defensePower.add(_pet.defensePower * _amount);

    emit UpgradePet(msg.sender, _id, _userPets[_id]);
  }

  // This is independent of Stock and Altar.
  function buyItem(uint256 _id) external payable {
    Item storage _item = items[_id];
    address _from = _item.owner;
    uint256 _price = _item.cost.mul(incrementRate) / 10;
    _payEther(_price);

    saveChickenOf(_from);
    House storage _fromHouse = _houseOf(_from);
    _fromHouse.huntingMultiplier = _fromHouse.huntingMultiplier.sub(_item.huntingMultiplier);
    _fromHouse.offenseMultiplier = _fromHouse.offenseMultiplier.sub(_item.offenseMultiplier);
    _fromHouse.defenseMultiplier = _fromHouse.defenseMultiplier.sub(_item.defenseMultiplier);

    saveChickenOf(msg.sender);
    House storage _toHouse = _houseOf(msg.sender);
    _toHouse.huntingMultiplier = _toHouse.huntingMultiplier.add(_item.huntingMultiplier);
    _toHouse.offenseMultiplier = _toHouse.offenseMultiplier.add(_item.offenseMultiplier);
    _toHouse.defenseMultiplier = _toHouse.defenseMultiplier.add(_item.defenseMultiplier);

    uint256 _halfMargin = _price.sub(_item.cost) / 2;
    devFee = devFee.add(_halfMargin);
    ethBalance[_from] = ethBalance[_from].add(_price - _halfMargin);

    items[_id].cost = _price;
    items[_id].owner = msg.sender;

    emit BuyItem(_from, msg.sender, _id, _price);
  }

  // This is independent of Stock and Altar.
  function buyStore() external payable {
    address _from = store.owner;
    uint256 _price = store.cost.mul(incrementRate) / 10;
    _payEther(_price);

    uint256 _halfMargin = (_price - store.cost) / 2;
    devFee = devFee.add(_halfMargin);
    ethBalance[_from] = ethBalance[_from].add(_price - _halfMargin).add(store.balance);

    store.cost = _price;
    store.owner = msg.sender;
    delete store.balance;

    emit BuyStore(_from, msg.sender, _price);
  }

  function withdrawStoreBalance() public {
    ethBalance[store.owner] = ethBalance[store.owner].add(store.balance);
    delete store.balance;
  }

}

/**
 * @title CHArena
 * @author M.H. Kang
 */
contract CHArena is CHHouse {

  /* EVENT */

  event Attack(
    address indexed _attacker,
    address indexed _defender,
    uint256 _booty
  );

  /* STORAGE */

  mapping(address => uint256) public attackCooldown;
  uint256 public cooldownTime;

  /* FUNCTION */

  function attack(address _target) external {
    require(attackCooldown[msg.sender] < block.timestamp);
    House storage _attacker = houses[msg.sender];
    House storage _defender = houses[_target];
    if (_attacker.offensePower.mul(_attacker.offenseMultiplier)
        > _defender.defensePower.mul(_defender.defenseMultiplier)) {
      uint256 _amount = saveChickenOf(_target);
      _amount = _defender.depots > 0 ? _amount / _defender.depots : _amount;
      savedChickenOf[_target] = savedChickenOf[_target] - _amount;
      savedChickenOf[msg.sender] = savedChickenOf[msg.sender].add(_amount);
      attackCooldown[msg.sender] = block.timestamp + cooldownTime;

      emit Attack(msg.sender, _target, _amount);
    }
  }

}

/**
 * @title CHAltar
 * @author M.H. Kang
 */
contract CHAltar is CHArena {

  /* EVENT */

  event NewAltarRecord(uint256 _id, uint256 _value);
  event ChickenToAltar(address indexed _user, uint256 _id, uint256 _value);
  event EtherFromAltar(address indexed _user, uint256 _id, uint256 _value);

  /* DATA STRUCT */

  struct Record {
    uint256 eth;
    uint256 total;
  }

  struct TradeBook {
    uint256 recordId;
    uint256 amount;
  }

  /* STORAGE */

  uint256 genesis;
  mapping (uint256 => Record) public altarRecords;
  mapping (address => TradeBook) public tradeBooks;

  /* FUNCTION */

  function chickenToAltar(uint256 _amount) external {
    require(_amount > 0);

    _payChicken(msg.sender, _amount);
    uint256 _id = _getCurrentAltarRecordId();
    Record storage _record = _getAltarRecord(_id);
    require(_record.eth * _amount / _amount == _record.eth);
    TradeBook storage _tradeBook = tradeBooks[msg.sender];
    if (_tradeBook.recordId < _id) {
      _resolveTradeBook(_tradeBook);
      _tradeBook.recordId = _id;
    }
    _record.total = _record.total.add(_amount);
    _tradeBook.amount += _amount;

    emit ChickenToAltar(msg.sender, _id, _amount);
  }

  function etherFromAltar() external {
    uint256 _id = _getCurrentAltarRecordId();
    TradeBook storage _tradeBook = tradeBooks[msg.sender];
    require(_tradeBook.recordId < _id);
    _resolveTradeBook(_tradeBook);
  }

  function tradeBookOf(address _user)
    public
    view
    returns (
      uint256 _id,
      uint256 _eth,
      uint256 _totalChicken,
      uint256 _chicken,
      uint256 _income
    )
  {
    TradeBook memory _tradeBook = tradeBooks[_user];
    _id = _tradeBook.recordId;
    _chicken = _tradeBook.amount;
    Record memory _record = altarRecords[_id];
    _totalChicken = _record.total;
    _eth = _record.eth;
    _income = _totalChicken > 0 ? _eth.mul(_chicken) / _totalChicken : 0;
  }

  /* INTERNAL FUNCTION */

  function _resolveTradeBook(TradeBook storage _tradeBook) internal {
    if (_tradeBook.amount > 0) {
      Record memory _oldRecord = altarRecords[_tradeBook.recordId];
      uint256 _ether = _oldRecord.eth.mul(_tradeBook.amount) / _oldRecord.total;
      delete _tradeBook.amount;
      ethBalance[msg.sender] = ethBalance[msg.sender].add(_ether);

      emit EtherFromAltar(msg.sender, _tradeBook.recordId, _ether);
    }
  }

  function _getCurrentAltarRecordId() internal view returns (uint256) {
    return (block.timestamp - genesis) / 86400;
  }

  function _getAltarRecord(uint256 _id) internal returns (Record storage _record) {
    _record = altarRecords[_id];
    if (_record.eth == 0) {
      uint256 _eth = altarFund / 10;
      _record.eth = _eth;
      altarFund -= _eth;

      emit NewAltarRecord(_id, _eth);
    }
  }

}

/**
 * @title CHCommittee
 * @author M.H. Kang
 */
contract CHCommittee is CHAltar {

  /* EVENT */

  event SetConfiguration(
    uint256 _chickenA,
    uint256 _ethA,
    uint256 _maxA,
    uint256 _chickenB,
    uint256 _ethB,
    uint256 _maxB
  );

  event SetDepot(uint256 _eth, uint256 _max);

  event NewPet(
    uint256 _huntingPower,
    uint256 _offensePower,
    uint256 _deffense,
    uint256 _chicken,
    uint256 _eth,
    uint256 _max
  );

  event ChangePet(
    uint256 _id,
    uint256 _chicken,
    uint256 _eth,
    uint256 _max
  );

  event NewItem(
    uint256 _huntingMultiplier,
    uint256 _offenseMultiplier,
    uint256 _defenseMultiplier,
    uint256 _eth
  );

  event SetDistribution(
    uint256 _dividendRate,
    uint256 _altarCut,
    uint256 _storeCut,
    uint256 _devCut
  );

  event SetCooldownTime(uint256 _cooldownTime);
  event SetDeveloper(address _developer);
  event SetCommittee(address _committee);

  /* STORAGE */

  address committee;
  address developer;

  /* FUNCTION */

  function setConfiguration(
    uint256 _chickenA,
    uint256 _ethA,
    uint256 _maxA,
    uint256 _chickenB,
    uint256 _ethB,
    uint256 _maxB
  )
    public
    onlyCommittee
  {
    require(_maxA > typeA.max && (_maxA == uint256(uint32(_maxA))));
    require(_maxB > typeB.max && (_maxB == uint256(uint32(_maxB))));

    typeA.chicken = _chickenA;
    typeA.eth = _ethA;
    typeA.max = _maxA;

    typeB.chicken = _chickenB;
    typeB.eth = _ethB;
    typeB.max = _maxB;

    emit SetConfiguration(_chickenA, _ethA, _maxA, _chickenB, _ethB, _maxB);
  }

  function setDepot(uint256 _price, uint256 _max) public onlyCommittee {
    depot.eth = _price;
    depot.max = _max;

    emit SetDepot(_price, _max);
  }

  function addPet(
    uint256 _huntingPower,
    uint256 _offensePower,
    uint256 _deffense,
    uint256 _chicken,
    uint256 _eth,
    uint256 _max
  )
    public
    onlyCommittee
  {
    require(_max == uint256(uint32(_max)));
    pets.push(
      Pet(_huntingPower, _offensePower, _deffense, _chicken, _eth, _max)
    );

    emit NewPet(
      _huntingPower,
      _offensePower,
      _deffense,
      _chicken,
      _eth,
      _max
    );
  }

  function changePet(
    uint256 _id,
    uint256 _chicken,
    uint256 _eth,
    uint256 _max
  )
    public
    onlyCommittee
  {
    Pet storage _pet = pets[_id];
    require(_pet.max > 0);
    require(_max == uint256(uint32(_max)));

    _pet.chicken = _chicken;
    _pet.eth = _eth;
    _pet.max = _max;

    emit ChangePet(_id, _chicken, _eth, _max);
  }

  function addItem(
    uint256 _huntingMultiplier,
    uint256 _offenseMultiplier,
    uint256 _defenseMultiplier,
    uint256 _price
  )
    public
    onlyCommittee
  {
    House storage _house = _houseOf(committee);
    _house.huntingMultiplier = _house.huntingMultiplier.add(_huntingMultiplier);
    _house.offenseMultiplier = _house.offenseMultiplier.add(_offenseMultiplier);
    _house.defenseMultiplier = _house.defenseMultiplier.add(_defenseMultiplier);

    items.push(
      Item(
        committee,
        _huntingMultiplier,
        _offenseMultiplier,
        _defenseMultiplier,
        _price
      )
    );

    emit NewItem(
      _huntingMultiplier,
      _offenseMultiplier,
      _defenseMultiplier,
      _price
    );
  }

  function setDistribution(
    uint256 _dividendRate,
    uint256 _altarCut,
    uint256 _storeCut,
    uint256 _devCut
  ) public onlyCommittee {
    require(_storeCut > 0);
    require(
      _dividendRate.add(_altarCut).add(_storeCut).add(_devCut) == 100
    );

    dividendRate = _dividendRate;
    altarCut = _altarCut;
    store.cut = _storeCut;
    devCut = _devCut;

    emit SetDistribution(_dividendRate, _altarCut, _storeCut, _devCut);
  }

  function setCooldownTime(uint256 _cooldownTime) public onlyCommittee {
    cooldownTime = _cooldownTime;

    emit SetCooldownTime(_cooldownTime);
  }

  function setDeveloper(address _developer) public onlyCommittee {
    require(_developer != address(0));
    withdrawDevFee();
    developer = _developer;

    emit SetDeveloper(_developer);
  }

  function setCommittee(address _committee) public onlyCommittee {
    require(_committee != address(0));
    committee = _committee;

    emit SetCommittee(_committee);
  }

  function withdrawDevFee() public {
    ethBalance[developer] = ethBalance[developer].add(devFee);
    delete devFee;
  }

  /* MODIFIER */

  modifier onlyCommittee {
    require(msg.sender == committee);
    _;
  }

}

/**
 * @title ChickenHunt
 * @author M.H. Kang
 */
contract ChickenHunt is CHCommittee {

  /* EVENT */

  event Join(address _user);

  /* CONSTRUCTOR */

  constructor() public {
    committee = msg.sender;
    developer = msg.sender;
  }

  /* FUNCTION */

  function init(address _chickenTokenDelegator) external onlyCommittee {
    require(chickenTokenDelegator == address(0));
    chickenTokenDelegator = _chickenTokenDelegator;
    genesis = 1525791600;
    join();
    store.owner = msg.sender;
    store.cost = 0.1 ether;
    setConfiguration(100, 0.00001 ether, 99, 100000, 0.001 ether, 9);
    setDistribution(20, 75, 1, 4);
    setCooldownTime(600);
    setDepot(0.05 ether, 10);
    addItem(5, 5, 0, 0.01 ether);
    addItem(0, 0, 5, 0.01 ether);
    addPet(1000, 0, 0, 100000, 0.002 ether, 9);
    addPet(0, 1000, 0, 100000, 0.002 ether, 9);
    addPet(0, 0, 1000, 202500, 0.00285 ether, 9);
  }

  function withdraw() external {
    uint256 _ether = ethBalance[msg.sender];
    delete ethBalance[msg.sender];
    msg.sender.transfer(_ether);
  }

  function join() public {
    House storage _house = houses[msg.sender];
    require(lastSaveTime[msg.sender] == 0);
    _house.hunter = Hunter(1, 1);
    _house.barrier = Barrier(1, 1);
    _house.depots = 1;
    _house.huntingPower = 10;
    _house.offensePower = 10;
    _house.defensePower = 110;
    _house.huntingMultiplier = 10;
    _house.offenseMultiplier = 10;
    _house.defenseMultiplier = 10;
    lastSaveTime[msg.sender] = block.timestamp;

    emit Join(msg.sender);
  }

  function detailsOf(address _user) public view
    returns (
      uint256 _huntingPower,
      uint256 _offensePower,
      uint256 _defensePower,
      uint256 _huntingMultiplier,
      uint256 _offenseMultiplier,
      uint256 _defenseMultiplier,
      uint256 _depots,
      uint256 _savedChicken,
      uint256 _lastSaveTime,
      uint256 _cooldown
    )
  {
    House memory _house = houses[_user];

    _huntingPower = _house.huntingPower;
    _offensePower =  _house.offensePower;
    _defensePower = _house.defensePower;
    _huntingMultiplier = _house.huntingMultiplier;
    _offenseMultiplier = _house.offenseMultiplier;
    _defenseMultiplier = _house.defenseMultiplier;
    _depots = _house.depots;
    _savedChicken = savedChickenOf[_user];
    _lastSaveTime = lastSaveTime[_user];
    _cooldown = attackCooldown[_user];
  }

  function houseStatsOf(address _user) public view
    returns (
      uint256 _strength,
      uint256 _dexterity,
      uint256 _structure,
      uint256 _material,
      uint256[] _pets
    )
  {
    House memory _house = houses[_user];

    _strength = _house.hunter.strength;
    _dexterity = _house.hunter.dexterity;
    _structure = _house.barrier.structure;
    _material = _house.barrier.material;
    _pets = petsOf[_user];
  }

}