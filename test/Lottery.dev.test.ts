import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { AddressLike, Wallet, ZeroAddress, hexlify, randomBytes, toBeArray, toBigInt } from "ethers";
import { ethers } from "hardhat";
import { ORBIToken, OrbiterLottery } from "../typechain-types";

describe("OrbiterLottery", () => {
  let deployer: HardhatEthersSigner;
  let owner: HardhatEthersSigner;
  let luckyUser: HardhatEthersSigner;
  let orbiterSigners: HardhatEthersSigner[];
  let rewardToken: ORBIToken;
  let rewardTokenAddress: string;
  let Lottery: OrbiterLottery;
  let signatures: string[] = [];

  interface signCard {
    winner: string;
    id: string;
    token: string;
    value: number;
    expiredTimestamp: number;
    flag: number;
  }

  interface Card {
    id: string;
    token: string;
    value: number;
    expiredTimestamp: number;
    flag: number;
  }

  let cards: Card[] = [];

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[9];
    luckyUser = signers[0];
    owner = signers[1];
    orbiterSigners = signers.slice(2, 4);

    const TestTokenFactory = await ethers.getContractFactory("ORBIToken");
    rewardToken = (await TestTokenFactory.connect(
      deployer
    ).deploy()) as ORBIToken;
    rewardTokenAddress = await rewardToken.getAddress();

    const LotteryFactory = await ethers.getContractFactory("OrbiterLottery");
    Lottery = (await LotteryFactory.connect(deployer).deploy(
      await owner.getAddress(),
      orbiterSigners.map((signer) => signer.getAddress())
    )) as OrbiterLottery;

    // approve rewardToken
    const tx1 = await rewardToken
      .connect(deployer)
      .approve(await Lottery.getAddress(), ethers.MaxUint256);
    await tx1.wait();

    // send rewardToken to Lottery
    const tx2 = await rewardToken
      .connect(deployer)
      .transfer(await Lottery.getAddress(), ethers.parseEther("1000"));
    await tx2.wait();

    // send rewardToken(native) to Lottery
    const tx3 = await deployer.sendTransaction({
      to: await Lottery.getAddress(),
      value: ethers.parseEther("0.001"),
    });
    await tx3.wait();

    // check balance
    expect(await rewardToken.balanceOf(await Lottery.getAddress())).to.equal(
      ethers.parseEther("1000")
    );

    console.log("OrbiterLottery deployed to: ", await Lottery.getAddress());
    console.log("rewardToken deployed to: ", rewardTokenAddress);
  });

  it("sign cards test", async () => {
    const signers = await ethers.getSigners();
    let signCards: signCard[] = [];
    const currentTime = (await ethers.provider.getBlock("latest"))?.timestamp;

    const signCardTypes = [
      "address",
      "uint64",
      "address",
      "bytes32",
      "address",
      "uint256",
      "uint64",
    ];
    const AbiCoder = ethers.AbiCoder.defaultAbiCoder();
    const luckyUserAddress = await luckyUser.getAddress();
    const currentChainId = (await signers[0].provider.getNetwork()).chainId;

    for (let i = 0; i < 10; i++) {
      const _rewardTokenAddress = i < 5 ? rewardTokenAddress : ZeroAddress;

      const randomId = ethers.hexlify(ethers.randomBytes(32));
      const randomFlag = Math.floor(Math.random() * 1000000);
      signCards.push({
        winner: luckyUserAddress,
        id: randomId,
        token: _rewardTokenAddress,
        value: (i + 1) * 1000,
        expiredTimestamp: currentTime! * 2,
        flag: randomFlag,
      });

      cards.push({
        id: signCards[i].id,
        token: _rewardTokenAddress,
        value: signCards[i].value,
        expiredTimestamp: signCards[i].expiredTimestamp,
        flag: signCards[i].flag,
      });

      const encodeMessageHash2 = ethers.keccak256(
        AbiCoder.encode(signCardTypes, [
          await Lottery.getAddress(),
          currentChainId,
          signCards[i].winner,
          signCards[i].id,
          _rewardTokenAddress,
          signCards[i].value,
          signCards[i].expiredTimestamp,
        ])
      );

      const encodeMessageHash = await Lottery.encodeCard(signCards[i].winner, {
        id: signCards[i].id,
        token: _rewardTokenAddress,
        value: signCards[i].value,
        expiredTimestamp: signCards[i].expiredTimestamp,
        flag: signCards[i].flag,
      });

      expect(encodeMessageHash).to.equal(encodeMessageHash2);

      const orbiterSigner = orbiterSigners[i % 2];

      signatures.push(
        await orbiterSigner.signMessage(toBeArray(encodeMessageHash))
      );
    }
  });

  it("ownerShip test", async () => {
    expect(await Lottery.owner()).to.equal(await owner.getAddress());
  });

  it("winner claimReward should pass", async () => {
    const beforeBalanceToken = await rewardToken.balanceOf(luckyUser.address);
    const beforeBalanceNative = await luckyUser.provider.getBalance(
      luckyUser.address
    );

    const tx = await Lottery.connect(luckyUser).claim(cards, signatures);
    const txReceipt = await tx.wait();
    const gasFee = (txReceipt?.gasUsed || 0n) * (txReceipt?.gasPrice || 0n);

    let totalClaimedToken: bigint = 0n;
    let totalClaimedNative: bigint = 0n;
    for (let i = 0; i < cards.length; i++) {
      if (cards[i].token == ZeroAddress) {
        totalClaimedNative += toBigInt(cards[i].value);
      } else {
        totalClaimedToken += toBigInt(cards[i].value);
      }
    }

    const afterBalanceToken = await rewardToken.balanceOf(luckyUser.address);
    const afterBalanceNative = await luckyUser.provider.getBalance(
      luckyUser.address
    );
    expect(afterBalanceToken - beforeBalanceToken).to.equal(totalClaimedToken);
    expect(afterBalanceNative - beforeBalanceNative + gasFee).to.equal(
      totalClaimedNative
    );

    // claim again should fail
    await expect(Lottery.connect(luckyUser).claim(cards, signatures)).to.be
      .reverted;

    const luckyUserAddress = (await luckyUser.getAddress()) as AddressLike;

    const claimedCards = await Lottery.getClaimedCards(luckyUserAddress);
    for (let i = 0; i < cards.length; i++) {
      expect(claimedCards[i].id).to.equal(cards[i].id);
      expect(claimedCards[i].value).to.equal(cards[i].value);
      expect(claimedCards[i].expiredTimestamp).to.equal(
        cards[i].expiredTimestamp
      );
      expect(claimedCards[i].flag).to.equal(cards[i].flag);
    }
  });

  it("check lottery existSigner", async () => {
    expect(await Lottery.existSigner(orbiterSigners[0])).to.be.true;
    expect(await Lottery.existSigner(Wallet.createRandom().address)).to.be.false;
  });

  it("check lottery existClaimId", async () => {
    expect(await Lottery.existClaimId(cards[0].id)).to.be.true;
    expect(await Lottery.existClaimId(cards[cards.length - 1].id)).to.be.true;
    expect(await Lottery.existClaimId(hexlify(randomBytes(32)))).to.be.false;
  });


  it("deployer withdraw should fail", async () => {
    await expect(
      Lottery.connect(deployer).withdraw(
        rewardTokenAddress,
        ethers.parseEther("1")
      )
    ).to.be.reverted;
  });

  it("deployer withdrawNative should fail", async () => {
    await expect(
      Lottery.connect(deployer).withdrawNative(ethers.parseEther("1"))
    ).to.be.reverted;
  });

  it("owner withdraw should pass", async () => {
    const beforeBalance = await rewardToken.balanceOf(owner);

    const amount = ethers.parseEther("1");
    const tx = await Lottery.connect(owner).withdraw(
      rewardTokenAddress,
      amount
    );
    await tx.wait();

    const afterBalance = await rewardToken.balanceOf(owner);

    expect(afterBalance - beforeBalance).to.equal(amount);
  });

  it("owner withdrawNative should pass", async () => {
    const beforeBalance = await owner.provider.getBalance(owner);

    const amount = ethers.parseEther("0.0001");
    const tx = await Lottery.connect(owner).withdrawNative(amount);
    const txReceipt = await tx.wait();
    const gasFee = (txReceipt?.gasUsed || 0n) * (txReceipt?.gasPrice || 0n);

    const afterBalance = await owner.provider.getBalance(owner);

    expect(afterBalance - beforeBalance + gasFee).to.equal(amount);
  });
});
