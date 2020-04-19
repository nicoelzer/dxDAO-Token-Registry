pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract dxTokenRegistry is Ownable{

    event AddNewList(uint listId, string listName);
    event AddNewToken(uint listId, address newToken);
    event RemoveToken(uint listId, address token);

    struct tcr {
      uint listId;
      string listName;
      address[] tokens;
      mapping(address => uint) tokenIndex;
      uint activeTokenCount;
    }

    mapping (uint => tcr) public tcrs;
    uint public listCount;

    function addNewList(string memory _listName) public onlyOwner returns(uint) {
      listCount++;
      tcrs[listCount].listId =listCount;
      tcrs[listCount].listName =_listName;
      tcrs[listCount].tokens.push(address(0));
      tcrs[listCount].activeTokenCount = 0;
      emit AddNewList(listCount,_listName);
      return listCount;
    }

    function addNewTokens(uint _listId, address[] memory _tokens) public onlyOwner {
      for (uint32 i = 0; i < _tokens.length; i++) {
        require(tcrs[_listId].tokenIndex[_tokens[i]] == 0, 'dxTokenRegistry : DUPLICATE_TOKEN');
        tcrs[_listId].tokens.push(_tokens[i]);
        tcrs[_listId].tokenIndex[_tokens[i]] = _tokens.length;
        tcrs[_listId].activeTokenCount++;
        emit AddNewToken(_listId, _tokens[i]);
      }
    }

    function removeTokens(uint _listId, address[] memory _tokens) public onlyOwner {
      for (uint32 i = 0; i < _tokens.length; i++) {
        require(tcrs[_listId].tokenIndex[_tokens[i]] != 0, 'dxTokenRegistry : INACTIVE_TOKEN');
        tcrs[_listId].tokenIndex[_tokens[i]] = 0;
        tcrs[_listId].activeTokenCount--;
        emit RemoveToken(_listId, _tokens[i]);
      }
    }

    function getTokens(uint _listId) public view returns(address[] memory activeTokens){
      activeTokens = new address[](tcrs[_listId].activeTokenCount);
      uint32 activeCount = 0;
      for (uint256 i = 0; i < tcrs[_listId].tokens.length; i++) {
        if (tcrs[_listId].tokenIndex[tcrs[_listId].tokens[i]] != 0) {
            activeTokens[activeCount] = tcrs[_listId].tokens[i];
            activeCount++;
        }
      }
    }

    function getTokensRange(uint _listId, uint256 _start, uint256 _end) public view returns(address[] memory tokensRange){
      require(_start <= tcrs[_listId].tokens.length && _end < tcrs[_listId].tokens.length, 'dxTokenRegistry: INVALID_RANGE');
      _end += 1;
      tokensRange = new address[](_end - _start);
      uint32 activeCount = 0;
      for (uint256 i = _start; i < _end; i++) {
         if (tcrs[_listId].tokenIndex[tcrs[_listId].tokens[i]] != 0) {
           tokensRange[activeCount] = tcrs[_listId].tokens[i];
          } else {
            tokensRange[activeCount] = address(0);
          }
        activeCount++;
      }
    }

    function activeToken(uint _listId,address _token) public view returns (bool) {
      return tcrs[_listId].tokenIndex[_token] != 0 ? true : false;
    }

    function getTokenData(address[] memory _tokens) public view returns (
      string[] memory names, string[] memory symbols, uint[] memory decimals
      ) {
      names = new string[](_tokens.length);
      symbols = new string[](_tokens.length);
      decimals = new uint[](_tokens.length);
      for (uint32 i = 0; i < _tokens.length; i++) {
        names[i] = ERC20(_tokens[i]).name();
        symbols[i] = ERC20(_tokens[i]).symbol();
        decimals[i] = ERC20(_tokens[i]).decimals();
      }
    }

    function getExternalBalances(address trader, address[] memory assetAddresses) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](assetAddresses.length);
        for (uint i = 0; i < assetAddresses.length; i++) {
            balances[i] = ERC20(assetAddresses[i]).balanceOf(trader);
        }
        return balances;
    }

}