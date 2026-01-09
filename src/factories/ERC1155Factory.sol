// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1155Factory} from "../interfaces/IERC1155Factory.sol";
import {DewizERC1155} from "../tokens/DewizERC1155.sol";

/**
 * @title ERC1155Factory
 * @author Dewiz
 * @notice Factory contract for creating ERC-1155 tokens
 * @dev Implements the Abstract Factory pattern for ERC-1155 token creation
 *      Inherits from Ownable for factory-level access control
 */
contract ERC1155Factory is IERC1155Factory, Ownable {
    /// @notice Array of all tokens created by this factory
    address[] private _tokens;

    /// @notice Mapping to track tokens created by this factory
    mapping(address => bool) private _isFactoryToken;

    /// @notice Mapping to track tokens created by specific addresses
    mapping(address => address[]) private _creatorTokens;

    /// @notice Error thrown when token creation fails
    error TokenCreationFailed();

    /**
     * @notice Creates a new ERC1155Factory
     * @param initialOwner The address that will own the factory
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Returns the type of tokens this factory creates
     * @return The token standard identifier
     */
    function tokenType() external pure override returns (string memory) {
        return "ERC1155";
    }

    /**
     * @notice Creates a new ERC-1155 token with the specified parameters
     * @param params The token creation parameters
     * @return tokenAddress The address of the newly created token
     */
    function createToken(ERC1155TokenParams calldata params) external override returns (address tokenAddress) {
        DewizERC1155 token = new DewizERC1155(
            params.name,
            params.symbol,
            params.uri,
            msg.sender,
            params.isMintable,
            params.isBurnable,
            params.isPausable,
            params.hasRoyalty,
            params.royaltyReceiver,
            params.royaltyFeeNumerator
        );

        tokenAddress = address(token);
        _registerToken(tokenAddress, params.name, params.symbol);
    }

    /**
     * @notice Creates a simple ERC-1155 token with basic parameters
     * @param name The name of the token collection
     * @param symbol The symbol of the token collection
     * @param uri The URI for token metadata
     * @return tokenAddress The address of the newly created token
     */
    function createSimpleToken(
        string calldata name,
        string calldata symbol,
        string calldata uri
    ) external override returns (address tokenAddress) {
        DewizERC1155 token = new DewizERC1155(
            name,
            symbol,
            uri,
            msg.sender,
            true,     // mintable
            true,     // burnable
            false,    // not pausable
            false,    // no royalty
            address(0),
            0
        );

        tokenAddress = address(token);
        _registerToken(tokenAddress, name, symbol);
    }

    /**
     * @notice Returns the count of tokens created by this factory
     * @return The total number of tokens created
     */
    function getTokenCount() external view override returns (uint256) {
        return _tokens.length;
    }

    /**
     * @notice Returns the address of a token at a specific index
     * @param index The index in the tokens array
     * @return The address of the token contract
     */
    function getTokenAt(uint256 index) external view override returns (address) {
        return _tokens[index];
    }

    /**
     * @notice Returns all tokens created by this factory
     * @return An array of all token addresses
     */
    function getAllTokens() external view override returns (address[] memory) {
        return _tokens;
    }

    /**
     * @notice Checks if an address is a token created by this factory
     * @param tokenAddress The address to check
     * @return True if the address is a token from this factory
     */
    function isTokenFromFactory(address tokenAddress) external view override returns (bool) {
        return _isFactoryToken[tokenAddress];
    }

    /**
     * @notice Returns all tokens created by a specific address
     * @param creator The address of the creator
     * @return An array of token addresses created by the creator
     */
    function getTokensByCreator(address creator) external view returns (address[] memory) {
        return _creatorTokens[creator];
    }

    /**
     * @dev Internal function to register a newly created token
     * @param tokenAddress The address of the new token
     * @param name The name of the token
     * @param symbol The symbol of the token
     */
    function _registerToken(address tokenAddress, string memory name, string memory symbol) internal {
        _tokens.push(tokenAddress);
        _isFactoryToken[tokenAddress] = true;
        _creatorTokens[msg.sender].push(tokenAddress);
        
        emit TokenCreated(tokenAddress, msg.sender, name, symbol);
    }
}
