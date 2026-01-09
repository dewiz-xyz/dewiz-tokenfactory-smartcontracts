// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ERC1155Factory} from "../../src/factories/ERC1155Factory.sol";
import {DewizERC1155} from "../../src/tokens/DewizERC1155.sol";
import {IERC1155Factory} from "../../src/interfaces/IERC1155Factory.sol";

/**
 * @title ERC1155FactoryTest
 * @author Dewiz
 * @notice Comprehensive tests for the ERC1155Factory contract
 * @dev Tests cover factory creation, multi-token creation, and token tracking functionality
 */
contract ERC1155FactoryTest is Test {
    ERC1155Factory public factory;

    address public owner;
    address public user;
    address public user2;
    address public royaltyReceiver;

    string public constant BASE_URI = "https://api.dewiz.xyz/tokens/{id}.json";

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
        royaltyReceiver = makeAddr("royaltyReceiver");

        vm.prank(owner);
        factory = new ERC1155Factory(owner);
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsOwner() public view {
        assertEq(factory.owner(), owner);
    }

    function test_Constructor_InitializesEmptyTokenArray() public view {
        assertEq(factory.getTokenCount(), 0);
    }

    // ============ TokenType Tests ============

    function test_TokenType_ReturnsERC1155() public view {
        assertEq(factory.tokenType(), "ERC1155");
    }

    // ============ CreateToken Tests ============

    function test_CreateToken_WithFullParams() public {
        IERC1155Factory.ERC1155TokenParams memory params = IERC1155Factory.ERC1155TokenParams({
            name: "Test Multi Token",
            symbol: "TMT",
            uri: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: true,
            hasRoyalty: true,
            royaltyReceiver: royaltyReceiver,
            royaltyFeeNumerator: 250
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        DewizERC1155 multiToken = DewizERC1155(tokenAddress);
        assertEq(multiToken.name(), "Test Multi Token");
        assertEq(multiToken.symbol(), "TMT");
        assertTrue(multiToken.mintable());
        assertTrue(multiToken.burnable());
        assertTrue(multiToken.pausable());

        // Verify royalty
        (address receiver, uint256 amount) = multiToken.royaltyInfo(0, 10000);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 250);
    }

    function test_CreateToken_EmitsTokenCreatedEvent() public {
        IERC1155Factory.ERC1155TokenParams memory params = IERC1155Factory.ERC1155TokenParams({
            name: "Event Token",
            symbol: "EVT",
            uri: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        vm.expectEmit(false, true, false, true);
        emit TokenCreated(address(0), user, "Event Token", "EVT");

        vm.prank(user);
        factory.createToken(params);
    }

    function test_CreateToken_IncreasesTokenCount() public {
        IERC1155Factory.ERC1155TokenParams memory params = IERC1155Factory.ERC1155TokenParams({
            name: "Count Token",
            symbol: "CNT",
            uri: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        assertEq(factory.getTokenCount(), 0);

        vm.prank(user);
        factory.createToken(params);

        assertEq(factory.getTokenCount(), 1);
    }

    function test_CreateToken_RegistersTokenInFactory() public {
        IERC1155Factory.ERC1155TokenParams memory params = IERC1155Factory.ERC1155TokenParams({
            name: "Registry Token",
            symbol: "REG",
            uri: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        assertTrue(factory.isTokenFromFactory(tokenAddress));
    }

    function test_CreateToken_SenderIsAdmin() public {
        bytes32 defaultAdminRole = 0x00;

        IERC1155Factory.ERC1155TokenParams memory params = IERC1155Factory.ERC1155TokenParams({
            name: "Admin Token",
            symbol: "ADM",
            uri: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        DewizERC1155 multiToken = DewizERC1155(tokenAddress);
        assertTrue(multiToken.hasRole(defaultAdminRole, user));
    }

    // ============ CreateSimpleToken Tests ============

    function test_CreateSimpleToken_WithDefaults() public {
        vm.prank(user);
        address tokenAddress = factory.createSimpleToken(
            "Simple Multi Token",
            "SMT",
            BASE_URI
        );

        DewizERC1155 multiToken = DewizERC1155(tokenAddress);
        assertEq(multiToken.name(), "Simple Multi Token");
        assertEq(multiToken.symbol(), "SMT");
        assertTrue(multiToken.mintable());
        assertTrue(multiToken.burnable());
        assertFalse(multiToken.pausable());
    }

    function test_CreateSimpleToken_NoRoyalty() public {
        vm.prank(user);
        address tokenAddress = factory.createSimpleToken(
            "No Royalty Token",
            "NRT",
            BASE_URI
        );

        DewizERC1155 multiToken = DewizERC1155(tokenAddress);
        (address receiver, uint256 amount) = multiToken.royaltyInfo(0, 10000);
        assertEq(receiver, address(0));
        assertEq(amount, 0);
    }

    // ============ Token Retrieval Tests ============

    function test_GetTokenAt_ReturnsCorrectAddress() public {
        vm.prank(user);
        address token1 = factory.createSimpleToken("Token1", "T1", BASE_URI);

        vm.prank(user);
        address token2 = factory.createSimpleToken("Token2", "T2", BASE_URI);

        assertEq(factory.getTokenAt(0), token1);
        assertEq(factory.getTokenAt(1), token2);
    }

    function test_GetAllTokens_ReturnsAllTokens() public {
        vm.startPrank(user);
        address token1 = factory.createSimpleToken("Token1", "T1", BASE_URI);
        address token2 = factory.createSimpleToken("Token2", "T2", BASE_URI);
        address token3 = factory.createSimpleToken("Token3", "T3", BASE_URI);
        vm.stopPrank();

        address[] memory allTokens = factory.getAllTokens();
        assertEq(allTokens.length, 3);
        assertEq(allTokens[0], token1);
        assertEq(allTokens[1], token2);
        assertEq(allTokens[2], token3);
    }

    function test_GetTokensByCreator_ReturnsOnlyCreatorsTokens() public {
        vm.prank(user);
        address userToken = factory.createSimpleToken("User Token", "UT", BASE_URI);

        vm.prank(user2);
        factory.createSimpleToken("User2 Token", "U2T", BASE_URI);

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
        address tokenAddress = factory.createSimpleToken("Factory Token", "FT", BASE_URI);

        assertTrue(factory.isTokenFromFactory(tokenAddress));
    }

    function test_IsTokenFromFactory_ReturnsFalseForExternalToken() public {
        vm.prank(user);
        DewizERC1155 externalToken = new DewizERC1155(
            "External",
            "EXT",
            BASE_URI,
            user,
            true,
            true,
            false,
            false,
            address(0),
            0
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
        address token1 = factory.createSimpleToken("Token1", "T1", BASE_URI);
        address token2 = factory.createSimpleToken("Token2", "T2", BASE_URI);
        vm.stopPrank();

        vm.prank(user2);
        address token3 = factory.createSimpleToken("Token3", "T3", BASE_URI);

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

    // ============ Invariant Tests ============

    function invariant_TokenCountMatchesArrayLength() public view {
        assertEq(factory.getTokenCount(), factory.getAllTokens().length);
    }
}
