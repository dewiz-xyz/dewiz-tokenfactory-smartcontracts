// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Factory} from "../interfaces/IERC20Factory.sol";
import {DewizERC20} from "../tokens/DewizERC20.sol";

/**
 * @title ERC20Factory
 * @author Dewiz
 * @notice Factory contract for creating ERC-20 tokens
 * @dev Implements the Abstract Factory pattern for ERC-20 token creation
 *      Inherits from Ownable for factory-level access control
 */
contract ERC20Factory is IERC20Factory, Ownable {
    /// @notice Array of all tokens created by this factory
    address[] private _tokens;

    /// @notice Mapping to track tokens created by this factory
    mapping(address => bool) private _isFactoryToken;

    /// @notice Mapping to track tokens created by specific addresses
    mapping(address => address[]) private _creatorTokens;

    /// @notice Default decimals for simple token creation
    uint8 public constant DEFAULT_DECIMALS = 18;

    /// @notice Error thrown when token creation fails
    error TokenCreationFailed();

    /**
     * @notice Creates a new ERC20Factory
     * @param initialOwner The address that will own the factory
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Returns the type of tokens this factory creates
     * @return The token standard identifier
     */
    function tokenType() external pure override returns (string memory) {
        return "ERC20";
    }

    /**
     * @notice Creates a new ERC-20 token with the specified parameters
     * @param params The token creation parameters
     * @return tokenAddress The address of the newly created token
     */
    function createToken(ERC20TokenParams calldata params) external override returns (address tokenAddress) {
        DewizERC20 token = new DewizERC20(
            params.name,
            params.symbol,
            params.decimals,
            params.initialSupply,
            params.initialHolder,
            msg.sender,
            params.isMintable,
            params.isBurnable,
            params.isPausable
        );

        tokenAddress = address(token);
        _registerToken(tokenAddress, params.name, params.symbol);
    }

    /**
     * @notice Creates a simple ERC-20 token with basic parameters
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param initialSupply The initial token supply
     * @return tokenAddress The address of the newly created token
     */
    function createSimpleToken(
        string calldata name,
        string calldata symbol,
        uint256 initialSupply
    ) external override returns (address tokenAddress) {
        DewizERC20 token = new DewizERC20(
            name,
            symbol,
            DEFAULT_DECIMALS,
            initialSupply,
            msg.sender,
            msg.sender,
            true,  // mintable
            true,  // burnable
            false  // not pausable
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
