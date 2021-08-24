const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { utils: { parseEther } } = ethers;

describe("TomatoICO", function () {
    let _TomatoIco, tomatoIco, _TomatoCoin, tomatoCoin;
    let treasury, owner, c1, c2;

    beforeEach(async function () {
        [treasury, owner, c1, c2] = await ethers.getSigners();
        
        _TomatoIco = await ethers.getContractFactory('TomatoSale');
        _TomatoCoin = await ethers.getContractFactory('Tomato');

        tomatoCoin = await upgrades.deployProxy(_TomatoCoin, [treasury.address]);
        await tomatoCoin.deployed();

        tomatoIco = await upgrades.deployProxy(_TomatoIco, [tomatoCoin.address]);
        await tomatoIco.deployed();
    });

    it("should allow only owner can change phases", async function () {
        expect(await tomatoIco.phase()).to.eq(0); // SEED

        await tomatoIco.movePhaseForward();
        expect(await tomatoIco.phase()).to.eq(1); // GENERAL

        try {
            await tomatoIco.connect(c1).movePhaseForward();
        } catch (err) {
            expect(err.message).to.deep.equal("VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
        }

        await tomatoIco.movePhaseForward();
        expect(await tomatoIco.phase()).to.eq(2); // OPEN
    });

    it("should not allow contribution if fund raising is not enabled", async function() {
        expect(await tomatoIco.fundRaisingEnabled()).to.eq(false);

        try {
            await tomatoIco.connect(c1).fundRaisingEnabled();
        } catch (err) {
            expect(err.message).to.deep.equal("VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
        }

        try {
            await tomatoIco.connect(c1).buyTomatoTokens();
        } catch (err) {
            expect(err.message).to.deep.equal("VM Exception while processing transaction: reverted with reason string 'Tomato token sale must be active'");
        }

        await tomatoIco.toggleFundRaising();
        await tomatoIco.addAddressToWhitelist(c1.address);
        await tomatoIco.connect(c1).buyTomatoTokens({ value: 10 });

        expect(await tomatoIco.totalEtherRaised()).to.eq("10");

        await tomatoIco.toggleFundRaising();
        expect(await tomatoIco.fundRaisingEnabled()).to.eq(false);
    });

    it("only whitelisted address can contribute in Seed phase", async function() {
        expect(await tomatoIco.phase()).to.eq(0); // SEED
        expect(await tomatoIco.fundRaisingEnabled()).to.eq(false);

        await tomatoIco.toggleFundRaising();
        expect(await tomatoIco.fundRaisingEnabled()).to.eq(true);

        try {
            await tomatoIco.connect(c1).buyTomatoTokens();
        } catch (err) {
            expect(err.message).to.deep.equal("VM Exception while processing transaction: reverted with reason string 'Contribution should be greater than 0'");
        }

        try {
            await tomatoIco.connect(c1).buyTomatoTokens({ value: 10 });
        } catch (err) {
            expect(err.message).to.deep.equal("VM Exception while processing transaction: reverted with reason string 'Address is not whitelisted for sale in seed phase'");
        }

        await tomatoIco.addAddressToWhitelist(c2.address);
        await tomatoIco.connect(c2).buyTomatoTokens({ value: 10 });

        expect(await tomatoCoin.balanceOf(c1.address)).to.eq("0");
        expect(await tomatoCoin.balanceOf(c2.address)).to.eq("0"); // not minted yet
        expect(await tomatoIco.totalEtherRaised()).to.eq("10");
    });

    it("should allow anyone to contribute in general phase", async function() {
        await tomatoIco.toggleFundRaising(); // fundraising enabled
        expect(await tomatoIco.phase()).to.eq(0); // SEED

        try {
            await tomatoIco.connect(c1).buyTomatoTokens({ value: 10 });
        } catch (err) {
            expect(err.message).to.deep.equal("VM Exception while processing transaction: reverted with reason string 'Address is not whitelisted for sale in seed phase'");
        }

        await tomatoIco.movePhaseForward();
        expect(await tomatoIco.phase()).to.eq(1); // GENERAL

        await tomatoIco.connect(c1).buyTomatoTokens({ value: 10 }); // same address now able to contribute without adding it in whitelisted list

        expect(await tomatoCoin.balanceOf(c1.address)).to.eq("0"); // not minted yet
        expect(await tomatoIco.totalEtherRaised()).to.eq("10");
    });

});
