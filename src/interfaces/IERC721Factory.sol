// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITokenFactory} from "./ITokenFactory.sol";

/**
 * @title IERC721Factory
 * @author Dewiz
 * @notice Interface for ERC-721 token factory
 * @dev Extends ITokenFactory with ERC-721 specific creation methods
 */
interface IERC721Factory is ITokenFactory {
    /// @notice Parameters for creating an ERC-721 token
    struct ERC721TokenParams {
        string name;
        string symbol;
        string baseURI;
        bool isMintable;
        bool isBurnable;
        bool isPausable;
        bool hasRoyalty;
        address royaltyReceiver;
        uint96 royaltyFeeNumerator; // Basis points (e.g., 250 = 2.5%)
        address complianceHook;
    }

    /// @notice Creates a new ERC-721 token with the specified parameters
    /// @param params The token creation parameters
    /// @return tokenAddress The address of the newly created token
    function createToken(ERC721TokenParams calldata params) external returns (address tokenAddress);

    /// @notice Creates a simple ERC-721 token with basic parameters
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param baseURI The base URI for token metadata
    /// @return tokenAddress The address of the newly created token
    function createSimpleToken(
        string calldata name,
        string calldata symbol,
        string calldata baseURI
    ) external returns (address tokenAddress);
}
