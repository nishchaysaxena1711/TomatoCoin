const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

// describe("TomatoICO", function () {
//     let _TomatoIco, tomatoIco, _TomatoCoin, tomatoCoin;

//     before(async function () {
//         let [treasury] = await ethers.getSigners();
        
//         _TomatoIco = await ethers.getContractFactory('TomatoSale');
//         _TomatoCoin = await ethers.getContractFactory('Tomato');

//         tomatoCoin = await upgrades.deployProxy(_TomatoCoin, [treasury.address]);
//         await tomatoCoin.deployed();

//         tomatoIco = await _TomatoIco.deploy();
//         await tomatoIco.deployed();
//     });

//     it("should allow the owner to advance phases", async function () {
//         expect(await tomatoIco.getPhase()).to.eq(0);
//     });

// });


// describe("Tomato", function () {
//     let _tomatoCoin, tomatoCoin;

//     before(async function () {
//         let [owner, treasury] = await ethers.getSigners();
//         _tomatoCoin = await ethers.getContractFactory('Tomato');
//         tomatoCoin = await _tomatoCoin.connect(owner).deploy(); // throwing error if we send treasury address as a param
//         await tomatoCoin.deployed();
//     });

//     it("should only allow the owner to toggle taxes", async function () {
//         let [owner] = await ethers.getSigners();
//         await tomatoCoin.connect(owner).toggleTax();
//     });

// });