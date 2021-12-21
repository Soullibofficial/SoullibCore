// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Token.sol";

contract SlibToken is Token {
  constructor(address to) Token("SLIB Token", "SLIB", 10_000_000_000, to) {}
  receive() external payable {}

  function burn(uint amount) public returns(bool) {
    _burn(_msgSender(), amount);
    return true;
  }
}
