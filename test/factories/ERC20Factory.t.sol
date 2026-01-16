// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20Factory} from "../../src/factories/ERC20Factory.sol";
import {DewizERC20} from "../../src/tokens/DewizERC20.sol";
import {IERC20Factory} from "../../src/interfaces/IERC20Factory.sol";
import {ITokenFactory} from "../../src/interfaces/ITokenFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC20FactoryTest
 * @author Dewiz
 * @notice Comprehensive tests for the ERC20Factory contract
 * @dev Tests cover factory creation, token creation, and token tracking functionality
 */
contract ERC20FactoryTest is Test {
    ERC20Factory public factory;

    address public owner;
    address public user;
    address public user2;

    uint8 public constant DEFAULT_DECIMALS = 18;

    // ============ Events ============
    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol
    );

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        user2 = makeAddr("user2");

        vm.prank(owner);
        factory = new ERC20Factory(owner);
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsOwner() public view {
        assertEq(factory.owner(), owner);
    }

    function test_Constructor_InitializesEmptyTokenArray() public view {
        assertEq(factory.getTokenCount(), 0);
    }

    // ============ TokenType Tests ============

    function test_TokenType_ReturnsERC20() public view {
        assertEq(factory.tokenType(), "ERC20");
    }

    // ============ CreateToken Tests ============

    function test_CreateToken_WithFullParams() public {
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            initialSupply: 1000 ether,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: true,
            complianceHook: address(0)
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        // Verify token was created correctly
        DewizERC20 token = DewizERC20(tokenAddress);
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
        assertEq(token.balanceOf(user), 1000 ether);
        assertTrue(token.mintable());
        assertTrue(token.burnable());
        assertTrue(token.pausable());
    }

    function test_CreateToken_EmitsTokenCreatedEvent() public {
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Event Token",
            symbol: "EVT",
            decimals: 18,
            initialSupply: 1000 ether,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            complianceHook: address(0)
        });

        vm.expectEmit(false, true, false, true);
        emit TokenCreated(address(0), user, "Event Token", "EVT");

        vm.prank(user);
        factory.createToken(params);
    }

    function test_CreateToken_IncreasesTokenCount() public {
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Count Token",
            symbol: "CNT",
            decimals: 18,
            initialSupply: 1000 ether,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            complianceHook: address(0)
        });

        assertEq(factory.getTokenCount(), 0);

        vm.prank(user);
        factory.createToken(params);

        assertEq(factory.getTokenCount(), 1);
    }

    function test_CreateToken_RegistersTokenInFactory() public {
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Registry Token",
            symbol: "REG",
            decimals: 18,
            initialSupply: 1000 ether,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            complianceHook: address(0)
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        assertTrue(factory.isTokenFromFactory(tokenAddress));
    }

    function test_CreateToken_TracksCreatorTokens() public {
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Creator Token",
            symbol: "CRT",
            decimals: 18,
            initialSupply: 1000 ether,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            complianceHook: address(0)
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        address[] memory userTokens = factory.getTokensByCreator(user);
        assertEq(userTokens.length, 1);
        assertEq(userTokens[0], tokenAddress);
    }

    function test_CreateToken_WithCustomDecimals() public {
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "USDC Clone",
            symbol: "USDC",
            decimals: 6,
            initialSupply: 1000000,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            complianceHook: address(0)
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        DewizERC20 token = DewizERC20(tokenAddress);
        assertEq(token.decimals(), 6);
    }

    function test_CreateToken_NonMintable() public {
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Fixed Supply",
            symbol: "FIX",
            decimals: 18,
            initialSupply: 1000 ether,
            initialHolder: user,
            isMintable: false,
            isBurnable: true,
            isPausable: false,
            complianceHook: address(0)
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        DewizERC20 token = DewizERC20(tokenAddress);
        assertFalse(token.mintable());
    }

    // ============ CreateSimpleToken Tests ============

    function test_CreateSimpleToken_WithDefaults() public {
        vm.prank(user);
        address tokenAddress = factory.createSimpleToken(
            "Simple Token",
            "SMPL",
            1000 ether
        );

        DewizERC20 token = DewizERC20(tokenAddress);
        assertEq(token.name(), "Simple Token");
        assertEq(token.symbol(), "SMPL");
        assertEq(token.decimals(), DEFAULT_DECIMALS);
        assertEq(token.balanceOf(user), 1000 ether);
        assertTrue(token.mintable());
        assertTrue(token.burnable());
        assertFalse(token.pausable());
    }

    function test_CreateSimpleToken_SenderIsInitialHolder() public {
        vm.prank(user);
        address tokenAddress = factory.createSimpleToken(
            "Holder Token",
            "HLD",
            500 ether
        );

        DewizERC20 token = DewizERC20(tokenAddress);
        assertEq(token.balanceOf(user), 500 ether);
    }

    function test_CreateSimpleToken_SenderIsAdmin() public {
        bytes32 defaultAdminRole = 0x00;

        vm.prank(user);
        address tokenAddress = factory.createSimpleToken(
            "Admin Token",
            "ADM",
            500 ether
        );

        DewizERC20 token = DewizERC20(tokenAddress);
        assertTrue(token.hasRole(defaultAdminRole, user));
    }

    // ============ Token Retrieval Tests ============

    function test_GetTokenAt_ReturnsCorrectAddress() public {
        vm.prank(user);
        address token1 = factory.createSimpleToken("Token1", "TK1", 1000 ether);

        vm.prank(user);
        address token2 = factory.createSimpleToken("Token2", "TK2", 2000 ether);

        assertEq(factory.getTokenAt(0), token1);
        assertEq(factory.getTokenAt(1), token2);
    }

    function test_GetAllTokens_ReturnsAllTokens() public {
        vm.startPrank(user);
        address token1 = factory.createSimpleToken("Token1", "TK1", 1000 ether);
        address token2 = factory.createSimpleToken("Token2", "TK2", 2000 ether);
        address token3 = factory.createSimpleToken("Token3", "TK3", 3000 ether);
        vm.stopPrank();

        address[] memory allTokens = factory.getAllTokens();
        assertEq(allTokens.length, 3);
        assertEq(allTokens[0], token1);
        assertEq(allTokens[1], token2);
        assertEq(allTokens[2], token3);
    }

    function test_GetTokensByCreator_ReturnsOnlyCreatorsTokens() public {
        vm.prank(user);
        address userToken = factory.createSimpleToken("User Token", "USR", 1000 ether);

        vm.prank(user2);
        factory.createSimpleToken("User2 Token", "US2", 2000 ether);

        address[] memory userTokens = factory.getTokensByCreator(user);
        assertEq(userTokens.length, 1);
        assertEq(userTokens[0], userToken);
    }

    function test_GetTokensByCreator_ReturnsEmptyForNonCreator() public view {
        address[] memory userTokens = factory.getTokensByCreator(user);
        assertEq(userTokens.length, 0);
    }

    // ============ IsTokenFromFactory Tests ============

    function test_IsTokenFromFactory_ReturnsTrueForFactoryToken() public {
        vm.prank(user);
        address tokenAddress = factory.createSimpleToken("Factory Token", "FAC", 1000 ether);

        assertTrue(factory.isTokenFromFactory(tokenAddress));
    }

    function test_IsTokenFromFactory_ReturnsFalseForExternalToken() public {
        // Deploy a token directly (not through factory)
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
            false,
            address(0)
        );

        assertFalse(factory.isTokenFromFactory(address(externalToken)));
    }

    function test_IsTokenFromFactory_ReturnsFalseForRandomAddress() public {
        address randomAddr = makeAddr("random");
        assertFalse(factory.isTokenFromFactory(randomAddr));
    }

    // ============ Multiple Token Creation Tests ============

    function test_CreateMultipleTokens_TracksAllCorrectly() public {
        vm.startPrank(user);
        address token1 = factory.createSimpleToken("Token1", "TK1", 1000 ether);
        address token2 = factory.createSimpleToken("Token2", "TK2", 2000 ether);
        vm.stopPrank();

        vm.prank(user2);
        address token3 = factory.createSimpleToken("Token3", "TK3", 3000 ether);

        // Verify total count
        assertEq(factory.getTokenCount(), 3);

        // Verify all tokens are registered
        assertTrue(factory.isTokenFromFactory(token1));
        assertTrue(factory.isTokenFromFactory(token2));
        assertTrue(factory.isTokenFromFactory(token3));

        // Verify creator tracking
        assertEq(factory.getTokensByCreator(user).length, 2);
        assertEq(factory.getTokensByCreator(user2).length, 1);
    }

    // ============ Fuzz Tests ============

    function testFuzz_CreateSimpleToken_WithRandomSupply(uint256 supply) public {
        vm.assume(supply > 0 && supply < type(uint128).max);

        vm.prank(user);
        address tokenAddress = factory.createSimpleToken("Fuzz Token", "FUZZ", supply);

        DewizERC20 token = DewizERC20(tokenAddress);
        assertEq(token.totalSupply(), supply);
        assertEq(token.balanceOf(user), supply);
    }

    function testFuzz_CreateToken_WithRandomDecimals(uint8 decimals) public {
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Decimals Token",
            symbol: "DEC",
            decimals: decimals,
            initialSupply: 1000,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            complianceHook: address(0)
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        DewizERC20 token = DewizERC20(tokenAddress);
        assertEq(token.decimals(), decimals);
    }

    // ============ Invariant Tests ============

    function invariant_TokenCountMatchesArrayLength() public view {
        assertEq(factory.getTokenCount(), factory.getAllTokens().length);
    }
}
