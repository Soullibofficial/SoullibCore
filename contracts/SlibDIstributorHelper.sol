// SPDX-License-Identifier: MIT

pragma solidity  0.8.4;

import "./Token.sol";
import { Pausable }  from "./utils/Ownable.sol";
import "./IERC20.sol";
import "./utils/SafeMath.sol";
import "./utils/SafeCast.sol";
import "./utils/SafeBEP20.sol";


//                                          SOULLIB ...90% /\/\

//   INTERACTIONS BETWEEN MAJOR PARTIES: CALLER 
//   AND CALL RECEIVER. THE TERM SOULLIBEE   IS 
//   REFERRED TO AS CALL ROUTER WHILE SOULLIBER 
//   CALL RECEIVER. 
//   IT  MODELS  A  
//   BUSI     NESS 
//   RELATION SHIP  
//   DERIVED  FROM THE SERVICE  RENDERED BY THE
//   SOULLIBER TO THE  CALLER. A FEE IS CHARGED
//   AGAINST   THE    CALLER's ACCOUNT IN "SLIB 
//                              TOKEN" WHICH IS 
//                              REGISTERED   IN
//                              FAVOUR  OF SOME
//                              BENEFI  CIARIES
//   THUS  :   SOULLIBER : The caller receiver.
//   SOULLIB :            The soullib platform.
//   REFEREE :    One who referred a soulliber.
//   UPLINE: Organisation the Soullib works for
//                              STAKER : Anyone  who  have staked SLIB 
//                              Token  up   to   the    minimum   stakers
//                              requirement BOARD : Anyone who   have staked
//                              SLIB      Token                  up  to    the
//                              minimum boards'                  requirement AT
//                              EVERY CALL MADE                  A FEE IS CHARGED                     
//                              REGARDED     AS                  REVENUE. REVENU E
//                              GENERATED   FOR EACH  CATEGORY  IS  TRACKED.WHEN A  
//                              SOULLIBEE ROUTES A CALL: WE INSTANTLY  DISTRIBUTE   
//                              THE  INCOME  AMONGST: SOULLIBER,  UPLINE,  SOULLIB   
//                              REFEREE THE REST                  IS CHARGED  TO  A
//                              LEDGER KEPT TO A                  PARTICULAR  PERIOD
//                              AFTER WHICH WILL                  BE   UNLOCKED   AND 
//                              ANYONE   IN THE                   STAKER   AND, BOARD
//                              CATEGORIES CAN ONLY CLAIM THEREAFTER THIS IS BECAUSE
//                              THE   NUMBER   OF   THE STAKERS AND BOARD MEMBERS 
//                              CANNOT BE DETERMINED AT THE POINT A CALL ROUTED

//                                                                                      HAPPY READING
//                                                                                      COPYRIGHT : SOULLIB
//                                                                                      DEV: BOBEU https://github.com/bobeu

