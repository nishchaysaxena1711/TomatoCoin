const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { utils: { parseEther }, BigNumber } = ethers;

describe("TomatoCoin", function () {
    let _TomatoCoin, tomatoCoin;
    let treasury, owner, c1, c2, c3, treasury2, tomatoIco;

    beforeEach(async function () {
        [treasury, owner, c1, c2, c3, treasury2, tomatoIco] = await ethers.getSigners();
        
        _TomatoCoin = await ethers.getContractFactory('Tomato');

        tomatoCoin = await upgrades.deployProxy(_TomatoCoin, [treasury.address]);
        await tomatoCoin.deployed();

        await tomatoCoin.setTomatoIcoAddress(tomatoIco.address);
    });

    it("should allow only owner can toggle tax", async function () {
        expect(await tomatoCoin.taxEnabled()).to.deep.equal(false);
        
        await tomatoCoin.toggleTax();
        expect(await tomatoCoin.taxEnabled()).to.deep.equal(true);

        try {
            await tomatoCoin.connect(c1).toggleTax();
        } catch (err) {
            expect(err.message).to.deep.equal("VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
        }

        await tomatoCoin.toggleTax();
        expect(await tomatoCoin.taxEnabled()).to.deep.equal(false);
    });

    it("should allow only owner can change treasury address", async function () {
        expect(await tomatoCoin.treasuryAddress()).to.deep.equal(treasury.address);

        try {
            await tomatoCoin.connect(c1).setTreasuryAddress(c2.address);
        } catch (err) {
            expect(err.message).to.deep.equal("VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
        }

        await tomatoCoin.setTreasuryAddress(treasury2.address);
        expect(await tomatoCoin.treasuryAddress()).to.deep.equal(treasury2.address);
    });

    it("should compute tax correctly", async function() {
        expect(await tomatoCoin.balanceOf(treasury.address)).to.deep.equal("50000");

        await tomatoCoin.connect(tomatoIco).mint(c1.address, BigNumber.from(100));
        await tomatoCoin.connect(tomatoIco).mint(c2.address, BigNumber.from(100));
        await tomatoCoin.connect(c2).transfer(c1.address, BigNumber.from(50));

        expect(await tomatoCoin.balanceOf(c1.address)).to.deep.equal(BigNumber.from(150));
        expect(await tomatoCoin.balanceOf(c2.address)).to.deep.equal(BigNumber.from(50));
        expect(await tomatoCoin.balanceOf(treasury.address)).to.deep.equal("50000");

        await tomatoCoin.toggleTax();
        await tomatoCoin.connect(c1).transfer(c2.address, BigNumber.from(50));

        expect(await tomatoCoin.balanceOf(c1.address)).to.deep.equal(100);
        expect(await tomatoCoin.balanceOf(c2.address)).to.deep.equal(99);
        expect(await tomatoCoin.balanceOf(treasury.address)).to.deep.equal("50001");
    });

});
