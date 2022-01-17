
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



contract StakingRewards {

    ERC20 public stakingToken;

    address private owner;


    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint public contractBalance;
    uint public _poolSize;
    uint public rewardRate;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => uint) public _releaseTime;

    mapping(address => uint) private _balances;

    constructor(address _stakingToken) {
        stakingToken = ERC20(_stakingToken);
        owner = msg.sender;
    }

    modifier _ownerOnly(){
      require(msg.sender == owner);
      _;
    }

    function releaseTime(address account) public view virtual returns (uint256) {
        return _releaseTime[account];
    }

    function untilRelease(address account) public view virtual returns (uint256) {
        return _releaseTime[account]-block.timestamp;
    }

    function ownerDeposit(uint _amount) public _ownerOnly{
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        contractBalance += _amount;
    }

        function ownerWithdraw(uint _amount) public _ownerOnly{
        stakingToken.transfer(msg.sender, _amount);
        contractBalance -= _amount;
    }


    function setRewardRate(uint rate) public _ownerOnly {

        rewardRate = rate;
    }

    function rewardPerToken() public view returns (uint) {
        
        if (contractBalance== 0) {
            return 0;
        }
        if(_poolSize== 0) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _poolSize);
    }

    function earned(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        _releaseTime[msg.sender] = block.timestamp+90*1 days; //lock funds for 90 days
        _poolSize += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(block.timestamp >= releaseTime(msg.sender), "TokenTimelock: current time is before release time");

        _poolSize-= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        require(block.timestamp >= releaseTime(msg.sender), "TokenTimelock: current time is before release time");
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        stakingToken.transfer(msg.sender, reward);
        contractBalance -= reward;
    }
}

interface ERC20 {

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
