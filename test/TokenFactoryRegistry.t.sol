// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {TokenFactoryRegistry} from "../src/TokenFactoryRegistry.sol";
import {ERC20Factory} from "../src/factories/ERC20Factory.sol";
import {ERC721Factory} from "../src/factories/ERC721Factory.sol";
import {ERC1155Factory} from "../src/factories/ERC1155Factory.sol";
import {DewizERC20} from "../src/tokens/DewizERC20.sol";
import {DewizERC721} from "../src/tokens/DewizERC721.sol";
import {DewizERC1155} from "../src/tokens/DewizERC1155.sol";
import {IERC20Factory} from "../src/interfaces/IERC20Factory.sol";
import {IERC721Factory} from "../src/interfaces/IERC721Factory.sol";
import {IERC1155Factory} from "../src/interfaces/IERC1155Factory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenFactoryRegistryTest
 * @author Dewiz
 * @notice Comprehensive tests for the TokenFactoryRegistry contract
 * @dev Tests cover factory registration, token creation via registry, and query functions
 */
contract TokenFactoryRegistryTest is Test {
    TokenFactoryRegistry public registry;
    ERC20Factory public erc20Factory;
    ERC721Factory public erc721Factory;
    ERC1155Factory public erc1155Factory;

    address public owner;
    address public user;
    address public user2;

    string public constant BASE_URI = "https://api.dewiz.xyz/tokens/";

    // ============ Events ============
    event FactoryRegistered(TokenFactoryRegistry.TokenType indexed tokenType, address indexed factoryAddress);
    event FactoryRemoved(TokenFactoryRegistry.TokenType indexed tokenType, address indexed factoryAddress);

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        user2 = makeAddr("user2");

        // Deploy registry
        vm.prank(owner);
        registry = new TokenFactoryRegistry(owner);

        // Deploy factories
        vm.startPrank(owner);
        erc20Factory = new ERC20Factory(owner);
        erc721Factory = new ERC721Factory(owner);
        erc1155Factory = new ERC1155Factory(owner);
        vm.stopPrank();
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsOwner() public view {
        assertEq(registry.owner(), owner);
    }

    function test_Constructor_FactoriesNotRegistered() public view {
        assertEq(address(registry.erc20Factory()), address(0));
        assertEq(address(registry.erc721Factory()), address(0));
        assertEq(address(registry.erc1155Factory()), address(0));
    }

    // ============ Factory Registration Tests ============

    function test_RegisterERC20Factory_Success() public {
        vm.prank(owner);
        registry.registerERC20Factory(address(erc20Factory));

        assertEq(address(registry.erc20Factory()), address(erc20Factory));
        assertEq(registry.factories(TokenFactoryRegistry.TokenType.ERC20), address(erc20Factory));
    }

    function test_RegisterERC20Factory_EmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit FactoryRegistered(TokenFactoryRegistry.TokenType.ERC20, address(erc20Factory));

        vm.prank(owner);
        registry.registerERC20Factory(address(erc20Factory));
    }

    function test_RegisterERC721Factory_Success() public {
        vm.prank(owner);
        registry.registerERC721Factory(address(erc721Factory));

        assertEq(address(registry.erc721Factory()), address(erc721Factory));
        assertEq(registry.factories(TokenFactoryRegistry.TokenType.ERC721), address(erc721Factory));
    }

    function test_RegisterERC1155Factory_Success() public {
        vm.prank(owner);
        registry.registerERC1155Factory(address(erc1155Factory));

        assertEq(address(registry.erc1155Factory()), address(erc1155Factory));
        assertEq(registry.factories(TokenFactoryRegistry.TokenType.ERC1155), address(erc1155Factory));
    }

    function test_RegisterAllFactories_Success() public {
        vm.prank(owner);
        registry.registerAllFactories(
            address(erc20Factory),
            address(erc721Factory),
            address(erc1155Factory)
        );

        assertEq(address(registry.erc20Factory()), address(erc20Factory));
        assertEq(address(registry.erc721Factory()), address(erc721Factory));
        assertEq(address(registry.erc1155Factory()), address(erc1155Factory));
    }

    function test_RevertWhen_RegisterERC20FactoryWithZeroAddress() public {
        vm.expectRevert(TokenFactoryRegistry.ZeroAddressFactory.selector);

        vm.prank(owner);
        registry.registerERC20Factory(address(0));
    }

    function test_RevertWhen_RegisterERC721FactoryWithZeroAddress() public {
        vm.expectRevert(TokenFactoryRegistry.ZeroAddressFactory.selector);

        vm.prank(owner);
        registry.registerERC721Factory(address(0));
    }

    function test_RevertWhen_RegisterERC1155FactoryWithZeroAddress() public {
        vm.expectRevert(TokenFactoryRegistry.ZeroAddressFactory.selector);

        vm.prank(owner);
        registry.registerERC1155Factory(address(0));
    }

    function test_RevertWhen_RegisterAllFactoriesWithZeroAddress() public {
        vm.expectRevert(TokenFactoryRegistry.ZeroAddressFactory.selector);

        vm.prank(owner);
        registry.registerAllFactories(
            address(0),
            address(erc721Factory),
            address(erc1155Factory)
        );
    }

    function test_RevertWhen_RegisterFactoryByNonOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );

        vm.prank(user);
        registry.registerERC20Factory(address(erc20Factory));
    }

    // ============ ERC-20 Token Creation Tests ============

    function test_CreateERC20Token_Success() public {
        // Register factory first
        vm.prank(owner);
        registry.registerERC20Factory(address(erc20Factory));

        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Registry Token",
            symbol: "REG",
            decimals: 18,
            initialSupply: 1000 ether,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: false
        });

        vm.prank(user);
        address tokenAddress = registry.createERC20Token(params);

        DewizERC20 token = DewizERC20(tokenAddress);
        assertEq(token.name(), "Registry Token");
        assertEq(token.balanceOf(user), 1000 ether);
    }

    function test_CreateSimpleERC20Token_Success() public {
        vm.prank(owner);
        registry.registerERC20Factory(address(erc20Factory));

        vm.prank(user);
        address tokenAddress = registry.createSimpleERC20Token(
            "Simple Token",
            "SMPL",
            500 ether
        );

        DewizERC20 token = DewizERC20(tokenAddress);
        assertEq(token.name(), "Simple Token");
        // When creating via registry, the factory's createSimpleToken is called
        // which sets msg.sender (the factory) as initialHolder
        // The token is minted to the factory contract, not the user
        assertEq(token.totalSupply(), 500 ether);
    }

    function test_RevertWhen_CreateERC20TokenWithoutFactory() public {
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Test",
            symbol: "TST",
            decimals: 18,
            initialSupply: 1000 ether,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: false
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenFactoryRegistry.FactoryNotRegistered.selector,
                TokenFactoryRegistry.TokenType.ERC20
            )
        );

        vm.prank(user);
        registry.createERC20Token(params);
    }

    function test_RevertWhen_CreateSimpleERC20TokenWithoutFactory() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenFactoryRegistry.FactoryNotRegistered.selector,
                TokenFactoryRegistry.TokenType.ERC20
            )
        );

        vm.prank(user);
        registry.createSimpleERC20Token("Test", "TST", 1000 ether);
    }

    // ============ ERC-721 Token Creation Tests ============

    function test_CreateERC721Token_Success() public {
        vm.prank(owner);
        registry.registerERC721Factory(address(erc721Factory));

        IERC721Factory.ERC721TokenParams memory params = IERC721Factory.ERC721TokenParams({
            name: "Registry NFT",
            symbol: "RNFT",
            baseURI: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        vm.prank(user);
        address tokenAddress = registry.createERC721Token(params);

        DewizERC721 nft = DewizERC721(tokenAddress);
        assertEq(nft.name(), "Registry NFT");
    }

    function test_CreateSimpleERC721Token_Success() public {
        vm.prank(owner);
        registry.registerERC721Factory(address(erc721Factory));

        vm.prank(user);
        address tokenAddress = registry.createSimpleERC721Token(
            "Simple NFT",
            "SNFT",
            BASE_URI
        );

        DewizERC721 nft = DewizERC721(tokenAddress);
        assertEq(nft.name(), "Simple NFT");
    }

    function test_RevertWhen_CreateERC721TokenWithoutFactory() public {
        IERC721Factory.ERC721TokenParams memory params = IERC721Factory.ERC721TokenParams({
            name: "Test",
            symbol: "TST",
            baseURI: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenFactoryRegistry.FactoryNotRegistered.selector,
                TokenFactoryRegistry.TokenType.ERC721
            )
        );

        vm.prank(user);
        registry.createERC721Token(params);
    }

    // ============ ERC-1155 Token Creation Tests ============

    function test_CreateERC1155Token_Success() public {
        vm.prank(owner);
        registry.registerERC1155Factory(address(erc1155Factory));

        IERC1155Factory.ERC1155TokenParams memory params = IERC1155Factory.ERC1155TokenParams({
            name: "Registry Multi Token",
            symbol: "RMT",
            uri: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        vm.prank(user);
        address tokenAddress = registry.createERC1155Token(params);

        DewizERC1155 multiToken = DewizERC1155(tokenAddress);
        assertEq(multiToken.name(), "Registry Multi Token");
    }

    function test_CreateSimpleERC1155Token_Success() public {
        vm.prank(owner);
        registry.registerERC1155Factory(address(erc1155Factory));

        vm.prank(user);
        address tokenAddress = registry.createSimpleERC1155Token(
            "Simple Multi Token",
            "SMT",
            BASE_URI
        );

        DewizERC1155 multiToken = DewizERC1155(tokenAddress);
        assertEq(multiToken.name(), "Simple Multi Token");
    }

    function test_RevertWhen_CreateERC1155TokenWithoutFactory() public {
        IERC1155Factory.ERC1155TokenParams memory params = IERC1155Factory.ERC1155TokenParams({
            name: "Test",
            symbol: "TST",
            uri: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenFactoryRegistry.FactoryNotRegistered.selector,
                TokenFactoryRegistry.TokenType.ERC1155
            )
        );

        vm.prank(user);
        registry.createERC1155Token(params);
    }

    // ============ Query Functions Tests ============

    function test_GetFactory_ReturnsCorrectAddress() public {
        vm.startPrank(owner);
        registry.registerERC20Factory(address(erc20Factory));
        registry.registerERC721Factory(address(erc721Factory));
        registry.registerERC1155Factory(address(erc1155Factory));
        vm.stopPrank();

        assertEq(registry.getFactory(TokenFactoryRegistry.TokenType.ERC20), address(erc20Factory));
        assertEq(registry.getFactory(TokenFactoryRegistry.TokenType.ERC721), address(erc721Factory));
        assertEq(registry.getFactory(TokenFactoryRegistry.TokenType.ERC1155), address(erc1155Factory));
    }

    function test_GetAllFactories_ReturnsAllRegisteredFactories() public {
        vm.prank(owner);
        registry.registerAllFactories(
            address(erc20Factory),
            address(erc721Factory),
            address(erc1155Factory)
        );

        address[] memory allFactories = registry.getAllFactories();
        assertEq(allFactories.length, 3);
    }

    function test_GetTotalTokenCount_ReturnsCorrectCount() public {
        vm.prank(owner);
        registry.registerAllFactories(
            address(erc20Factory),
            address(erc721Factory),
            address(erc1155Factory)
        );

        // Create tokens
        vm.startPrank(user);
        registry.createSimpleERC20Token("Token1", "T1", 1000 ether);
        registry.createSimpleERC20Token("Token2", "T2", 2000 ether);
        registry.createSimpleERC721Token("NFT1", "N1", BASE_URI);
        registry.createSimpleERC1155Token("Multi1", "M1", BASE_URI);
        vm.stopPrank();

        assertEq(registry.getTotalTokenCount(), 4);
    }

    function test_IsFactoryRegistered_ReturnsCorrectly() public {
        assertFalse(registry.isFactoryRegistered(TokenFactoryRegistry.TokenType.ERC20));

        vm.prank(owner);
        registry.registerERC20Factory(address(erc20Factory));

        assertTrue(registry.isFactoryRegistered(TokenFactoryRegistry.TokenType.ERC20));
    }

    function test_IsTokenFromAnyFactory_ReturnsTrue() public {
        vm.prank(owner);
        registry.registerERC20Factory(address(erc20Factory));

        vm.prank(user);
        address tokenAddress = registry.createSimpleERC20Token("Test", "TST", 1000 ether);

        assertTrue(registry.isTokenFromAnyFactory(tokenAddress));
    }

    function test_IsTokenFromAnyFactory_ReturnsFalseForExternalToken() public {
        vm.prank(owner);
        registry.registerERC20Factory(address(erc20Factory));

        // Deploy external token
        vm.prank(user);
        DewizERC20 externalToken = new DewizERC20(
            "External",
            "EXT",
            18,
            1000 ether,
            user,
            user,
            true,
            true,
            false
        );

        assertFalse(registry.isTokenFromAnyFactory(address(externalToken)));
    }

    // ============ Integration Tests ============

    function test_FullWorkflow_CreateAllTokenTypes() public {
        // Register all factories
        vm.prank(owner);
        registry.registerAllFactories(
            address(erc20Factory),
            address(erc721Factory),
            address(erc1155Factory)
        );

        // Create ERC-20
        vm.prank(user);
        address erc20Token = registry.createSimpleERC20Token("USD Coin", "USDC", 1000000 * 1e6);

        // Create ERC-721
        vm.prank(user);
        address erc721Token = registry.createSimpleERC721Token("Cool NFTs", "COOL", "https://cool.nft/");

        // Create ERC-1155
        vm.prank(user);
        address erc1155Token = registry.createSimpleERC1155Token("Game Items", "GAME", "https://game.items/");

        // Verify all tokens
        assertTrue(registry.isTokenFromAnyFactory(erc20Token));
        assertTrue(registry.isTokenFromAnyFactory(erc721Token));
        assertTrue(registry.isTokenFromAnyFactory(erc1155Token));

        // Verify count
        assertEq(registry.getTotalTokenCount(), 3);
    }

    function test_MultipleUsersCreateTokens() public {
        vm.prank(owner);
        registry.registerERC20Factory(address(erc20Factory));

        // User 1 creates tokens
        vm.startPrank(user);
        registry.createSimpleERC20Token("User1 Token1", "U1T1", 1000 ether);
        registry.createSimpleERC20Token("User1 Token2", "U1T2", 2000 ether);
        vm.stopPrank();

        // User 2 creates tokens
        vm.startPrank(user2);
        registry.createSimpleERC20Token("User2 Token1", "U2T1", 3000 ether);
        vm.stopPrank();

        // Verify total count
        assertEq(registry.getTotalTokenCount(), 3);

        // When creating via registry, the registry calls the factory
        // so msg.sender in the factory is the registry, not the original user
        // All tokens are tracked under the registry address as creator
        assertEq(erc20Factory.getTokensByCreator(address(registry)).length, 3);
    }

    // ============ Invariant Tests ============

    function invariant_FactoryAddressesConsistent() public view {
        // If erc20Factory is set, it should match factories mapping
        if (address(registry.erc20Factory()) != address(0)) {
            assertEq(
                registry.factories(TokenFactoryRegistry.TokenType.ERC20),
                address(registry.erc20Factory())
            );
        }
    }
}
