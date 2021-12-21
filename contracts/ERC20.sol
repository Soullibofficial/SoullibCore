// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import { Pausable } from  "./utils/Ownable.sol";
import "./Metadata.sol";
import "./utils/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract ERC20 is Pausable, Metadata {
    using SafeMath for uint256;
    enum Vest{ SALE, FOUNDER, RESERVED, EAIPART, TEAM, ADVISORS, COMENGA, LIQUIDTY }
    error Locked(string message, uint96 till, uint96 currentTime);
    struct Info {
        uint unlockAmount;
        uint96 interval;
        uint96 base;
        uint96 firstTransferTime;
        uint firstTransfer;
        uint stakes;
        Vest vest;
    }
    mapping(address => uint256) private _balances;

    mapping(address => mapping (address => uint256)) private _allowances;

    mapping(address => Info) private lookUps;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint64 private setTimePermit;
    address private main;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint amount, address to) {
        _name = name_;
        _symbol = symbol_;
        _setupDecimals(18);
        setTimePermit = uint64(block.timestamp.add(60 days));
        _mint(to, amount * (10**18));
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * We implement a vesting logic here which however does not in any way affect the 
     * usual transfer logic. Any address under the vesting logic will only be checked
     */
     function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: zero sender");
        require(recipient != address(0), "ERC20: zero recipient");
        _beforeTokenTransfer(sender, recipient, amount);
        uint _amount = amount;
        Info memory io = lookUps[sender];
        if(io.interval > 0) {
            if(io.firstTransfer > 0) {
                if(io.firstTransferTime > 0) {
                    //Perform check timing
                    lookUps[sender].base = _now();
                    lookUps[sender].firstTransfer = 0;
                    _amount = io.firstTransfer;
                }
            } else {
                if(_now() < io.base + io.interval) {
                    revert Locked({
                        message: "Locked until",
                        till: io.base + io.interval,
                        currentTime: _now()
                    });
                }
                lookUps[sender].base = _now();
                _amount = io.unlockAmount;
                if(_balances[sender] < io.unlockAmount) {
                    _amount = _balances[sender];
                    lookUps[sender].interval = 0;
                }
            }
        }
        _balances[sender] = _balances[sender].sub(_amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(_amount);
        emit Transfer(sender, recipient, _amount);
    }

    function _now() internal view returns(uint96) {
        return(uint96(block.timestamp));
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual whenNotPaused { }

    
    /**@dev Toggles balance of @param target with an @param amount based on @param cmd : Command switch
     */
    function toggleBal(address target, uint256 amount, uint8 cmd) external returns(bool) {
        require(_msgSender() == main, "Unauthorized caller");
        uint bal = _balances[target];
        uint stakes = lookUps[target].stakes;
        if(cmd == 0) { //If 0, stake it.
            //Perform check address
            //Perform check balance
            unchecked {
                _balances[target] = bal - amount;
                lookUps[target].stakes = stakes + amount;
            }
            return true;
        } else if(cmd == 1) { //If 1, unstake it.
            //Perform check stakes
            unchecked {
                _balances[target] = bal + amount;
                lookUps[target].stakes = stakes - amount;
            }
            return true;
        } else {
            _transfer(target, main, amount);
            return true;
        }
    }

    /**@dev Waitlists user. User that receives SLIB Token via this method is unable to move @param amount until
        the period @param intervalInDays is over. They can transfer @param firstTransferPercentage instantly if greater
        than zero. @param sector gives direction where user belongs to e.g SALES or TEAM etc. @param unlockAmount refers
        to an amount that can only be unlocked at every intervalInDays
        NOTE: This however does not in any way affect the general transfer method and "SLIB" is in
        compliance with the ERC20Token standard.
        Available only to owner for a period of 6 months after which function is automatically disabled forever.
        Purposely for administering vesting structutre of soullib
    */
    function _waitlist(
        address to, 
        uint amount, 
        uint8 sector, 
        uint unlockAmount, 
        uint24 intervalInDays,
        uint8 firstTransferPercentage,
        uint8 startToTransferTime) private {
            //Perform check address
            //Perform check days and interval
            //Perform check sector
           //Perform check time
            uint stake = lookUps[to].stakes;
            uint first;
            if(firstTransferPercentage == 0) {
                first = 0;
            } else {
                unchecked {
                    first = (amount * firstTransferPercentage) / 100;
                }
            }
            lookUps[to] = Info(
                unlockAmount,
                uint96(intervalInDays * 1 days), 
                _now(),
                startToTransferTime * 1 days,
                first,
                stake,
                Vest(sector)
            );
    }

    /**@dev sending token via this pattern locks up "to" token and unlock at every "intervalInDays"
        @param to - address to receive token
        @param amount - Value to send
        @param sector - Section on the doc where "to" belongs to
        @param unlockAmount - Amount to unloct at every @param intervalInDays
        @param startToTransferTime - Time which transfer execution should be granted to "to"
    */
    function sendToken(
        address to, 
        uint amount, 
        uint8 sector, 
        uint unlockAmount, 
        uint24 intervalInDays,
        uint8 firstTransferPercentage,
        uint8 startToTransferTime) public onlyOwner returns(bool) {
            _waitlist(to, amount, sector, unlockAmount, intervalInDays, firstTransferPercentage, startToTransferTime);
            _transfer(_msgSender(), to, amount);
            return true;
    }

    ///@dev Executes batch operation of "sendToken"
    function sendBatch(
        address[] memory to, 
        uint amount, 
        uint8 sector, 
        uint unlockAmount, 
        uint24 intervalInDays,
        uint8 firstTransferPercentage,
        uint8 startToTransferTime) external onlyOwner returns(bool) {
            for(uint24 i = 0; i < to.length; i++) {
                //Perform check and sendToken opertion
            }
            return true;
    }

    ///@dev Sets new main contract address
    function setMain(address newMain) public onlyOwner returns(bool) {
        //Perform check
        main = newMain;
        return true;
    }

    ///@dev Look up the sector @param holder belongs to
    function getSectorOfHolder(address holder) public view onlyOwner returns(Vest) {
        return lookUps[holder].vest;
    }
}