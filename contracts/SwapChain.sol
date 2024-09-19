// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapCoin is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Mapping of deposits (token address => depositor => deposit amount)
    mapping(address => mapping(address => uint256)) public deposits;

    // Mapping of orders (order ID => order details)
    mapping(uint256 => Order) public orders;

    // Order structure
    struct Order {
        address depositor;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        bool fulfilled;
    }

    uint256 public nextOrderId;

    // Event emitted when a deposit is made
    event Deposit(address indexed depositor, address indexed token, uint256 amount);

    // Event emitted when an order is created
    event OrderCreated(uint256 indexed orderId, address indexed depositor, address indexed tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    // Event emitted when an order is fulfilled
    event OrderFulfilled(uint256 indexed orderId, address indexed buyer, address indexed tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    constructor() Ownable(msg.sender) {}

    function deposit(address token, uint256 amount) public nonReentrant {
        require(amount > 0, "Deposit amount must be greater than 0");
        
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        deposits[token][msg.sender] += amount;

        emit Deposit(msg.sender, token, amount);
    }

    function createOrder(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) public nonReentrant {
        require(tokenIn != tokenOut, "Invalid token pair");
        require(amountIn > 0 && amountOut > 0, "Invalid amounts");
        require(deposits[tokenIn][msg.sender] >= amountIn, "Insufficient deposit");

        uint256 orderId = nextOrderId++;
        orders[orderId] = Order(msg.sender, tokenIn, tokenOut, amountIn, amountOut, false);

        deposits[tokenIn][msg.sender] -= amountIn;

        emit OrderCreated(orderId, msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function fulfillOrder(uint256 orderId) public nonReentrant {
        Order storage order = orders[orderId];
        require(!order.fulfilled, "Order already fulfilled");
        require(deposits[order.tokenOut][msg.sender] >= order.amountOut, "Insufficient deposit to fulfill order");

        address buyer = msg.sender;
        address seller = order.depositor;

        // Transfer tokens
        deposits[order.tokenOut][buyer] -= order.amountOut;
        deposits[order.tokenIn][seller] += order.amountIn;
        deposits[order.tokenOut][seller] += order.amountOut;

        // Update order status
        order.fulfilled = true;

        emit OrderFulfilled(orderId, buyer, order.tokenIn, order.tokenOut, order.amountIn, order.amountOut);
    }

    function withdraw(address token, uint256 amount) public nonReentrant {
        require(deposits[token][msg.sender] >= amount, "Insufficient balance");

        deposits[token][msg.sender] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    // Emergency function to recover any ERC20 tokens sent to the contract
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }
}