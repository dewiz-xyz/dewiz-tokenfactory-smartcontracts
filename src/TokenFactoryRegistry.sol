// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Factory} from "./interfaces/IERC20Factory.sol";
import {IERC721Factory} from "./interfaces/IERC721Factory.sol";
import {IERC1155Factory} from "./interfaces/IERC1155Factory.sol";

/**
 * @title TokenFactoryRegistry
 * @author Dewiz
 * @notice Central registry and coordinator for all token factories
 * @dev Implements the Abstract Factory pattern by providing a unified interface
 *      to access and manage multiple concrete factory implementations.
 *      This contract serves as the entry point for creating any type of token.
 */
contract TokenFactoryRegistry is Ownable {
    /// @notice Enum representing supported token types
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    /// @notice The ERC-20 factory instance
    IERC20Factory public erc20Factory;

    /// @notice The ERC-721 factory instance
    IERC721Factory public erc721Factory;

    /// @notice The ERC-1155 factory instance
    IERC1155Factory public erc1155Factory;

    /// @notice Mapping of token type to factory address
    mapping(TokenType => address) public factories;

    /// @notice Array of all registered factory addresses
    address[] private _registeredFactories;

    /// @notice Emitted when a factory is registered or updated
    event FactoryRegistered(TokenType indexed tokenType, address indexed factoryAddress);

    /// @notice Emitted when a factory is removed
    event FactoryRemoved(TokenType indexed tokenType, address indexed factoryAddress);

    /// @notice Error thrown when a factory address is zero
    error ZeroAddressFactory();

    /// @notice Error thrown when a factory is not registered
    error FactoryNotRegistered(TokenType tokenType);

    /// @notice Error thrown when the factory type doesn't match
    error InvalidFactoryType();

    /**
     * @notice Creates a new TokenFactoryRegistry
     * @param initialOwner The address that will own the registry
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Registers an ERC-20 factory
     * @param factory The address of the ERC-20 factory
     */
    function registerERC20Factory(address factory) external onlyOwner {
        if (factory == address(0)) revert ZeroAddressFactory();
        
        erc20Factory = IERC20Factory(factory);
        factories[TokenType.ERC20] = factory;
        _addToRegisteredFactories(factory);
        
        emit FactoryRegistered(TokenType.ERC20, factory);
    }

    /**
     * @notice Registers an ERC-721 factory
     * @param factory The address of the ERC-721 factory
     */
    function registerERC721Factory(address factory) external onlyOwner {
        if (factory == address(0)) revert ZeroAddressFactory();
        
        erc721Factory = IERC721Factory(factory);
        factories[TokenType.ERC721] = factory;
        _addToRegisteredFactories(factory);
        
        emit FactoryRegistered(TokenType.ERC721, factory);
    }

    /**
     * @notice Registers an ERC-1155 factory
     * @param factory The address of the ERC-1155 factory
     */
    function registerERC1155Factory(address factory) external onlyOwner {
        if (factory == address(0)) revert ZeroAddressFactory();
        
        erc1155Factory = IERC1155Factory(factory);
        factories[TokenType.ERC1155] = factory;
        _addToRegisteredFactories(factory);
        
        emit FactoryRegistered(TokenType.ERC1155, factory);
    }

    /**
     * @notice Registers all factories at once
     * @param erc20 The address of the ERC-20 factory
     * @param erc721 The address of the ERC-721 factory
     * @param erc1155 The address of the ERC-1155 factory
     */
    function registerAllFactories(
        address erc20,
        address erc721,
        address erc1155
    ) external onlyOwner {
        if (erc20 == address(0) || erc721 == address(0) || erc1155 == address(0)) {
            revert ZeroAddressFactory();
        }

        erc20Factory = IERC20Factory(erc20);
        erc721Factory = IERC721Factory(erc721);
        erc1155Factory = IERC1155Factory(erc1155);

        factories[TokenType.ERC20] = erc20;
        factories[TokenType.ERC721] = erc721;
        factories[TokenType.ERC1155] = erc1155;

        _addToRegisteredFactories(erc20);
        _addToRegisteredFactories(erc721);
        _addToRegisteredFactories(erc1155);

        emit FactoryRegistered(TokenType.ERC20, erc20);
        emit FactoryRegistered(TokenType.ERC721, erc721);
        emit FactoryRegistered(TokenType.ERC1155, erc1155);
    }

    // ============ ERC-20 Token Creation ============

    /**
     * @notice Creates a new ERC-20 token with full parameters
     * @param params The token creation parameters
     * @return tokenAddress The address of the newly created token
     */
    function createERC20Token(
        IERC20Factory.ERC20TokenParams calldata params
    ) external returns (address tokenAddress) {
        if (address(erc20Factory) == address(0)) revert FactoryNotRegistered(TokenType.ERC20);
        return erc20Factory.createToken(params);
    }

    /**
     * @notice Creates a simple ERC-20 token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param initialSupply The initial token supply
     * @return tokenAddress The address of the newly created token
     */
    function createSimpleERC20Token(
        string calldata name,
        string calldata symbol,
        uint256 initialSupply
    ) external returns (address tokenAddress) {
        if (address(erc20Factory) == address(0)) revert FactoryNotRegistered(TokenType.ERC20);
        return erc20Factory.createSimpleToken(name, symbol, initialSupply);
    }

    // ============ ERC-721 Token Creation ============

    /**
     * @notice Creates a new ERC-721 token with full parameters
     * @param params The token creation parameters
     * @return tokenAddress The address of the newly created token
     */
    function createERC721Token(
        IERC721Factory.ERC721TokenParams calldata params
    ) external returns (address tokenAddress) {
        if (address(erc721Factory) == address(0)) revert FactoryNotRegistered(TokenType.ERC721);
        return erc721Factory.createToken(params);
    }

    /**
     * @notice Creates a simple ERC-721 token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param baseURI The base URI for token metadata
     * @return tokenAddress The address of the newly created token
     */
    function createSimpleERC721Token(
        string calldata name,
        string calldata symbol,
        string calldata baseURI
    ) external returns (address tokenAddress) {
        if (address(erc721Factory) == address(0)) revert FactoryNotRegistered(TokenType.ERC721);
        return erc721Factory.createSimpleToken(name, symbol, baseURI);
    }

    // ============ ERC-1155 Token Creation ============

    /**
     * @notice Creates a new ERC-1155 token with full parameters
     * @param params The token creation parameters
     * @return tokenAddress The address of the newly created token
     */
    function createERC1155Token(
        IERC1155Factory.ERC1155TokenParams calldata params
    ) external returns (address tokenAddress) {
        if (address(erc1155Factory) == address(0)) revert FactoryNotRegistered(TokenType.ERC1155);
        return erc1155Factory.createToken(params);
    }

    /**
     * @notice Creates a simple ERC-1155 token
     * @param name The name of the token collection
     * @param symbol The symbol of the token collection
     * @param uri The URI for token metadata
     * @return tokenAddress The address of the newly created token
     */
    function createSimpleERC1155Token(
        string calldata name,
        string calldata symbol,
        string calldata uri
    ) external returns (address tokenAddress) {
        if (address(erc1155Factory) == address(0)) revert FactoryNotRegistered(TokenType.ERC1155);
        return erc1155Factory.createSimpleToken(name, symbol, uri);
    }

    // ============ Query Functions ============

    /**
     * @notice Returns the factory for a specific token type
     * @param tokenType The type of token
     * @return The factory address
     */
    function getFactory(TokenType tokenType) external view returns (address) {
        return factories[tokenType];
    }

    /**
     * @notice Returns all registered factory addresses
     * @return An array of factory addresses
     */
    function getAllFactories() external view returns (address[] memory) {
        return _registeredFactories;
    }

    /**
     * @notice Returns the total count of tokens across all factories
     * @return totalCount The total number of tokens created
     */
    function getTotalTokenCount() external view returns (uint256 totalCount) {
        if (address(erc20Factory) != address(0)) {
            totalCount += erc20Factory.getTokenCount();
        }
        if (address(erc721Factory) != address(0)) {
            totalCount += erc721Factory.getTokenCount();
        }
        if (address(erc1155Factory) != address(0)) {
            totalCount += erc1155Factory.getTokenCount();
        }
    }

    /**
     * @notice Checks if a factory is registered for a token type
     * @param tokenType The type of token
     * @return True if a factory is registered
     */
    function isFactoryRegistered(TokenType tokenType) external view returns (bool) {
        return factories[tokenType] != address(0);
    }

    /**
     * @notice Checks if an address is a token from any registered factory
     * @param tokenAddress The address to check
     * @return True if the address is a token from any factory
     */
    function isTokenFromAnyFactory(address tokenAddress) external view returns (bool) {
        if (address(erc20Factory) != address(0) && erc20Factory.isTokenFromFactory(tokenAddress)) {
            return true;
        }
        if (address(erc721Factory) != address(0) && erc721Factory.isTokenFromFactory(tokenAddress)) {
            return true;
        }
        if (address(erc1155Factory) != address(0) && erc1155Factory.isTokenFromFactory(tokenAddress)) {
            return true;
        }
        return false;
    }

    /**
     * @dev Adds a factory to the registered factories array if not already present
     * @param factory The factory address to add
     */
    function _addToRegisteredFactories(address factory) internal {
        // Check if already registered
        for (uint256 i = 0; i < _registeredFactories.length; i++) {
            if (_registeredFactories[i] == factory) {
                return;
            }
        }
        _registeredFactories.push(factory);
    }
}
