
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



contract StakingRewards {
    ERC20 public stakingToken;

    uint public rewardPercentage;
    uint public _poolSize;
    uint public _lockingPeriod;
    uint public contractBalance;
    uint public rewardPeriod;
    
    address private owner;

    struct Stake {
        address user;
        uint256 amount;
        uint64 sinceBlock;
        uint64 untilBlock;   
        uint reward;
         }

    struct Reward{
        uint reward;
        uint64 start;
        uint64 end;
    }

    Stake[] public stakes;
    Reward[] public rewards;
   

    constructor(address _stakingToken) {
        stakingToken = ERC20(_stakingToken);
        owner = msg.sender;
    }

    modifier _ownerOnly(){
      require(msg.sender == owner);
      _;
    }

    function ownerDeposit(uint _amount) public _ownerOnly{
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        contractBalance += _amount;
    }

    function ownerWithdraw(uint _amount) public _ownerOnly{
        stakingToken.transfer(msg.sender, _amount);
        contractBalance -= _amount;
    }

    function stake(uint _amount) external  {
        _poolSize += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakes.push(Stake(msg.sender, _amount, uint64(block.timestamp), uint64(block.timestamp + _lockingPeriod ), 0));
        
    }


    function unstake (uint256 _id) external {
        require(stakes[_id].user == msg.sender, 'Not your stake');
        require(stakes[_id].amount > 0, 'Nothing to unstake');

        uint _amount = stakes[_id].amount;
        stakes[_id].untilBlock= uint64(block.timestamp);

        calculateReward(_id); // Calculate Reward of the Stake

        stakes[_id].amount= 0;
        _poolSize-= _amount;
        
        stakingToken.transfer(msg.sender, _amount);
        
    }

    function calculateReward(uint256 _id) public {
        uint64 end;
        
        if(stakes[_id].untilBlock> uint64(block.timestamp)){
            end =uint64(block.timestamp);
        }
        else{
            end = stakes[_id].untilBlock;
        }

        for (uint i=0; i<=rewards.length; i++){
            if(rewards[i].end > stakes[_id].sinceBlock ){
                stakes[_id].reward = rewards[i].end - stakes[_id].sinceBlock * rewards[i].reward * stakes[_id].amount; // finds the  Start of the staking time
            }

            else if ((rewards[i].start > stakes[_id].sinceBlock) && (rewards[i].end > end) && (rewards[i].end != 0)  ){
                stakes[_id].reward += end - stakes[_id].sinceBlock * rewards[i].reward * stakes[_id].amount; // finds Regions where the reward Rate change during staking
            }

            else if ((rewards[i].start < end&& rewards[i].start > stakes[_id].sinceBlock  )  && (rewards[i].end == 0)){
                stakes[_id].reward += end - rewards[i].start * rewards[i].reward * stakes[_id].amount; // finds the end of the staking time
            }

            else if ((rewards[i].start < stakes[_id].sinceBlock)  && (rewards[i].end == 0)){
                stakes[_id].reward += end - stakes[_id].sinceBlock * rewards[i].reward * stakes[_id].amount; // if the staking was in a period where no changes to the Rewardrate apperared, this will be executed
            }

        }


    }



    function getReward(uint256 _id) external {

        require(stakes[_id].user == msg.sender, 'Not your stake');
        require(stakes[_id].amount == 0, 'Nothing to unstake');

        stakingToken.transfer(msg.sender, stakes[_id].reward);
 
    }


    function setRewardRate(uint rate) public _ownerOnly {
        
        rewards.push(Reward(rate, uint64(block.timestamp), 0));
        rewards[rewards.length -1].end = uint64(block.timestamp);
        
        
    }  
    
    function setLockingPeriod(uint lockingPeriod) public _ownerOnly {
        _lockingPeriod = lockingPeriod;
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
