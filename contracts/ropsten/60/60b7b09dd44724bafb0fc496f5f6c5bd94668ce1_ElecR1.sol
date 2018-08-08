pragma solidity 0.4.24;

contract SELTInterface{
    string public  name;
    uint256 public totalSupply;
    function () public payable;
    function balanceOf(address _owner) constant public returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract ElecR1 {

    SELTInterface SELT;
    // Model a Candidate
    struct Candidate {
        uint8 id;
        string name;
        uint voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store Candidates
    // Fetch Candidate
    mapping(uint8 => Candidate) public candidates;
    // Store Candidates Count
    uint8 public candidatesCount = 0;
    //Store votes Count
    uint public TotalVote;

    string public  TokenName;

    event Voted(address indexed _from, address indexed _to, uint8 votes);

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );
    //check address
    modifier onlyValidAddress(address _to){
        require(_to != address(0x00));
        _;
    }

    modifier onlyValidSenderIsAcceptToken(address _to){
        require(_to != address(SELT));
        _;
    }

    modifier onlyAccept5Vote(uint8 votes){
        require(countBit(votes) == 5);
        _;
    }


    constructor (
        // address _ElecTokenAddress,
        // string _name1,
        // string _name2,
        // string _name3,
        // string _name4,
        // string _name5,
        // string _name6,
        // string _name7
    ) 
    public {
        SELT = SELTInterface(0x883c8197c2c9fd1c11e90ffbac883ac6d4c7f1ed);
        TokenName = SELT.name();
        addCandidate("_name1");
        addCandidate("_name2");
        addCandidate("_name3");
        addCandidate("_name4");
        addCandidate("_name5");
        addCandidate("_name6");
        addCandidate("_name7");
    }

    function countBit(uint8 data) private pure returns (uint8 totalBits){
        data = (data & 0x55) + ((data >> 1) & 0x55);
        data = (data & 0x33) + ((data >> 2) & 0x33);
        data = (data & 0x0F) + ((data >> 4) & 0x0F);
        data = (data & 0x00) + ((data >> 8) & 0x00);
        return data;
    }

    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(uint8(1) << candidatesCount, _name, 0);
    }

    function vote (uint8 _candidateid, address sender) public {
        // require that they haven&#39;t voted before
        require(!voters[sender]);


        // record that voter has voted
        voters[sender] = true;

        // update candidate vote Count
        candidates[_candidateid].voteCount ++;

        // trigger voted event
        emit votedEvent(candidates[_candidateid].id);
    }
    // add onlyValidSenderIsToken
    function receiveApproval(address _from, uint256 _value, address _token, uint8 votes
    )   onlyValidSenderIsAcceptToken(_token)
    onlyAccept5Vote(votes)
    public {
        require(SELT.transferFrom(_from,  this, _value));
        for(uint8 i = 0 ; i < 7; i++){
            if((votes & candidates[i + 1].id) != 0){
                vote(i + 1, _from);
            }
        }
        TotalVote += _value;
        emit Voted(_from, this, votes);
    }

}