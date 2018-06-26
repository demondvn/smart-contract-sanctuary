pragma solidity 0.4.24;

contract MainCon {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function doSomething() external {
        emit SomethingDone(address(this));
    }

    event SomethingDone(address _addr);
}

contract SubCon {
    address public owner;

    MainCon xyz_;

    constructor(MainCon _xyz) public {
        xyz_ = _xyz;
        owner = msg.sender;
    }

    function interactWithXYZ() external {
        xyz_.doSomething();
    }
}