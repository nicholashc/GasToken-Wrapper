// contract wrapper to combine aribitray code execution with https://gastoken.io/

pragma solidity ^0.5.0;

contract Gastoken {
	function mint(uint256 value) external;
  function free(uint256 value) external returns (bool success);
  function balanceOf(address owner) external pure returns (uint256 balance);
}

contract GasTokenWrapper {

  address payable public owner;
  //there are two GasToken contracts
  //the first uses overwriting aribitray data with zeros to receive a storage rebate
  //the second uses contract self destructs
  address public GST1 = 0x88d60255F917e3eb94eaE199d827DAd837fac4cB;
  address public GST2 = 0x0000000000b3F879cb30FE243b4Dfee438691c04;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() { 
    require (msg.sender == owner); 
    _; 
  }
  
  //call this function with a low gas price to mint new gas tokens
  //tokens will be held by this contract 
  function mintGasTokens(address _gasToken, uint256 _amount) external onlyOwner {
  	Gastoken g = Gastoken(_gasToken);
  	g.mint(_amount);
  }

  //call this function to free gas tokens and execute some aribitray code where you will be using high gas price
  //_msgData should be the hex encoded function signuature, with zero padded arguments if requried. eg 0xe9fad8ee for exit()
  function burnGasAndExecute(
  	address _gasToken, 
  	uint256 _free, 
  	address _target,
  	bytes memory _msgData
  ) 
  	public 
  	payable
    onlyOwner
  	returns (bool, bytes memory)
  {	
  	Gastoken g = Gastoken(_gasToken);
    require(g.free(_free));
    return _target.call.value(msg.value)(_msgData);
  }

  //withdraw any funds to owner
  function withdraw() external onlyOwner {
    owner.transfer(address(this).balance);
  }

  //returns token balances from the two GST contracts 
  function checkGSTbalance() external view returns(uint256, uint256) {
    Gastoken g1 = Gastoken(GST1);
    Gastoken g2 = Gastoken(GST2);
    return (g1.balanceOf(address(this)), g2.balanceOf(address(this)));
  }

  //fallback
  function() external payable {}
}