contract SlibDistributorHelper is Pausable {
  using SafeMath for uint256;

  ///@dev emits notificatio when a call is routed from @param to to @param from
  event CallSent(address indexed to, address indexed from);

  ///@dev Emits event when @param staker staked an @param amount
  event Staked(address indexed staker, uint256 amount);

  ///@dev Emits event when @param staker unstakes an @param amount
  event Unstaked(address indexed staker, uint256 amount);

  ///@dev Emits event when @param user claims an @param amount
  event Claimed(address indexed user, uint256 amount);

  ///@dev Emits event when @param newSignUp is added by an @param upline
  event SignedUp(address indexed newSignUp, address indexed upline);

  ///@dev Emits event when @param upline removed @param soulliber
  event Deleted(address indexed upline, address indexed soulliber);

  ///@notice Categories any soulliber can belong to
  enum Categ {
    INDIV,
    PRIV,
    GOV
  }

  //SubCategory
  enum Share {
    SOULLIBEE,
    SOULLIBER,
    UPLINE,
    SOULLIB,
    BOARD,
    STAKER,
    REFEREE
  }

  ///@dev Function selector : Connects with the SLIB Token contract using low level call. 
  bytes4 private constant TOGGLE_SELECTOR = bytes4(keccak256(bytes("toggleBal(address,uint256,uint8)")));

  ///@dev Structure profile data
  struct Prof {
    address upline;
    address referee;
    uint256 lastBalChanged;
    uint64 lastClaimedDate;
    uint256 stake;
    uint[] callIds;
    mapping(address=>bool) canClaimRef;
    mapping(Share=>bool) status;
    Categ cat;
    Share sh;
  }

  ///@dev Global/state data
  struct Revenue {
    uint64 round;
    uint96 withdrawWindow;
    uint64 lastUnlockedDate; //Last time reward was released to the pool
    uint perCallCharge;
    uint totalFeeGeneratedForARound;
    uint id;
    uint stakersShare;
    uint boardShare;
    mapping(Categ=>mapping(uint64 => uint256)) revenue;
    mapping(address=>uint256) shares;
  }

  ///@dev Explicit storage getter
  Revenue private rev;

  /**@dev minimumStake thresholds
  */
  uint256[3] private thresholds;

  ///@dev Tracks the number of Soullibers in each category
  uint256[3] public counter;

  ///@dev SLIB Token address
  address public token;

  ///@dev Router address for governance integration
  address private router;

  ///@dev Tracks the number of time fee revenue was generated 
  uint64 public revenueCounter = 5;

  ///@dev Tracks the number of stakers
  uint64 public stakersCount;

  ///@dev Tracks the number of borad  greater than thresholds[1]
  uint64 public boardCount;

  ///@dev Profiles of all users
  mapping(address => Prof) private profs;

  /**@dev Sharing rates
      */
  mapping(Categ => uint256[7]) private rates;

  ///@dev Ensure "target" is a not already signed up
  modifier isNotSoulliber(address target) {
    require(!isSoulliber(target), "Already signed up");
    _;
  }

  ///@dev Ensure "target" is a already signed up
  modifier isASoulliber(address target) {
    require(isSoulliber(target), "Not a soulliber");
    _;
  }

  ///@dev Ensure "idx" is within acceptable range
  modifier oneOrTwo(uint8 idx) {
    require(idx == 1 || idx == 2, "Out of bound");
    _;
  }

  ///@dev Ensure "idx" is within acceptable range
  modifier lessThan3(uint8 idx) {
    require(idx < 3, "Out of bound");
    _;
  }

  ///@dev Initialize storage and state
  constructor() {}

  /**@dev Fallback
  */
  receive() external payable {
    (bool ss,) = router.call{value: msg.value}("");
    require(ss,"");
  }

  /**@dev Sets sharing rate for each of the categories
  */
  function setRate(uint8 categoryIndex, uint256[7] memory newRates) public onlyAdmin returns (bool) {
    //Perform check
    for (uint8 i = 0; i < newRates.length; i++) {
      require(newRates[i] < 101, "NewRate: 100% max exceed");
    }
    rates[Categ(categoryIndex)] = newRates;
    return true;
  }

  ///@dev Ensures "target" is the zero address
  function _notZero(address target) internal pure {
    require(target != zero(), "Soullib: target is Zero address");
  }

  ///@dev Sets new token address
  function resetTokenAddr(address newToken) public returns(bool) {
    //Perform check
    token = newToken;
    return true;
  }

  /**@dev Soulliber can enquire for callIds of specific index
    @param index -  Position of soullibee in the list of soulliber's callers
  */
  function getCallId(uint64 index) public view isASoulliber(_msgSender()) returns(uint) {
    uint len = profs[_msgSender()].callIds.length;
    //Perform check
    return profs[_msgSender()].callIds[index-1];
  }

  ///@dev Internal: returns zero address
  function zero() internal pure returns(address) {
    return address(0);
  }

  /**@dev View only: Returns target's Category and MemberType
    e.g Categ.INDIV, and Share.SOULLIBEE
  */
  function getUserCategory(address target) public view returns (Categ) {
    return (profs[target].cat);
  }

  /**@dev Public: signs up the caller as a soulliber
          @param referee - optional: Caller can either parse "referee" or not
            This is an address that referred the caller.
            Note: Caller cannot add themselves as the referee
            Caller must not have signed up before now
      */
  function individualSoulliberSignUp(address referee) public whenNotPaused isNotSoulliber(_msgSender()) returns (bool) {
    if (referee == zero()) {
      referee = router;
    }
   //Perform check
    profs[_msgSender()].referee = referee;
    profs[_msgSender()].status[Share.SOULLIBER] = true;
    _complete(Categ.INDIV, _msgSender(), zero(), Share(1));

    return true;
  }

  ///@dev Completes signup for "target"
  function _complete(
    Categ cat,
    address target,
    address upline,
    Share sh) internal {
      profs[target].cat = Categ(cat);
      _setStatus(target, Share.SOULLIBER, true);
      profs[target].sh = sh;
      uint256 count = counter[uint8(Categ(cat))];
      counter[uint8(Categ(cat))] = count + 1;

      emit SignedUp(target, upline);
  }

  ///@dev Returns true if @param target is soulliber and false if otherwise
  function isSoulliber(address target) public view returns (bool) {
    return profs[target].status[Share.SOULLIBER];
  }

  ///@dev Returns true if @param target is soullibee and false if otherwise
  function isSoullibee(address target) public view returns (bool) {
    return profs[target].status[Share.SOULLIBEE];
  }

  /**@dev Private or Governmental organizations can sign up as a 
    @param newAddress as soulliber to their profile
    @param _choseCategory - Position index in the category caller belongs to
    Note: _choseCategory should be either 1 or 2
            1 ==> Private organization.
            2 ==> Government.
    NOTE: _cat can only be between 0 and 3 but exclude 0. This because the default
            category "INDIV" cannot be upgraded to.
  */
  function addASoulliberToProfile(uint8 _choseCategory, address newAddress) public whenNotPaused oneOrTwo(_choseCategory) isNotSoulliber(newAddress) returns (bool) {
    //Perform check
    //Set upline
    _setStatus(newAddress, Share.SOULLIBER, true);
    _setStatus(_msgSender(), Share.UPLINE, true);
    _complete(Categ(_choseCategory), newAddress, _msgSender(), Share(1));

    return true;
  }

  /**@dev Anyone is able to sign up as a Soullibee
    Note: Anyone must not already have signed up before now
  */
  function signUpAsSoullibee() public returns (bool) {
    //Perform check
    _setStatus(_msgSender(), Share.SOULLIBEE, true);
    return true;
  }

  /**@dev Caller is able tp pop out "soulliber" from profile
    NOTE: Only the upline can remove soulliber from account
            and they must have already been added before now
  */
  function removeSoulliberFromProfile(address soulliber) public whenNotPaused isASoulliber(soulliber) returns (bool) {
    _notZero(soulliber);
    address upLine = profs[soulliber].upline;
    //Perform check
    Categ cat = profs[soulliber].cat;
    delete profs[soulliber];

    emit Deleted(upLine, soulliber);
    return true;
  }

  /**@dev Anyone can remove themselves as a soullibee.
    Note: Cafeful should be taken as Anyone deleted themselves can no longer route a call
  */
  function deleteAccountSoullibee() public returns (bool) {
    //Perform check
    delete profs[_msgSender()];
    return true;
  }

  /**@dev This is triggered anytime a call is routed to the soulliber
    @param to - Soulliber address/Call receiver
    @param amount - Fee charged to soullibee for this call
    @param cat - category call receiver belongs to.
    @param ref - referee address if any
      NOTE: Referee can claim reward instantly.
      if "to" i.e call receiver does not have a referee,
      then they must have an upline

      If current time equals the set withdrawal window, then we move the balance in the withdrawable 
      balance to the unclaimed ledge, swapped with the queuing gross balance accumulated for the past {withdrawal window} period.
      Any unclaimed balance is cleared and updated with current.
  */

  function _receiveFeeUpdate(
    address to,
    uint256 amount,
    Categ cat,
    address ref) private {
      uint256[7] memory _rates = rates[cat];
      rev.totalFeeGeneratedForARound += amount;
      rev.shares[ref] += amount.mul(_rates[6]).div(100);
      address upline = profs[to].upline;
      rev.shares[upline] += amount.mul(_rates[3]);

      rev.shares[to] += amount.mul(_rates[1]).div(100);
      rev.shares[address(this)] += amount.mul(_rates[2]).div(100);
      uint64 round = rev.round;
      rev.revenue[cat][round + 1] += amount;
      uint lud = rev.revenue[cat][3];
      if(_now() >= lud.add(rev.withdrawWindow)) {
          uint p = rev.revenue[cat][round + 1]; 
          uint p1 = rev.revenue[cat][round];
          uint p2 = rev.revenue[cat][round + 2];
          rev.revenue[cat][round + 1] = 0;
          (rev.revenue[cat][round], rev.revenue[cat][round + 2]) = (p2, p + p1);
          rev.revenue[cat][3] = SafeCast.toUint64(_now());
          (rev.revenue[cat][revenueCounter], rev.totalFeeGeneratedForARound) = (rev.totalFeeGeneratedForARound, p);
          rev.boardShare = p.mul(_rates[4]).div(100).div(boardCount);

          revenueCounter ++;
      }
      if (rev.lastUnlockedDate == 0) {
          rev.lastUnlockedDate = SafeCast.toUint64(_now());
      }
  }

  /**@dev Sets @param newwindow : Period which Staker and board member can claim withdrawal
    Note: "newWindow should be in days e.g 2 or 10 or any
  */
  function setWithdrawWindow(uint16 newWindow) public onlyOwner returns(bool) {
    //Perform check
    rev.withdrawWindow = newWindow * 1 days;
    return true;
  }

  /** @dev View: Returns past generated fee
      @param round - Past revenueCounter: must not be less than 3 and should be less than 
      or equal to current counter
      @param categoryIndex: From Categ(0, or 1, or 2)
  */
  function getPastGeneratedFee(uint64 round, uint8 categoryIndex) public view lessThan3(categoryIndex) returns(uint) {
    uint cnt = revenueCounter;
    //Perform check
    return rev.revenue[Categ(categoryIndex)][round];
  }

  ///@dev  View: returns call charge , last unlocked date and current total fee generated
  function getFeeLastUnlockedFeeGeneratedForARound() public view returns (uint, uint, uint) {
    return (rev.perCallCharge, rev.lastUnlockedDate, rev.totalFeeGeneratedForARound);
  }

  /**@dev View: returns Gross generated fee for the 
    @param categoryIndex : Position of the category enquiring for
                            i.e INDIV or PRIV or GOVT
                            NOTE: categoryIndex must not be greater than 3
                            i.e should be from 0 to 2 
  */
  function getGrossGeneratedFee(uint8 categoryIndex) public view lessThan3(categoryIndex) returns (uint) {
    return rev.revenue[Categ(categoryIndex)][rev.round];
  }

  /**@dev View: returns Claimable generated fee for the 
    @param categoryIndex : Position of the category enquiring for
                            i.e INDIV or PRIV or GOVT
                            NOTE: categoryIndex must not be greater than 3
                            i.e should be from 0 to 2 
  */
  function getClaimableGeneratedFee(uint8 categoryIndex) public view lessThan3(categoryIndex) returns (uint) {
    return rev.revenue[Categ(categoryIndex)][rev.round];
  }

  /**@dev View: returns unclaimed generated fee for the 
    @param categoryIndex : Position of the category enquiring for
                            i.e INDIV or PRIV or GOVT
                            NOTE: categoryIndex must not be greater than 3
                            i.e should be from 0 to 2 
  */
  function getUnclaimedFee(uint8 categoryIndex) public view onlyAdmin lessThan3(categoryIndex) returns (uint) {
    return rev.revenue[Categ(categoryIndex)][rev.round + 1];
  }

  /**@dev View: returns last time generated fee for "categoryIndex" for released for distribution 
    @param categoryIndex : Position of the category enquiring for
                            i.e INDIV or PRIV or GOVT
                            NOTE: categoryIndex must not be greater than 3
                            i.e should be from 0 to 2 
  */
  function getLastFeeReleasedDate(uint8 categoryIndex) public view onlyAdmin lessThan3(categoryIndex) returns (uint) {
    return rev.revenue[Categ(categoryIndex)][2];
  }


  ///@dev View: Returns current block Unix time stamp
  function _now() internal view returns (uint256) {
    return block.timestamp;
  } 

  function _getStatus(address target) internal view returns(bool, bool, bool, bool, bool, bool) {
    return (
      profs[target].status[Share(0)],
      profs[target].status[Share(1)],
      profs[target].status[Share(2)],
      profs[target].status[Share(6)],
      profs[target].status[Share(5)],
      profs[target].status[Share(4)]
    );
  }

  /**@notice Users in the Categ can claim fee reward if they're eligible
    Note: Referees are extempted
  */

  function claimRewardExemptReferee() public whenNotPaused returns (bool) {
    (, bool isSouliber, bool isUplin,, bool isStaker, bool isBoard) = _getStatus(_msgSender());
    // require(!isSolibee && !isRef, "Ref: Use designated method");
    uint256 shr;
    if (isSouliber || isUplin) {
      shr = rev.shares[_msgSender()];
      rev.shares[_msgSender()] = 0;
    } else {
      //Perform check
      //Perform check
      profs[_msgSender()].lastClaimedDate = SafeCast.toUint64(rev.lastUnlockedDate);
      uint256 lastBalChanged = profs[_msgSender()].lastBalChanged;
      (uint stak, uint bor) = _getThresholds();
      //Perform check
      Categ cat = profs[_msgSender()].cat;
      shr = isStaker ? rev.stakersShare : rev.boardShare;
      rev.revenue[cat][rev.round + 2] -= shr;

    }
    //Perform check
    SafeBEP20.safeTransfer(IERC20(token), _msgSender(), shr);

    emit Claimed(_msgSender(), shr);
    return true;
  }

  ///@dev Only referee can claim using this method
  function claimReferralReward() public returns (bool) {
    (,,, bool isRef,,) = _getStatus(_msgSender());
    //Perform check
    uint256 claim = rev.shares[_msgSender()];
    //Perform check
    rev.shares[_msgSender()] = 0;
    _setStatus(_msgSender(), Share.REFEREE,  false);
    SafeBEP20.safeTransfer(IERC20(token), _msgSender(), claim);

    emit Claimed(_msgSender(), claim);
    return true;
  }

  /**@dev Move unclaimed reward to "to"
      @param to - address to receive balance
      @param index - Which of the unclaimed pool balance from the Category do you want to move?
      Note: Callable only by the owner
  */
  function moveUnclaimedReward(address to, uint8 index) public onlyowner lessThan3(index) returns (bool) {
    uint256 unclaimed = rev.revenue[Categ(index)][rev.round + 2];
    //Perform check
    rev.revenue[Categ(index)][rev.round + 2] = 0;
    address[2] memory _to = [to, router];
    uint sP;
    for(uint8 i = 0; i < _to.length; i++) {
        sP = unclaimed.mul(30).div(100);
        address to_ = _to[i];
        if(to_ == to) {
            sP = unclaimed.mul(70).div(100);
        }
        SafeBEP20.safeTransfer(IERC20(token), to_, sP);
    }

    return true;
  }

  ///@dev View: Returbs the minimum stake for both staker and board members
  function _getThresholds() internal view returns (uint256, uint256) {
    return (thresholds[1], thresholds[2]);
  }

  ///@dev Internal: updates target's PROFILE status
  function _updateState(
    address target,
    uint8 cmd) internal returns (bool) {
      (uint256 staker, uint256 board) = _getThresholds();
      uint256 lastBalChanged = profs[target].lastBalChanged;
      uint curStake = _stakes(target);
      if(cmd == 0) {
        if(curStake >= board) {
          _setStatus(target, Share.BOARD, true);
        } else if(curStake < board && curStake >= staker) {
          _setStatus(target, Share.STAKER, true);
        } else { 
          _setStatus(target, Share.STAKER, false);
        }

        if(lastBalChanged == 0) {
          profs[target].lastBalChanged = _now();
        }
      } else {
        profs[target].lastBalChanged = _now();
        _setStatus(target, Share.STAKER,  false);
      } 
      return true;
  }

  /**@notice Utility to stake SLIB Token
    Note: Must not be disabled
    Staker's stake balance are tracked hence if an user unstake before the unlocked date, they 
    will lose the reward. They must keep the stake up to a minimum of 30 days
  */
  function stakeSlib(uint256 amount) public whenNotPaused returns (bool) {
    (uint stak, uint bor) = _getThresholds();
    if(!hasStake(_msgSender())) {
      if(amount >= bor) {
        boardCount ++;
      }
      if(amount >= stak && amount < bor){
        stakersCount ++;
      }
    }
    (bool thisSuccess, ) = token.call(abi.encodeWithSelector(TOGGLE_SELECTOR, _msgSender(), amount, 0));
    //Perform check
    profs[_msgSender()].stake = _stakes(_msgSender()).add(amount);
    _updateState(_msgSender(), 0);

    emit Staked(_msgSender(), amount);
    return true;
  }

  /**@notice Utility for to unstake SLIB Token
    Note: Must not be disabled
    Staker's stake balance are tracked hence if an user unstake before the unlocked date, they 
    will lose the reward. They must keep the stake up to a minimum of 30 days
  */
  function unstakeSlib() public whenNotPaused returns (bool) {
      uint256 curStake = _stakes(_msgSender());
      //Perform check
      profs[_msgSender()].stake = 0;
      (bool thisSuccess, ) = token.call(abi.encodeWithSelector(TOGGLE_SELECTOR, _msgSender(), curStake, 1));
      //Perform check
      _updateState(_msgSender(), 1);

      emit Unstaked(_msgSender(), curStake);
      return true;
  }

  //@dev shows if target has stake running or not
  function hasStake(address target) public view returns (bool) {
    return _stakes(target) > 0;
  }

  ///@dev Internal: Returns stake position of @param target
  function _stakes(address target) internal view returns (uint256) {
    return profs[target].stake;
  }

  ///@dev Public: Returns stake position of @param target
  function stakes(address target) public view returns (uint256) {
    return _stakes(target);
  }

  /**@param to - Soullibee routes a call to a specific Soulliber @param "to"
      Performs a safe external low level calls to feeDistributor address
  */
  function routACall(address to) public whenNotPaused isASoulliber(to) returns (bool) {
    //Perform check
    uint256 _fee = rev.perCallCharge;
    address ref = profs[to].referee;
    uint curId = rev.id;
    rev.id = curId + 1;
    profs[to].callIds.push(curId);
    (bool thisSuccess, ) = token.call(abi.encodeWithSelector(TOGGLE_SELECTOR, _msgSender(), _fee, 2));
    //Perform check
    Categ ofClient = profs[to].cat;
    _setStatus(to, Share.REFEREE, true);
    _receiveFeeUpdate(to, _fee, ofClient, ref);
    emit CallSent(to, _msgSender());

    return true;
  }

  ///@dev Internal : Sets @param target 's status to true
  function _setStatus(address target, Share sh, bool stat) internal {
    profs[target].status[sh] = stat;
  }

  ///@dev sets new fee on calls.
  function updateCallCharge(uint256 newPerCallCharge) public onlyAdmin {
    rev.perCallCharge = newPerCallCharge;
  }

  /**@dev sets minimum hold in SLIB for eitherstakers
  */
  function setMinimumHoldForStaker(uint256 amount) public onlyAdmin {
    thresholds[1] = amount;
  }

  /**@dev sets minimum hold in SLIB for either board
  */
  function setMinimumHoldForBoard(uint256 amount) public onlyAdmin {
    thresholds[2] = amount;
  }

  /**@dev sets minimum hold in SLIB for either board or stakers
  */
  function getMinimumHolds() public view returns (uint256, uint256) {
    return (thresholds[1], thresholds[2]);
  }

  ///@notice Returns the total number of members in each "catIndex"
  function getCounterOfEachCategory(uint8 categoryIndex) public view onlyAdmin lessThan3(categoryIndex) returns (uint256) {
    return counter[categoryIndex];
  }

  ///@notice Read only: returns rate for each subcategory in each category
  function getRate(uint8 categoryIndex) public view lessThan3(categoryIndex) returns (uint256[7] memory) {
    return rates[Categ(categoryIndex)];
  }

  ///@dev Emergency withdraw function: Only owner is permitted
  function emergencyWithdraw(address to, uint256 amount) public onlyOwner returns (bool) {
    _notZero(to);
    //Perform check
    (bool success, ) = to.call{ value: amount }("");
    //Perform check
    return true;
  }

  ///@dev Returns current withdrawal window
  function getWIthdrawalWindow() public view returns(uint96) {
    return rev.withdrawWindow;    
  }


}
