import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("SwapChain", function () {
  async function deploySwapChain() {
    // Contracts are deployed using the first signer/account by default
    const [owner, addr1, addr2] = await hre.ethers.getSigners();

    // Deploy mock ERC20 tokens
    const MockToken = await hre.ethers.getContractFactory("SolarCoin");
    const token1 = await MockToken.deploy("Token1", "TKN1");
    const token2 = await MockToken.deploy("Token2", "TKN2");

    // Deploy SwapCoin contract
    const SwapChain = await hre.ethers.getContractFactory("SwapChain");
    const swapChain = await SwapChain.deploy();

    // Mint some tokens for testing
    await token1.mint(addr1.address, hre.ethers.parseEther("1000"));
    await token2.mint(addr2.address, hre.ethers.parseEther("1000"));

    return { swapChain, token1, token2, owner, addr1, addr2 };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { swapChain, owner } = await loadFixture(deploySwapChain);
      expect(await swapChain.owner()).to.equal(owner.address);
    });
  });
});
