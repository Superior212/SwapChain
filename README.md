# SwapChain

SwapChain is a decentralized token swap smart contract built on Ethereum. It allows users to create and fulfill token swap orders in a trustless manner.

## Features

- Deposit ERC20 tokens
- Create swap orders
- Fulfill existing orders
- Cancel unfulfilled orders
- Withdraw deposited tokens
- View deposit balances

## Smart Contract Overview

The SwapCoin contract is implemented in Solidity and includes the following key components:

- `UserDeposit`: A struct to track user token balances
- `Order`: A struct to represent swap orders
- `depositAndCreateOrder`: A function to deposit tokens and create an order in one transaction
- `fulfillOrder`: A function to fulfill existing orders
- `cancelOrder`: A function to cancel unfulfilled orders
- `withdraw`: A function to withdraw deposited tokens

## Prerequisites

- Node.js (v12.0.0 or later)
- npm (v6.0.0 or later)
- Hardhat

## Installation

1. Clone the repository:

   ```
   git clone https://github.com/Superior212/SwapChain
   cd swapcoin
   ```

2. Install dependencies:

   ```
   npm install
   ```

3. Compile the smart contracts:
   ```
   npx hardhat compile
   ```

## Security Considerations

- The contract uses OpenZeppelin's `ReentrancyGuard` to prevent reentrancy attacks.
- It's recommended to have the contract audited by a professional security firm before deploying to mainnet.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
