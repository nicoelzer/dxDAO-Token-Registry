var DXTokenRegistry = artifacts.require("./dxTokenRegistry.sol");

module.exports = function(deployer){
  deployer.deploy(DXTokenRegistry);
}