
// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/omenTokenRegistry.sol

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;


interface ERC20Interface {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function balanceOf(address _owner) external view returns (uint256 balance);
}

interface ERC20BytesInterface {
  function name() external view returns (bytes32);
  function symbol() external view returns (bytes32);
  function decimals() external view returns (uint8);
  function balanceOf(address _owner) external view returns (uint256 balance);
}

contract omenTokenRegistry is Ownable{

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
