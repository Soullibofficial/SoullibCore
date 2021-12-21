// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    /**@dev Used in dual purpose: admin level 1
     */
    address[2] private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    mapping(address=>bool) private isAdmin;

    constructor () {
        _setOwner(_msgSender(), false);
        isAdmin[_msgSender()] = true;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner[1];
    }

    /**
     * @dev Throws if called by any account other than the owner.
        note: Becareful, the owner weldge much power in the context
         for which they are uses
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: not the owner");
        _;
    
    }

    /**
     * @dev Throws if called by any account other than the owner.
        note: Becareful, the owner weldge much power in the context
         for which they are uses
     */
    modifier onlyowner() {
        require(_msgSender() == _owner[0], "Ownable: not the owner");
        _;
    
    }
    
    /**
     * @dev Throws if called by any account other than the admin.
     */
   modifier onlyAdmin() {
        require(isAdmin[_msgSender()], "Ownable: not an admin");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     * Can still be reinstated.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0), true);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyowner {
        require(newOwner != address(0), "Ownable: zero address");
        _setOwner(newOwner, true);
    }

    function _setOwner(address newOwner, bool ll) private {
        address oldOwner = _owner[1];
        ll? (_owner[1] = newOwner, _owner[0] = _owner[0]) : 
        (_owner[0] = newOwner, _owner[1] = newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**@dev Toggles admin role to true or false.
       @param cmd - Will activate newAdmin else deactivates
       @param newAdmin - New address to add as admin
     */
    function toggleAdminRole(address newAdmin, uint8 cmd) public virtual onlyOwner {
      if(cmd == 0) {
          require(!isAdmin[newAdmin], "Already an admin");
          isAdmin[newAdmin] = true;
      } else {
          require(isAdmin[newAdmin], "Already an admin");
          isAdmin[newAdmin] = false;
      }
    }


    function verifyAdmin(address target) public view returns(bool) {
        return isAdmin[target];
    }

}


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}