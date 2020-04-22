
const truffleAssert = require("truffle-assertions");
const tokenRegistry = artifacts.require("./dxTokenRegistry.sol");

contract("dxTokenRegistry", async (accounts) => {
    let __contract;
    const __owner = accounts[0];
    const __user1 = accounts[1];
    const __tokenAddr1 = '0x5eF09cc3e4E63F9d37F1dc57b3FC6e6180178794'
    const __tokenAddr2 = '0x47769354ACC9efac989dc5B93e652960aF534bb7'
    const __tokenAddr3 = '0x0500f8C8AAD954936b86c06AFBa5D4e27b806352'

  before(async () => {
      __contract = await tokenRegistry.deployed();
      __contractAddress = __contract.address;
  });

  it("should set deployer as owner", async function() {
    const _result = await __contract.owner();
    assert.strictEqual(_result, __owner, "Owner is not deployer");
  });
  
  it("should not allow non-admins to add lists", async function() {
    __listName = 'testList';
    await truffleAssert.reverts(
      __contract.addList(__listName, {
        from: __user1
      }),
        "Ownable: caller is not the owner"
    );
  });
  
  it("should allow admins to add lists", async function() {
    __listName = 'testList';
    __listId = 1;

    const listCountBefore = await __contract.listCount();
    let tx = await __contract.addList(__listName, { from: __owner });
    truffleAssert.eventEmitted(tx, 'AddList', (ev) => {
        return ev.listId.toNumber() === __listId && ev.listName === __listName;
    });
    const listCountAfter = await __contract.listCount();
    assert.equal(listCountAfter.toNumber(), listCountBefore.toNumber() +1);


  });

  it("should not allow non-admins to add tokens", async function() {
    __listId = 1;
    await truffleAssert.reverts(
      __contract.addTokens(__listId, [__tokenAddr1], {
        from: __user1
      }),
        "Ownable: caller is not the owner"
    );
  });

  it("should allow admins to add tokens", async function() {
    __tokenAddresses = [__tokenAddr1,__tokenAddr2];
    __listId = 1;

    assert.isFalse(await __contract.isTokenActive.call(__listId,__tokenAddr1));
    const tx = await __contract.addTokens(__listId, __tokenAddresses, { from: __owner });
    assert.isTrue(await __contract.isTokenActive.call(__listId,__tokenAddr1));

    truffleAssert.eventEmitted(tx, 'AddToken', (ev) => {
      return ev.listId.toNumber() === __listId && ev.token === __tokenAddr1;
    });

    truffleAssert.eventEmitted(tx, 'AddToken', (ev) => {
      return ev.listId.toNumber() === __listId && ev.token === __tokenAddr2;
    });

  });

  it("should revert duplicate tokens", async function() {
    __listId = 1;
    const tx = await __contract.addTokens(__listId, [__tokenAddr3], { from: __owner });
    
    await truffleAssert.reverts(
      __contract.addTokens(__listId, [__tokenAddr3], {
        from: __owner
      }),
        "DXTokenRegistry : DUPLICATE_TOKEN"
    );

  });

  it("should revert invalid listId", async function() {
    __listId = 50;
    
    await truffleAssert.reverts(
      __contract.addTokens(__listId, [__tokenAddr3], {
        from: __owner
      }),
        "DXTokenRegistry : INVALID_LIST"
    );

  });

  it("should remove tokens", async function() {
    __listId = 1;
    const tcrs_before = await __contract.tcrs.call(__listId);
    tokenCount_before = tcrs_before.activeTokenCount.toNumber();
    const tx = await __contract.removeTokens(__listId, [__tokenAddr2], { from: __owner });
    const tcrs_after = await __contract.tcrs.call(__listId);
    tokenCount_after = tcrs_after.activeTokenCount.toNumber();

    assert.equal(tokenCount_before-1, tokenCount_after);

    truffleAssert.eventEmitted(tx, 'RemoveToken', (ev) => {
        return ev.listId.toNumber() === __listId && ev.token === __tokenAddr2;
    });

    assert.isFalse(await __contract.isTokenActive.call(__listId,__tokenAddr2));

  });

  it("should revert transaction when trying to remove inactive tokens", async function() {
    __listId = 1;

    await truffleAssert.reverts(
      __contract.removeTokens(__listId, [__tokenAddr2], {
        from: __owner
      }),
        "DXTokenRegistry : INACTIVE_TOKEN"
    );

  });

  it("should transfer ownership", async function() {
    __listId = 1;

    assert.equal(await __contract.owner(), __owner);
    const tx = await __contract.transferOwnership(__user1, { from: __owner });
    assert.equal(await __contract.owner(), __user1);

  });

});



