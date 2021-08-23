const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("TomatoICO", function () {
    let _TomatoIco, tomatoIco, _TomatoCoin, tomatoCoin;
    let treasury, owner;

    before(async function () {
        [treasury, owner] = await ethers.getSigners();
        
        _TomatoIco = await ethers.getContractFactory('TomatoSale');
        _TomatoCoin = await ethers.getContractFactory('Tomato');

        tomatoCoin = await upgrades.deployProxy(_TomatoCoin, [treasury.address]);
        await tomatoCoin.deployed();

        tomatoIco = await upgrades.deployProxy(_TomatoIco, [tomatoCoin.address]);
        await tomatoIco.deployed();
    });

    it("owner can change phases", async function () {
        expect(await tomatoIco.getPhase()).to.eq(0); // SEED

        await tomatoIco.movePhaseForward();

        expect(await tomatoIco.getPhase()).to.eq(1); // GENERAL
    });

});
