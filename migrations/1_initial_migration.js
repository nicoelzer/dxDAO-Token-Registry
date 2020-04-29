const Migrations = artifacts.require("Migrations");
const DxTokenRegistry = artifacts.require("DXTokenRegistry");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(DxTokenRegistry);
};
