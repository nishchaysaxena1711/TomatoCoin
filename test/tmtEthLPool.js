const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { utils: { parseEther }, BigNumber } = ethers;

describe("Tomato_Eth_Liquidity_Pool", function() {

    let _TomatoIco, tomatoIco, _TomatoCoin, tomatoCoin, _LPCoin, lpCoin, _LiquidityPool, liquidityPool;
    let treasury, eth, owner, c1, c2, c3;

    beforeEach(async function () {
        [treasury, eth, owner, c1, c2, c3] = await ethers.getSigners();
        
        _TomatoIco = await ethers.getContractFactory('TomatoSale');
        _TomatoCoin = await ethers.getContractFactory('Tomato');
        _LPCoin = await ethers.getContractFactory('LPToken');
        _LiquidityPool = await ethers.getContractFactory('EthTomatoPool');

        liquidityPool = await upgrades.deployProxy(_LiquidityPool, [treasury.address, eth.address]);
        await liquidityPool.deployed();

        lpCoin = await upgrades.deployProxy(_LPCoin);
        await lpCoin.deployed();

        tomatoCoin = await upgrades.deployProxy(_TomatoCoin, [treasury.address, liquidityPool.address]);
        await tomatoCoin.deployed();

        tomatoIco = await upgrades.deployProxy(_TomatoIco, [tomatoCoin.address]);
        await tomatoIco.deployed();

        await tomatoCoin.setTomatoIcoAddress(tomatoIco.address);

        await lpCoin.setTomatoLPAddress(liquidityPool.address);
        await liquidityPool.setLPTokenAddress(lpCoin.address);
        await liquidityPool.setTomatoTokenAddress(tomatoCoin.address);

        await tomatoIco.toggleFundRaising();

        expect(await tomatoIco.phase()).to.deep.equal(0); // SEED
        await tomatoIco.movePhaseForward();
        expect(await tomatoIco.phase()).to.deep.equal(1); // GENERAL
        await tomatoIco.movePhaseForward();
        expect(await tomatoIco.phase()).to.deep.equal(2); // OPEN
    });

    it("should have 150000 tomato coins in account of lpool", async function() {
        expect(await tomatoCoin.balanceOf(liquidityPool.address)).to.deep.equal('150000');
    });

    it('should allow owner to transfer funds into liquidity contract', async function() {
    });

    it("should provide liquidity to pool successfully", async function() {});

    it("should allow burl lpTOkens successfully", async function() {});

    it("should swap tomato for eth successfully and vice-versa", async function() {});

});
