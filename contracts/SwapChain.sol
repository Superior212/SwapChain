// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapChain is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    address public owner;

    struct UserDeposit {
        mapping(address => uint256) tokenBalances;
    }

    struct Order {
        address depositor;
        address tokenIn;
        address tokenOut;
        uint128 amountIn;
        uint128 amountOut;
        bool fulfilled;
        bool cancelled;
    }

    mapping(address => UserDeposit) private deposits;
    mapping(uint256 => Order) public orders;

    uint256 public nextOrderId;

    event DepositMade(
        address indexed depositor,
        address indexed token,
        uint256 amount
    );
    event OrderCreated(
        uint256 indexed orderId,
        address indexed depositor,
        address indexed tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint128 amountOut
    );
    event OrderFulfilled(
        uint256 indexed orderId,
        address indexed buyer,
        address indexed tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint128 amountOut
    );
    event OrderCancelled(
        uint256 indexed orderId,
        address indexed depositor,
        address indexed tokenIn,
        uint128 amountIn
    );
    event Withdrawal(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    error InsufficientDeposit();
    error InvalidOrder();
    error OrderAlreadyFulfilled();
    error OrderAlreadyCancelled();
    error Unauthorized();

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Deposits a specified amount of tokens into the contract and creates a new order.
     *
     * @param tokenIn The token being deposited.
     * @param tokenOut The token being sold.
     * @param amountIn The amount of tokens being deposited.
     * @param amountOut The amount of tokens being sold.
     */
    function depositAndCreateOrder(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint128 amountOut
    ) external nonReentrant {
        _deposit(tokenIn, amountIn);
        _createOrder(tokenIn, tokenOut, amountIn, amountOut);
    }

    function _deposit(address token, uint256 amount) internal {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender].tokenBalances[token] += amount;
        emit DepositMade(msg.sender, token, amount);
    }

    /**
     * @dev Creates a new order by depositing the specified amount of tokens and storing the order details.
     *
     * @param tokenIn The token being deposited.
     * @param tokenOut The token being sold.
     * @param amountIn The amount of tokens being deposited.
     * @param amountOut The amount of tokens being sold.
     */
    function _createOrder(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint128 amountOut
    ) internal {
        if (tokenIn == tokenOut || amountIn == 0 || amountOut == 0)
            revert InvalidOrder();
        if (deposits[msg.sender].tokenBalances[tokenIn] < amountIn)
            revert InsufficientDeposit();

        uint256 orderId = nextOrderId++;
        orders[orderId] = Order(
            msg.sender,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            false,
            false
        );
        deposits[msg.sender].tokenBalances[tokenIn] -= amountIn;

        emit OrderCreated(
            orderId,
            msg.sender,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut
        );
    }

    /**
     * @dev Fulfills an existing order by transferring tokens to the buyer and updating the order status.
     *
     * @param orderId The ID of the order being fulfilled.
     */
    function fulfillOrder(uint256 orderId) external nonReentrant {
        Order storage order = orders[orderId];
        if (order.fulfilled) revert OrderAlreadyFulfilled();
        if (order.cancelled) revert OrderAlreadyCancelled();
        if (
            deposits[msg.sender].tokenBalances[order.tokenOut] < order.amountOut
        ) revert InsufficientDeposit();

        address buyer = msg.sender;
        address seller = order.depositor;

        // Update balances
        deposits[buyer].tokenBalances[order.tokenOut] -= order.amountOut;
        deposits[seller].tokenBalances[order.tokenIn] += order.amountIn;
        deposits[seller].tokenBalances[order.tokenOut] += order.amountOut;

        // Mark order as fulfilled
        order.fulfilled = true;

        emit OrderFulfilled(
            orderId,
            buyer,
            order.tokenIn,
            order.tokenOut,
            order.amountIn,
            order.amountOut
        );
    }

    /**
     * @dev Cancels an existing order by transferring tokens back to the depositor and updating the order status.
     *
     * @param orderId The ID of the order being cancelled.
     */
    function cancelOrder(uint256 orderId) external nonReentrant {
        Order storage order = orders[orderId];
        if (msg.sender != order.depositor) revert Unauthorized();
        if (order.fulfilled) revert OrderAlreadyFulfilled();
        if (order.cancelled) revert OrderAlreadyCancelled();

        // Return tokens to depositor
        deposits[order.depositor].tokenBalances[order.tokenIn] += order
            .amountIn;

        // Mark order as cancelled
        order.cancelled = true;

        emit OrderCancelled(
            orderId,
            order.depositor,
            order.tokenIn,
            order.amountIn
        );
    }

    /**
     * @dev Withdraws a specified amount of tokens from the contract.
     *
     * @param token The token being withdrawn.
     * @param amount The amount of tokens being withdrawn.
     */
    function withdraw(address token, uint256 amount) external nonReentrant {
        if (deposits[msg.sender].tokenBalances[token] < amount)
            revert InsufficientDeposit();

        deposits[msg.sender].tokenBalances[token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdrawal(msg.sender, token, amount);
    }

    /**
     * @dev Returns the balance of a specific token for a given user.
     *
     * @param user The user whose balance is being queried.
     * @param token The token being queried.
     *
     * @return The balance of the token for the user.
     */
    function getDeposit(
        address user,
        address token
    ) external view returns (uint256) {
        return deposits[user].tokenBalances[token];
    }

    /**
     * @dev Recovers any ERC20 tokens sent to the contract.
     *
     * @param tokenAddress The address of the token being recovered.
     * @param tokenAmount The amount of tokens being recovered.
     */
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }
}
