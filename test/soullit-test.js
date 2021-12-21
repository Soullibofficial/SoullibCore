
/*
Testing SoullibDistributor - "../build/contract/SlibDistributorHelper.sol"
*/
require("@nomiclabs/hardhat-web3");
const BigNumber = require("bignumber.js");
const {
    expectRevert // Assertions for transactions that should fail
  } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const { expect, assert } = require("chai");
const { artifacts } = require("hardhat");
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants");
const ether = require("@openzeppelin/test-helpers/src/ether");

const SlibDistributorHelper = artifacts.require("SlibDistributorHelper");
const SlibOneFile = artifacts.require("SlibOneFile");

let instance;
let sAddress;
let slib;
let slibAddress;

let acc1;
let acc2;
let acc3;
let acc4;
let acc5;

let balAcc1;
let balAcc2;

let totalSupply;

function bn(arg) {
    const c = new BigNumber(arg);
    return c;
}

var stakeAmt = bn(1e+21);
var msupply = bn(1e+28);
var boardThreshold = bn(5e+24);
var stakerThreshold = bn(2e+22);
var amount = bn(2e+22);

const etherValue = web3.utils.unitMap.ether;

function _format(arg) {
    let b = bn(arg);
    return b.toNumber();
}

const NAME = async () => await slib.name();

const symbol = async () => await slib.symbol();

const decimals = async () => await slib.decimals();

const getCallId  = async (index, from) => await instance.getCallId(index, {from: from});

const getUserCategory  = async (target) => await instance.getUserCategory(target);

const pause = async () => await instance.pause({from: acc1});

const unpause = async () => await instance.unpause({from: acc1});

const signUpAsSoullibee = async (from) => await instance.signUpAsSoullibee({from: from});

const isAdmin = async (target) => await instance.verifyAdmin(target);

const hasStake = async (target) => await instance.hasStake(target);

const isSoulliber = async (target) => await instance.isSoulliber(target);

const isSoullibee = async (target) => await instance.isSoullibee(target);

const toggleAdminRole = async (newAdmin, command) => await instance.toggleAdminRole(newAdmin, command);

const tSupply = async () => bn(await slib.totalSupply());

const transfer = async (from, to, _value) => await slib.transfer(to, _value, {from: from});

const approve = async (amount, from, to) => await slib.approve(to, amount, {from: from});

const balanceOf = async (address) => bn(await slib.balanceOf(address));

const allowance = async (owner, spender) => bn(await slib.allowance(owner, spender));

const stakeSLIB = async (from, value) => await instance.stakeSlib(value, {from: from});

const getPastGeneratedFee = async (round, catIndex) => bn(await instance.getPastGeneratedFee(round, catIndex, {from: acc1}));

const getUnclaimedFee = async (catIndex) => bn(await instance.getUnclaimedFee(catIndex, {from: acc1}));

const getLastFeeReleasedDate = async (catIndex) => bn(await instance.getLastFeeReleasedDate(catIndex, {from: acc1}));

const getFeeLastUnlockedFeeGeneratedForARound = async () => await instance.getFeeLastUnlockedFeeGeneratedForARound({from: acc1});

const getGrossGeneratedFee = async (catIndex) => bn(await instance.getGrossGeneratedFee(catIndex, {from: acc1}));

const setWithdrawWindow = async (newWindow) => await instance.setWithdrawWindow(newWindow, {from: acc1});

const deleteAccountSoullibee = async (from) => await instance.deleteAccountSoullibee({from: from});

const unstakeSLIB = async (from) => await instance.unstakeSlib({from: from});

const addASoulliberToProfile = async (_cat, soulliber, from) => await instance.addASoulliberToProfile(_cat, soulliber, {from: from});

const individualSoulliberSignUp = async (referee, from) => await instance.individualSoulliberSignUp(referee, {from: from});

const removeSoulliberFromProfile = async (soulliber, from) => await instance.removeSoulliberFromProfile(soulliber, {from: from});

const claimRewardExemptRefferal = async (from) => instance.claimRewardExemptReferee({from:from});

const claimReferralReward = async (from) => instance.claimReferralReward({from:from});


const moveUnclaimedReward = async (to, index, from) => instance.moveUnclaimedReward(to, index, {from: from});

const routACall = async (to, from) => await instance.routACall(to, {from: from});

const updateCallCharge = async (newFee, from) => await instance.updateCallCharge(newFee, {from: from});

const setMinimumHoldForStaker = async (amount, from) => await instance.setMinimumHoldForStaker(amount, {from: from});

const setMinimumHoldForBoard = async (amount, from) => await instance.setMinimumHoldForBoard(amount, {from: from});

