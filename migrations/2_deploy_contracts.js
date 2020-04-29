var DXTokenRegistry = artifacts.require("DXTokenRegistry");

module.exports = function(deployer){
  deployer.deploy(DXTokenRegistry);
};