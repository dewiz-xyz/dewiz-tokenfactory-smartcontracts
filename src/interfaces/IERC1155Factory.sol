// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITokenFactory} from "./ITokenFactory.sol";

/**
 * @title IERC1155Factory
 * @author Dewiz
 * @notice Interface for ERC-1155 token factory
 * @dev Extends ITokenFactory with ERC-1155 specific creation methods
 */
interface IERC1155Factory is ITokenFactory {
    /// @notice Parameters for creating an ERC-1155 token
    struct ERC1155TokenParams {
        string name;
        string symbol;
        string uri;
        bool isMintable;
        bool isBurnable;
        bool isPausable;
        bool hasRoyalty;
        address royaltyReceiver;
        uint96 royaltyFeeNumerator; // Basis points (e.g., 250 = 2.5%)
        address complianceHook;
    }

    /// @notice Creates a new ERC-1155 token with the specified parameters
    /// @param params The token creation parameters
    /// @return tokenAddress The address of the newly created token
    function createToken(ERC1155TokenParams calldata params) external returns (address tokenAddress);

    /// @notice Creates a simple ERC-1155 token with basic parameters
    /// @param name The name of the token collection
    /// @param symbol The symbol of the token collection
    /// @param uri The URI for token metadata
    /// @return tokenAddress The address of the newly created token
    function createSimpleToken(
        string calldata name,
        string calldata symbol,
        string calldata uri
    ) external returns (address tokenAddress);
}