const getMinimumHold = async () => await instance.getMinimumHolds();

const getRate = async (catIndex) => await instance.getRate(catIndex);

const getCounterOfEachCategory = async (catIndex) => await instance.getCounterOfEachCategory(catIndex);

const setRate = async (catIndex, newRates=Array(7)) => bn (await instance.setRate(catIndex, newRates));

const emergencyWithdraw = async (to, amount) => await instance.emergencyWithdraw(to, amount);

const stakes = async (target) => bn(await instance.stakes(target));


describe('Testing...SlibDistributorHelper...', function (accounts) {
    before(async function () {
        accounts = await web3.eth.getAccounts()
        acc1 = accounts[0];
        acc2 = accounts[1];
        acc3 = accounts[2];
        acc4 = accounts[3];
        acc5 = accounts[4];
        
        slib = await SlibOneFile.new(acc1, {from: acc1});
        slibAddress = slib.address;

        instance = await SlibDistributorHelper.new(slibAddress, acc5, {from: acc1});
        sAddress = instance.address;

        for(let i = 0; i < 5; i++) {
            const value = bn(5e+24); 
            var address = accounts[i];
            transfer(acc1, address, value);
        }
    });

    // const getWIthdrawalWindow = async () => new BN(await instance.getWIthdrawalWindow());

    beforeEach(async function () {
        balAcc1 = await balanceOf(acc1);
        balAcc2 = await balanceOf(acc2);
        balAcc3 = await balanceOf(acc3);
        balAcc4 = await balanceOf(acc4);
        balAcc5 = await balanceOf(acc5);
        
        totalSupply = await tSupply();
    });

    it("...should comfirm token metadata.", async function () {
        const expected = String("SLIB Token");
        const _symbol = String("SLIB");
        const dec = 18;
        expect(await NAME()).to.equal(expected);
        expect(await symbol()).to.equal(_symbol);
        expect(_format(await decimals())).to.equal(dec);
        expect(_format(await tSupply())).to.equal(_format(msupply));
        console.log(
          "NAME: ", expected,
          "\nSYMBOL", _symbol,
          "\nDECIMAL", _format(await decimals()),
          "\nTOTAL SUPPLY :", _format( await tSupply())
        )
    });

    it('should reverts when transferring tokens to the zero address', async function () {
        expectRevert(
            transfer(acc1, ZERO_ADDRESS, amount),
            "ERC20: zero recipient",
        );
    });

    it('add new admin to list', async function () {
        await toggleAdminRole(acc3, 0);
        await toggleAdminRole(acc4, 0);
        expect(await isAdmin(acc3)).to.equal(true);
        expect(await isAdmin(acc4)).to.equal(true);
    });

    it('remove an admin from the list', async function () {
        await toggleAdminRole(acc4, 1);
        expect(await isAdmin(acc4)).to.equal(false);
    });

    it("...should revert when no fund to withdraw", async function() {
        expectRevert(
            emergencyWithdraw(acc1, etherValue, {from: acc1}),
            "Insufficeint balance",
        );
    });

    it("...should increase the bal when deposit", async function(){
        const balRouter = await web3.eth.getBalance(acc5);
        console.log("ETH BAL ACC5 init: ", _format(balRouter));
        
        await web3.eth.sendTransaction({
            from: acc4,
            to: sAddress,
            value: etherValue
        });
        const balafter = await web3.eth.getBalance(acc5);
        console.log("ETH BAL ACC5 AFTER: ", _format(balafter));
        const _bal = await web3.eth.getBalance(sAddress)
        expect(_format(_bal)).equal(0);
        expect(_format(balafter)).equal(_format(bn(balRouter).plus(etherValue)));
    });

    it("...should transfer value of an amount from the sender to the recipient.", async function() {
        await transfer(acc1, acc2, amount);
        expect(_format(await balanceOf(acc2))).to.equal(_format(amount.plus(bn(balAcc2))));
        expect(_format(await balanceOf(acc1))).to.equal(_format(bn(balAcc1).minus(amount)));
        console.log(
          "INIT BAL ACC1: ", _format(balAcc1),
          "\nINIT BAL ACC2: ", _format(balAcc2),
          "\nCURRENT BALANCE ACC1: ", _format(await balanceOf(acc1)),
          "\nCURRENT BALANCE ACC2: ", _format(await balanceOf(acc2))
        )

    });

    it("...should increase allowance of Acc3 after approval from Acc2.", async function () {
        await approve(amount, acc2, acc3);
        const currentAllowance = await allowance(acc2, acc3);
        
        expect(_format(currentAllowance )).to.equal(_format(bn(amount)));
        console.log(
          "APPROVED AMOUNT: ", _format(amount),
          "\nCURRENT ALLOWANCE: ", _format(currentAllowance)
        )
    });
    
    it("...should increase the balance of acc3 when transferFrom the owner", async function() {
        const allow = await allowance(acc2, acc3);

        await slib.transferFrom(acc2, acc3, allow, {from: acc3});
        const _allowance = await allowance(acc2, acc3);
        const _balAcc3 = await balanceOf(acc3);
        const _balAcc2 = await balanceOf(acc2);

        expect(_format(_allowance)).to.equal(0);
        expect(_format(_balAcc3)).to.equal(_format(bn(balAcc3).plus(allow)));
        expect(_format(_balAcc2)).to.equal(_format(bn(balAcc2).minus(allow)));

        console.log(
          "OLD BALANCE ACC2: ", _format(balAcc2),
          "\nOLD BALANCE ACC3: ", _format(balAcc3),
          "\nCURRENT BALANCE ACC2: ", _format(_balAcc2),
          "\nCURRENT BALANCE ACC3: ", _format(_balAcc3)
        )
    });

    it("...should set rates for a categories", async function() {
        const r1 = Array(0, 30, 20, 42, 3, 4, 1);
        await setRate(1, r1);
        const newRate1 = await getRate(1);
        for(let i = 0; i < 7; i++) {
            console.log("R1: ", r1[i], "\nNewRate1: ", _format(newRate1[i]));
            assert.equal(r1[i], newRate1[i]);
        }
    });

    
    it("...should revert when paused", async function() {
        await pause();
        expectRevert(
            stakeSLIB(acc3, boardThreshold),
            "Pausable: paused"
        )
        await unpause();
    });

    it("...should confirm acc1 as an admin", async function() {
        assert.isTrue(await isAdmin(acc1));
    });
    
    it("...should sign up as a soulliber", async function() {
        await individualSoulliberSignUp(acc4, acc2);
        assert.isTrue(await isSoulliber(acc2))

        const cat = await getUserCategory(acc2);
        expect(_format(cat)).to.equal(0);
    });

    it("...should sign up a soulliber", async function() {
        await addASoulliberToProfile(1, acc5, acc3);
        assert.isTrue(await isSoulliber(acc5));
        const cat = await getUserCategory(acc5);
        expect(_format(cat)).to.equal(1);
    });

    it("...should set minimum holds", async function() {
        await setMinimumHoldForBoard(boardThreshold, acc1);
        await setMinimumHoldForStaker(stakerThreshold, acc1);
  
        const holds = await getMinimumHold();
  
        console.log(
          "STAKER: ", _format(holds[0]),
          "\nBOARD: ", _format(holds[1])
        )
        expect(_format(holds[0])).to.equal(_format(stakerThreshold));
        expect(_format(holds[1])).to.equal(_format(boardThreshold));
    });

    it("...should set logic address", async function() {
        await slib.setLogic(sAddress, {from: acc1});
    })

    it("...should stake successfully", async () => {
        await stakeSLIB(acc2, boardThreshold);
        await stakeSLIB(acc5, stakerThreshold);
        const stake = await stakes(acc2);
        const stake5 = await stakes(acc5);
        console.log(
          "\nBOARD THRESHOLD: ", _format(boardThreshold),
          "\nACTUAL STAKE: ", _format(stake),
          "\nSTAKER THRESHOLD: ", _format(stakerThreshold),
          "\nACTUAL STAKE: ", _format(stake5)
        );
        const bal1 = await balanceOf(acc2);
        const bal2 = await balanceOf(acc5);
        
        assert.isTrue(await hasStake(acc2));
        assert.isTrue(await hasStake(acc5));
        expect(_format(stake)).to.equal(_format(boardThreshold));
        expect(_format(stake5)).to.equal(_format(stakerThreshold));
        expect(_format(bal1)).to.equal(_format(balAcc2.minus(boardThreshold)));
        expect(_format(bal2)).to.equal(_format(balAcc5.minus(stakerThreshold)));
    });

    it("...should unstake successfully", async () => {
        const initStake = await stakes(acc2);
        await unstakeSLIB(acc2);
        const stake = await stakes(acc2);
        const bal = await balanceOf(acc2);
        
        assert.isFalse(await hasStake(acc2));
        expect(_format(stake)).to.equal(0);
        expect(_format(bal)).to.equal(_format(balAcc2.plus(initStake)));
    });

    it("...should stake again", async () => {
        const initStake = await stakes(acc2);
        await stakeSLIB(acc2, boardThreshold);
        const stake = await stakes(acc2);
        console.log(
          "INITIAL STAKE: ", _format(initStake),
          "\nACTUAL STAKE: ", _format(stake)
        );

        expect(_format(stake)).to.equal(_format(boardThreshold.plus(initStake)));
    });

    it("...should add account as soullibee", async function() {
        await signUpAsSoullibee(acc1);
        const isSoul = await isSoullibee(acc1);
        assert.isTrue(isSoul);
    });

    it("...should revert when target is not a soulliber", async function() {
        expectRevert(
            routACall(acc3, acc1),
            "Not a soulliber"
        )
    });

    it("...should revert when target is not a soullibee", async function() {
        expectRevert(
            routACall(acc2, acc5),
            "Not registered"
        )
    });

    it("...should make a call", async function() {
        const fee = await getFeeLastUnlockedFeeGeneratedForARound();
        console.log(
            "\nINIT:",
            "\n LAST FEE RELEASE DATE 0: ", _format(await getLastFeeReleasedDate(0)),
            "\nLAST FEE RELEASE DATE 1: ", _format(await getLastFeeReleasedDate(1)),
            "\nGROSS GENERATED FEE 0: ", _format(await getGrossGeneratedFee(0)),
            "\nGROSS GENERATED FEE 1: ", _format(await getGrossGeneratedFee(1)),
            "\nUNCLAIMED FEE 0: ", _format(await getUnclaimedFee(0)),
            "\nUNCLAIMED FEE 1: ", _format(await getUnclaimedFee(1)),
            "\nPAST GENERATED FEE 1: ", _format(await getPastGeneratedFee(5, 1)),
            "\ngetFeeLast ..: ", _format(fee[0]),
            "\ngetFeeLast 2..: ", _format(fee[1]),
            "\ngetFeeLast 3..: ", _format(fee[2])
        );

        const newFee = bn(2e+21);
        await setWithdrawWindow(0);
        await updateCallCharge(newFee, acc1);
        await routACall(acc2, acc1);
        await routACall(acc2, acc1);
        await routACall(acc5, acc1);
        await routACall(acc5, acc1);
        const feedate = await getFeeLastUnlockedFeeGeneratedForARound();

        console.log(
            "\nAFTER: ",
            "\nLAST FEE RELEASE DATE 0: ", _format(await getLastFeeReleasedDate(0)),
            "\nLAST FEE RELEASE DATE 1: ", _format(await getLastFeeReleasedDate(1)),
            "\nGROSS GENERATED FEE 0: ", _format(await getGrossGeneratedFee(0)),
            "\nGROSS GENERATED FEE 1: ", _format(await getGrossGeneratedFee(1)),
            "\nUNCLAIMED FEE 0: ", _format(await getUnclaimedFee(0)),
            "\nUNCLAIMED FEE 1: ", _format(await getUnclaimedFee(1)),
            "\nPAST GENERATED FEE: ", _format(await getPastGeneratedFee(5, 1)),
            "\nPAST GENERATED FEE: ", _format(await getPastGeneratedFee(6, 1)),
            "\ngetFeeLast ..: ", _format(feedate[0]),
            "\ngetFeeLast 2..: ", _format(feedate[1]),
            "\ngetFeeLast 3..: ", _format(feedate[2])
        );
        
    });

    it("...should get call id of soullibee", async function() {
        const id = await getCallId(1, acc2);
        const id5 = await getCallId(1, acc5);

        console.log(
            "ID2: ", _format(id),
            "ID5: ", _format(id5)
        );

        expect(_format(id)).to.equal(1);
        expect(_format(id5)).to.equal(3);
    });


    it("...should claim reward", async function() {
        console.log(
            "\nINIT BAL ACC2: ", _format(balAcc2),
            "\nINIT BAL ACC4: ", _format(balAcc4),
            "\nINIT BAL ACC5: ", _format(balAcc5),
        )
        await claimRewardExemptRefferal(acc2);
        await claimRewardExemptRefferal(acc5);

        await claimReferralReward(acc4);

        console.log(
            "\nAFTER BAL ACC2: ", _format(await balanceOf(acc2)),
            "\nAFTER BAL ACC4: ", _format(await balanceOf(acc4)),
            "\nAFTER BAL ACC5: ", _format(await balanceOf(acc5)),
        )
    });
    
    it("...should remove soulliber from profile", async function() {
        await removeSoulliberFromProfile(acc5, acc3);
        const isSoul = await isSoulliber(acc5);
        assert.isFalse(isSoul);
    });

    it("...should delete account of soullibee", async function() {
        await deleteAccountSoullibee(acc1);
        const isSoul = await isSoullibee(acc1);
        assert.isTrue(isSoul);
    });
   
});



