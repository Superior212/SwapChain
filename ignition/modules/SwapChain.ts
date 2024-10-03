import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const swapModule = buildModule("swapModule", (m) => {
  const lock = m.contract("SwapChain", []);

  return { lock };
});

export default swapModule;
