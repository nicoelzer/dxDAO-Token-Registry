pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

interface ERC20Interface {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function balanceOf(address _owner) external view returns (uint256 balance);
}

interface ERC20BytesInterface {
  function name() external view returns (bytes32);
  function symbol() external view returns (bytes32);
}

contract mixTokenRegistry is Ownable{

    /** @dev Mapping of tokens to status */
    mapping (address => bool) public authorisedStatus;

    /** @dev Array of authorised tokens */
    address[] public authorisedTokens;
    
    /** @dev Event emitted when a new token was added */
    event AddNewToken(address newToken);
    
    /** @dev Event emitted when a token was removed */
    event RemoveToken(address token);

    /** @dev Owner facing function used to add new token(s)
      * @param _tokens address of token(s) to add
      * Emits an {AddNewToken} event.
      */
    function addNewTokens(address[] memory _tokens) public onlyOwner {
        for (uint32 i = 0; i < _tokens.length; i++) {
            authorisedStatus[_tokens[i]] = true;
            authorisedTokens.push(_tokens[i]);
            emit AddNewToken(_tokens[i]);
        }
    }

    /** @dev Owner facing function used to remove token(s)
      * @param _tokens address of token(s) to remove
      * Emits an {RemoveToken} event.
      */
    function removeTokens(address[] memory _tokens) public onlyOwner {
        for (uint32 i = 0; i < _tokens.length; i++) {
            require(authorisedStatus[_tokens[i]] == true, "token already removed");
            authorisedStatus[_tokens[i]] = false;
            emit RemoveToken(_tokens[i]);
        }
    }

    /** @dev Function that returns an array of active tokens.
      * @return an array of active token addresses
      */
    function getAvailableTokens() public view returns(address[] memory tokens) {
        tokens = new address[](authorisedTokens.length);

        for (uint32 i = 0; i < authorisedTokens.length; i++) {
            if (authorisedStatus[authorisedTokens[i]]) {
                tokens[i] = authorisedTokens[i];
            } else {
                tokens[i] = address(0);
            }
        }
    }

    /** @dev Function that takes byte32 and returns string value
      * @param x value in bytes32
      * @return value in string
      */
    function bytes32ToString(bytes32 x) private pure returns (string memory) {
      bytes memory bytesString = new bytes(32);
      uint charCount = 0;
      for (uint j = 0; j < 32; j++) {
        byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
        if (char != 0) {
          bytesString[charCount] = char;
          charCount++;
        }
      }
      bytes memory bytesStringTrimmed = new bytes(charCount);
      for (uint32 j = 0; j < charCount; j++) {
        bytesStringTrimmed[j] = bytesString[j];
      }
      return string(bytesStringTrimmed);
    }

    /** @dev Function that return the Name for a given token
      * @param tokenAddress address of the token to query
      * @return string of the tokenName
      */
    function getTokenName(address tokenAddress) private view returns (string memory){
      // check if bytes32 call returns correctly
      string memory name = bytes32ToString(ERC20BytesInterface(tokenAddress).name());
      bytes memory nameBytes = bytes(name);
      if(nameBytes.length <= 1){
        name = ERC20Interface(tokenAddress).name();
      }
      return name;
    }

    /** @dev Function that return the Symbol for a given token
      * @param tokenAddress address of the token to query
      * @return string of the tokenSymbol
      */
    function getTokenSymbol(address tokenAddress) private view returns (string memory){
      // check if bytes32 call returns correctly
      string memory symbol = bytes32ToString(ERC20BytesInterface(tokenAddress).symbol());
      bytes memory symbolBytes = bytes(symbol);
      if(symbolBytes.length <= 1){
        symbol = ERC20Interface(tokenAddress).symbol();
      }
      return symbol;
    }

    /** @dev Function that return the Name, Symbol and Decimals for a given token(s)
      * @param _tokens address of the token to query
      * @return Array of the token name, symbol and decimals for queried token(s)
      */
    function getTokenData(address[] memory _tokens) public view returns (
      string[] memory names, string[] memory symbols, uint[] memory decimals
      ) {
      names = new string[](_tokens.length);
      symbols = new string[](_tokens.length);
      decimals = new uint[](_tokens.length);
      for (uint32 i = 0; i < _tokens.length; i++) {
        names[i] = getTokenName(_tokens[i]);
        symbols[i] = getTokenSymbol(_tokens[i]);
        decimals[i] = ERC20Interface(_tokens[i]).decimals();
      }
    }

}