
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



contract StakingRewards {
    ERC20 public stakingToken;


    uint public _poolSize;
    uint public _lockingPeriod;
    uint public contractBalance;
    
    address private owner;

    struct Stake {
        address user;
        uint amount;
        uint sinceBlock;
        uint untilBlock;   
        uint reward;
         }

    struct Reward{
        uint reward;
        uint start;
        uint end;
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
        stakes.push(Stake(msg.sender, _amount, uint(block.timestamp), uint(block.timestamp + _lockingPeriod ), 0));
        
    }


    function unstake (uint _id) external {
        require(stakes[_id].user == msg.sender, 'Not your stake');
        require(stakes[_id].amount > 0, 'Nothing to unstake');
        require(stakes[_id].untilBlock < uint(block.timestamp), 'To early');

        uint _amount = stakes[_id].amount;
        stakes[_id].untilBlock= uint(block.timestamp);

        calculateReward(_id); // Calculate Reward of the Stake

        stakes[_id].amount= 0;
        _poolSize-= _amount;
        
        stakingToken.transfer(msg.sender, _amount);
        getReward(_id);
        
    }

    function calculateReward(uint _id) public {
        stakes[_id].reward =0;
        uint end;

        
        if(stakes[_id].untilBlock> uint(block.timestamp)){
            end = uint(block.timestamp);
        }
        else{
            end = stakes[_id].untilBlock;
        }
        
         for (uint i=0; i<rewards.length; i++){
             
            if ((rewards[i].start < stakes[_id].sinceBlock)  && (rewards[i].end == 0)){
                stakes[_id].reward += (end - stakes[_id].sinceBlock) * rewards[i].reward * stakes[_id].amount; // if staking starts and ends without reward change
            }

            else if((rewards[i].start < stakes[_id].sinceBlock) && (rewards[i].end > stakes[_id].sinceBlock) && (rewards[i].end != 0)){
                stakes[_id].reward += (rewards[i].end - stakes[_id].sinceBlock) * rewards[i].reward * stakes[_id].amount; //first feward rate
            }

            else if ((rewards[i].start > stakes[_id].sinceBlock) && (rewards[i].end < end) && (rewards[i].end != 0)  ){
                stakes[_id].reward += (rewards[i].end - rewards[i].start) * rewards[i].reward * stakes[_id].amount; //reward rate during staking
            }

            else if ((rewards[i].start < end) && (rewards[i].start > stakes[_id].sinceBlock)  && (rewards[i].end == 0)){
                stakes[_id].reward += (end - rewards[i].start) * rewards[i].reward * stakes[_id].amount; //last reward rate
            }

        }


    }

    function getReward(uint _id) public {

        require(stakes[_id].user == msg.sender, 'Not your reward');
        require(stakes[_id].reward > 0, 'Nothing to unstake');
        require(stakes[_id].reward < contractBalance , 'Not enought balance in contract');

        stakes[_id].reward = 0;
        stakingToken.transfer(msg.sender, stakes[_id].reward);
 
    }

    function setRewardRate(uint rate) public _ownerOnly {
        
        rewards.push(Reward(rate, uint(block.timestamp), uint(0)));
        if(rewards.length>1){
            rewards[rewards.length -2].end = uint(block.timestamp);
        }
        
    }  
    
    function setLockingPeriod(uint lockingPeriod) public _ownerOnly {
        _lockingPeriod = lockingPeriod;
    }

    function untilLockingEnd(uint _id) public view returns(uint) {
        return stakes[_id].untilBlock - uint(block.timestamp);
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
