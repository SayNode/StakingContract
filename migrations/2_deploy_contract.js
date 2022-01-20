const staking  = artifacts.require("stakingRewards");

module.exports = function(deployer) {
  deployer.deploy(staking, "0x0867dd816763BB18e3B1838D8a69e366736e87a1", 240);
};