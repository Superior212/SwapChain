const { ethers } = require("ethers");
const SwapCoinABI =
  require("./artifacts/contracts/SwapCoin.sol/SwapCoin.json").abi;

async function main() {
  // Connect to the contract
  const provider = new ethers.providers.JsonRpcProvider(
    "https://mainnet.infura.io/v3/YOUR-PROJECT-ID"
  );
  const signer = new ethers.Wallet("YOUR-PRIVATE-KEY", provider);
  const swapCoinAddress = "DEPLOYED_CONTRACT_ADDRESS";
  const swapCoin = new ethers.Contract(swapCoinAddress, SwapCoinABI, signer);

  // Deposit tokens and create an order
  const tokenInAddress = "TOKEN_IN_ADDRESS";
  const tokenOutAddress = "TOKEN_OUT_ADDRESS";
  const amountIn = ethers.utils.parseUnits("100", 18); // Adjust decimals as needed
  const amountOut = ethers.utils.parseUnits("90", 18); // Adjust decimals as needed

  await swapCoin.depositAndCreateOrder(
    tokenInAddress,
    tokenOutAddress,
    amountIn,
    amountOut
  );

  console.log("Order created successfully!");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
