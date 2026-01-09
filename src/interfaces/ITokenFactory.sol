// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ITokenFactory
 * @author Dewiz
 * @notice Abstract Factory interface for creating token contracts
 * @dev Defines the contract for all concrete token factory implementations
 *      following the Abstract Factory design pattern
 */
interface ITokenFactory {
    /// @notice Emitted when a new token is created
    /// @param tokenAddress The address of the newly created token
    /// @param creator The address that initiated the token creation
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol
    );

    /// @notice Returns the type of tokens this factory creates
    /// @return The token standard identifier (e.g., "ERC20", "ERC721", "ERC1155")
    function tokenType() external pure returns (string memory);

    /// @notice Returns the count of tokens created by this factory
    /// @return The total number of tokens created
    function getTokenCount() external view returns (uint256);

    /// @notice Returns the address of a token at a specific index
    /// @param index The index in the tokens array
    /// @return The address of the token contract
    function getTokenAt(uint256 index) external view returns (address);

    /// @notice Returns all tokens created by this factory
    /// @return An array of all token addresses
    function getAllTokens() external view returns (address[] memory);

    /// @notice Checks if an address is a token created by this factory
    /// @param tokenAddress The address to check
    /// @return True if the address is a token from this factory
    function isTokenFromFactory(address tokenAddress) external view returns (bool);
}
