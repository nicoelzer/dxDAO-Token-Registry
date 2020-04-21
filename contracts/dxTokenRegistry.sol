pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DXTokenRegistry is Ownable{

    event AddList(uint listId, string listName);
    event AddToken(uint listId, address token);
    event RemoveToken(uint listId, address token);

    enum TokenStatus {NULL,ACTIVE,REMOVED}

    struct TCR {
      uint listId;
      string listName;
      address[] tokens;
      mapping(address => TokenStatus) status;
      uint activeTokenCount;
    }

    mapping (uint => TCR) public tcrs;
    uint public listCount;

    function addList(string memory _listName) public onlyOwner returns(uint) {
      listCount++;
      tcrs[listCount].listId =listCount;
      tcrs[listCount].listName =_listName;
      tcrs[listCount].tokens.push(address(0));
      tcrs[listCount].activeTokenCount = 0;
      emit AddList(listCount,_listName);
      return listCount;
    }

    function addTokens(uint _listId, address[] memory _tokens) public onlyOwner {
      for (uint32 i = 0; i < _tokens.length; i++) {
        require(tcrs[_listId].status[_tokens[i]] != TokenStatus.ACTIVE, 'dxTokenRegistry : DUPLICATE_TOKEN');
        if(tcrs[_listId].status[_tokens[i]] == TokenStatus.REMOVED){
          tcrs[_listId].status[_tokens[i]] = TokenStatus.ACTIVE;
          tcrs[_listId].activeTokenCount++;
        } else {
          tcrs[_listId].tokens.push(_tokens[i]);
          tcrs[_listId].status[_tokens[i]] = TokenStatus.ACTIVE;
          tcrs[_listId].activeTokenCount++;
        }
        emit AddToken(_listId, _tokens[i]);
      }
    }

    function removeTokens(uint _listId, address[] memory _tokens) public onlyOwner {
      for (uint32 i = 0; i < _tokens.length; i++) {
        require(tcrs[_listId].status[_tokens[i]] == TokenStatus.ACTIVE, 'dxTokenRegistry : INACTIVE_TOKEN');
        tcrs[_listId].status[_tokens[i]] = TokenStatus.REMOVED;
        tcrs[_listId].activeTokenCount--;
        emit RemoveToken(_listId, _tokens[i]);
      }
    }

    function getAllTokens(uint _listId) public view returns(address[] memory){
      return tcrs[_listId].tokens;
    }

    function getActiveTokens(uint _listId) public view returns(address[] memory activeTokens){
      activeTokens = new address[](tcrs[_listId].activeTokenCount);
      uint32 activeCount = 0;
      for (uint256 i = 0; i < tcrs[_listId].tokens.length; i++) {
        if (tcrs[_listId].status[tcrs[_listId].tokens[i]] == TokenStatus.ACTIVE) {
          activeTokens[activeCount] = tcrs[_listId].tokens[i];
          activeCount++;
        }
      }
    }

    function getActiveTokensRange(uint _listId, uint256 _start, uint256 _end) public view returns(address[] memory tokensRange){
      require(_start <= tcrs[_listId].tokens.length && _end < tcrs[_listId].tokens.length, 'dxTokenRegistry: INVALID_RANGE');
      tokensRange = new address[](_end - _start +1);
      uint32 activeCount = 0;
      for (uint256 i = _start; i <= _end; i++) {
         if (tcrs[_listId].status[tcrs[_listId].tokens[i]] == TokenStatus.ACTIVE) {
          tokensRange[activeCount] = tcrs[_listId].tokens[i];
          activeCount++;
         }
      }
    }

    function isTokenActive(uint _listId,address _token) public view returns (bool) {
      return tcrs[_listId].status[_token] == TokenStatus.ACTIVE ? true : false;
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