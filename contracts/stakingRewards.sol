
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;



contract StakingRewards {
    ERC20 public stakingToken;


    uint public _poolSize; //all stakes together
    uint public _lockingPeriod; // timeperiod in which each individual stake is locked in the contract
    uint public contractBalance; // balance of the contract from which the rewards are payed
    
    address private owner;

    struct Stake {
        address user;
        uint amount;
        uint sinceBlock; // start of staking
        uint untilBlock; // end of staking
        uint reward;
         }

    struct Reward{
        uint reward;
        uint start;
        uint end;
    }

    Stake[] public stakes;
    Reward[] public rewards;
   

    constructor(address _stakingToken, uint lockingPeriod) {
        stakingToken = ERC20(_stakingToken);
        owner = msg.sender;
        _lockingPeriod = lockingPeriod; //* 1 days;
    }

    modifier _ownerOnly(){
      require(msg.sender == owner);
      _;
    }

    //function to deposit funds to the contract. Funds are used to pay the staking rewards
    function ownerDeposit(uint _amount) public _ownerOnly{
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        contractBalance += _amount;
    }

    //function to withdraw from the Contract
    function ownerWithdraw(uint _amount) public _ownerOnly{
        stakingToken.transfer(msg.sender, _amount);
        contractBalance -= _amount;
    }

    //function to create an individual stake
    function stake(uint _amount) public returns(uint) {
        require(_amount > 0, 'Nothing to stake'); //check that you stake something
        _poolSize += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakes.push(Stake(msg.sender, _amount, uint(block.timestamp), uint(block.timestamp + _lockingPeriod ), 0));
        return stakes.length;
    }

    //function to withdraw your funds
    function unstake (uint _id) public  {
        require(stakes[_id].user == msg.sender, 'Not your stake'); //check if its your stake
        require(stakes[_id].amount > 0, 'Nothing to unstake'); //check if something is staked
        require(stakes[_id].untilBlock < uint(block.timestamp), 'Too early'); //check if locking period is over
        
        calculateReward(_id); // Calculate Reward of the Stake
        uint _amount;
        if(contractBalance < stakes[_id].reward){ // if there is not enough balance to pay the reward, just pay the stake back. Prevent locked funds.
            _amount = stakes[_id].amount;
        }
        else{
            _amount = stakes[_id].amount + stakes[_id].reward; //add reward to the payout amount
            stakes[_id].reward =0; // empty the reward

        }
        _poolSize-= stakes[_id].amount; 
        stakes[_id].amount= 0;
        stakingToken.transfer(msg.sender, _amount); //transfer the payout
        
        
    }

    //function to calculate the reward of each individual stake
    function calculateReward(uint _id) public {
        stakes[_id].reward =0; //set reward to 0 to prevent adding it everytime
        uint end;

        if(stakes[_id].untilBlock> uint(block.timestamp)){ //check if locking period is over now. If not, take the actual time to calculate it
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

    //function to set reward rate for current timeperiod
    function setRewardRate(uint rate) public _ownerOnly {    
        rewards.push(Reward(rate, uint(block.timestamp), uint(0)));
        if(rewards.length>1){
            rewards[rewards.length -2].end = uint(block.timestamp);
        }
        
    }  

    //function to check how long your funds are stil locked
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
