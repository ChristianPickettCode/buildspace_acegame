const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("AceGame");
  const gameContract = await gameContractFactory.deploy(
    ["King of Spades", "King of Diamonds", "King of Clubs", "King of Hearts"], // Names
    [
      "https://5ywn6daenz6poefpjkgs3c2vdgtzsk2vevam6ap7mvc4443iwdfq.arweave.net/XCc9IMqbpj6QFoNiB46xHJfgXhaxTeyZWdyeh_Eul5A", // Images
      "https://5ywn6daenz6poefpjkgs3c2vdgtzsk2vevam6ap7mvc4443iwdfq.arweave.net/D_xcsZP4qH9iClydxkWAIz1ztMdBPPzOOINDJ9UG2SI",
      "https://5ywn6daenz6poefpjkgs3c2vdgtzsk2vevam6ap7mvc4443iwdfq.arweave.net/uY68XKmEdltFpOwdVYK9rkUQ6hshnAw4QBbGN52FsZI",
      "https://5ywn6daenz6poefpjkgs3c2vdgtzsk2vevam6ap7mvc4443iwdfq.arweave.net/XzOJugbduBG2KxAJ_LBaGUZ9608L0ORwPzmU_KF-Ny0",
    ],
    [400, 400, 400, 400], // HP values
    [100, 100, 100, 100], // Attack damage values
    "Ace of Spades", // Boss name
    "https://5ywn6daenz6poefpjkgs3c2vdgtzsk2vevam6ap7mvc4443iwdfq.arweave.net/czRuCi_EV6NUSotNR7Pcaxc3WnigSO10qm-DQZaaYUc", // Boss image
    1000, // Boss hp
    100 // Boss attack damage
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
