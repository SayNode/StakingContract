
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;



contract StakingRewards {
    ERC20 public stakingToken;


    uint public _poolSize; //all stakes together
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
        uint reward; // reward in promille
        uint start; // start of reward period
        uint end; // end of reward period
    }

    Stake[] public stakes;
    Reward[] public rewards;
   

    constructor(address _stakingToken) {
        stakingToken = ERC20(_stakingToken);
        owner = msg.sender;
        rewards.push(Reward(uint(100), uint(block.timestamp), uint(0))); //set first reward rate as 100
    }

    modifier _ownerOnly(){
      require(msg.sender == owner);
      _;
    }

    //function to deposit funds to the contract. Funds are used to pay the staking rewards
    function ownerDeposit(uint _amount) external _ownerOnly{
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        contractBalance += _amount;
    }

    //function to withdraw from the Contract
    function ownerWithdraw(uint _amount) external _ownerOnly{
        stakingToken.transfer(msg.sender, _amount);
        contractBalance -= _amount;
    }

    //function to create an individual stake
    function stake(uint _amount) external returns(uint) {
        require(_amount > 0, 'Nothing to stake'); //check that you stake something

        bool isTransfered = stakingToken.transferFrom(msg.sender, address(this), _amount);

        require(isTransfered == true, "Error while transfer"); // breaks if an error occoured during transfer

        _poolSize += _amount;
        stakes.push(Stake(msg.sender, _amount, uint(block.timestamp), uint(block.timestamp), 0));
        return stakes.length;
                
    }

    //function to withdraw your funds
    function unstake (uint _id) external  {
        require(stakes[_id].user == msg.sender, 'Not your stake'); //check if its your stake
        require(stakes[_id].amount > 0, 'Nothing to unstake');

        stakes[_id].untilBlock = uint(block.timestamp); // sets the end of the stake to calculate the correct reward.
        
        calculateReward(_id); // Calculate Reward of the Stake
        uint _amount;

        if(contractBalance < stakes[_id].reward){ // if there is not enough balance to pay the reward, just pay the stake back. Prevent locked funds.
            _amount = stakes[_id].amount;
        }

        else{
            _amount = stakes[_id].amount + stakes[_id].reward; //add reward to the payout amount
            contractBalance -= stakes[_id].reward; // reduce the contractBalance by the amount of the Reward
            stakes[_id].reward =0; // empty the reward

        }

        _poolSize-= stakes[_id].amount; 
        stakes[_id].amount= 0;
        stakingToken.transfer(msg.sender, _amount); //transfer the payout
        
        
    }

    function claimReward(uint _id) external {
         require(stakes[_id].user == msg.sender, 'Not your reward');
         require(stakes[_id].reward <= contractBalance, 'Not enough funds to payout' );
         require(stakes[_id].reward > 0, 'Nothing to payout' );
         require(stakes[_id].amount == 0, 'Use unstake' );

         
         uint _amount= stakes[_id].reward;
         stakes[_id].reward = 0; //empty rewards.
         stakingToken.transfer(msg.sender, _amount ); //transfer the payout
         contractBalance -= _amount; // reduce the contract balance 
         
      
    }

    //function to calculate the reward of each individual stake
    function calculateReward(uint _id) internal {
        stakes[_id].reward = 0; //set reward to 0 to prevent adding it everytime
        uint end;
        uint divisor = 31536000000; // 24*60*60(Days) * 365(year) * 1000 (promille)

        end = stakes[_id].untilBlock;
        
         for (uint i=0; i<rewards.length; i++){
             
            if ((rewards[i].start <= stakes[_id].sinceBlock)  && (rewards[i].end == 0)){
                stakes[_id].reward +=((end - stakes[_id].sinceBlock) * rewards[i].reward * stakes[_id].amount)/divisor; // if staking starts and ends without reward change
            }

            else if((rewards[i].start <= stakes[_id].sinceBlock) && (rewards[i].end >= stakes[_id].sinceBlock) && (rewards[i].end != 0)){
                uint endOfBlock;
                
                if(rewards[i].end >= stakes[_id].untilBlock){
                    endOfBlock = stakes[_id].untilBlock;
                }
                else{
                    endOfBlock = rewards[i].end;
                }

                stakes[_id].reward += ((endOfBlock - stakes[_id].sinceBlock) * rewards[i].reward * stakes[_id].amount)/divisor; //first reward rate of the stake
            }

            else if ((rewards[i].start >= stakes[_id].sinceBlock) && (rewards[i].end <= end) && (rewards[i].end != 0)  ){
                stakes[_id].reward += ((rewards[i].end - rewards[i].start) * rewards[i].reward * stakes[_id].amount)/divisor; //reward rate during staking
            }

            else if ((rewards[i].start <= end) && (rewards[i].start >= stakes[_id].sinceBlock)){
                stakes[_id].reward += ((end - rewards[i].start) * rewards[i].reward * stakes[_id].amount)/divisor; //last reward rate of the stake
            }

        }


    }

    //function to set reward rate for current timeperiod
    function setRewardRate(uint rate) public _ownerOnly {    
        rewards.push(Reward(rate, uint(block.timestamp), uint(0))); // last reward rate has 0 as end as identifier. 
        if(rewards.length>1){
            rewards[rewards.length -2].end = uint(block.timestamp); //set end of the previous reward rate to actual time
        }
        
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
