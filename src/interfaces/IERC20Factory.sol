// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITokenFactory} from "./ITokenFactory.sol";

/**
 * @title IERC20Factory
 * @author Dewiz
 * @notice Interface for ERC-20 token factory
 * @dev Extends ITokenFactory with ERC-20 specific creation methods
 */
interface IERC20Factory is ITokenFactory {
    /// @notice Parameters for creating an ERC-20 token
    struct ERC20TokenParams {
        string name;
        string symbol;
        uint8 decimals;
        uint256 initialSupply;
        address initialHolder;
        bool isMintable;
        bool isBurnable;
        bool isPausable;
    }

    /// @notice Creates a new ERC-20 token with the specified parameters
    /// @param params The token creation parameters
    /// @return tokenAddress The address of the newly created token
    function createToken(ERC20TokenParams calldata params) external returns (address tokenAddress);

    /// @notice Creates a simple ERC-20 token with basic parameters
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param initialSupply The initial token supply
    /// @return tokenAddress The address of the newly created token
    function createSimpleToken(
        string calldata name,
        string calldata symbol,
        uint256 initialSupply
    ) external returns (address tokenAddress);
}
