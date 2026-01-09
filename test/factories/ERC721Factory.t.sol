// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ERC721Factory} from "../../src/factories/ERC721Factory.sol";
import {DewizERC721} from "../../src/tokens/DewizERC721.sol";
import {IERC721Factory} from "../../src/interfaces/IERC721Factory.sol";

/**
 * @title ERC721FactoryTest
 * @author Dewiz
 * @notice Comprehensive tests for the ERC721Factory contract
 * @dev Tests cover factory creation, NFT creation, and token tracking functionality
 */
contract ERC721FactoryTest is Test {
    ERC721Factory public factory;

    address public owner;
    address public user;
    address public user2;
    address public royaltyReceiver;

    string public constant BASE_URI = "https://api.dewiz.xyz/nfts/";

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
        factory = new ERC721Factory(owner);
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsOwner() public view {
        assertEq(factory.owner(), owner);
    }

    function test_Constructor_InitializesEmptyTokenArray() public view {
        assertEq(factory.getTokenCount(), 0);
    }

    // ============ TokenType Tests ============

    function test_TokenType_ReturnsERC721() public view {
        assertEq(factory.tokenType(), "ERC721");
    }

    // ============ CreateToken Tests ============

    function test_CreateToken_WithFullParams() public {
        IERC721Factory.ERC721TokenParams memory params = IERC721Factory.ERC721TokenParams({
            name: "Test NFT",
            symbol: "TNFT",
            baseURI: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: true,
            hasRoyalty: true,
            royaltyReceiver: royaltyReceiver,
            royaltyFeeNumerator: 250
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        DewizERC721 nft = DewizERC721(tokenAddress);
        assertEq(nft.name(), "Test NFT");
        assertEq(nft.symbol(), "TNFT");
        assertTrue(nft.mintable());
        assertTrue(nft.burnable());
        assertTrue(nft.pausable());

        // Verify royalty
        (address receiver, uint256 amount) = nft.royaltyInfo(0, 10000);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 250);
    }

    function test_CreateToken_EmitsTokenCreatedEvent() public {
        IERC721Factory.ERC721TokenParams memory params = IERC721Factory.ERC721TokenParams({
            name: "Event NFT",
            symbol: "EVNT",
            baseURI: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        vm.expectEmit(false, true, false, true);
        emit TokenCreated(address(0), user, "Event NFT", "EVNT");

        vm.prank(user);
        factory.createToken(params);
    }

    function test_CreateToken_IncreasesTokenCount() public {
        IERC721Factory.ERC721TokenParams memory params = IERC721Factory.ERC721TokenParams({
            name: "Count NFT",
            symbol: "CNT",
            baseURI: BASE_URI,
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
        IERC721Factory.ERC721TokenParams memory params = IERC721Factory.ERC721TokenParams({
            name: "Registry NFT",
            symbol: "REG",
            baseURI: BASE_URI,
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

        IERC721Factory.ERC721TokenParams memory params = IERC721Factory.ERC721TokenParams({
            name: "Admin NFT",
            symbol: "ADM",
            baseURI: BASE_URI,
            isMintable: true,
            isBurnable: true,
            isPausable: false,
            hasRoyalty: false,
            royaltyReceiver: address(0),
            royaltyFeeNumerator: 0
        });

        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        DewizERC721 nft = DewizERC721(tokenAddress);
        assertTrue(nft.hasRole(defaultAdminRole, user));
    }

    // ============ CreateSimpleToken Tests ============

    function test_CreateSimpleToken_WithDefaults() public {
        vm.prank(user);
        address tokenAddress = factory.createSimpleToken(
            "Simple NFT",
            "SNFT",
            BASE_URI
        );

        DewizERC721 nft = DewizERC721(tokenAddress);
        assertEq(nft.name(), "Simple NFT");
        assertEq(nft.symbol(), "SNFT");
        assertTrue(nft.mintable());
        assertTrue(nft.burnable());
        assertFalse(nft.pausable());
    }

    function test_CreateSimpleToken_NoRoyalty() public {
        vm.prank(user);
        address tokenAddress = factory.createSimpleToken(
            "No Royalty NFT",
            "NRNFT",
            BASE_URI
        );

        DewizERC721 nft = DewizERC721(tokenAddress);
        (address receiver, uint256 amount) = nft.royaltyInfo(0, 10000);
        assertEq(receiver, address(0));
        assertEq(amount, 0);
    }

    // ============ Token Retrieval Tests ============

    function test_GetTokenAt_ReturnsCorrectAddress() public {
        vm.prank(user);
        address nft1 = factory.createSimpleToken("NFT1", "N1", BASE_URI);

        vm.prank(user);
        address nft2 = factory.createSimpleToken("NFT2", "N2", BASE_URI);

        assertEq(factory.getTokenAt(0), nft1);
        assertEq(factory.getTokenAt(1), nft2);
    }

    function test_GetAllTokens_ReturnsAllTokens() public {
        vm.startPrank(user);
        address nft1 = factory.createSimpleToken("NFT1", "N1", BASE_URI);
        address nft2 = factory.createSimpleToken("NFT2", "N2", BASE_URI);
        address nft3 = factory.createSimpleToken("NFT3", "N3", BASE_URI);
        vm.stopPrank();

        address[] memory allTokens = factory.getAllTokens();
        assertEq(allTokens.length, 3);
        assertEq(allTokens[0], nft1);
        assertEq(allTokens[1], nft2);
        assertEq(allTokens[2], nft3);
    }

    function test_GetTokensByCreator_ReturnsOnlyCreatorsTokens() public {
        vm.prank(user);
        address userToken = factory.createSimpleToken("User NFT", "UNFT", BASE_URI);

        vm.prank(user2);
        factory.createSimpleToken("User2 NFT", "U2NFT", BASE_URI);

        address[] memory userTokens = factory.getTokensByCreator(user);
        assertEq(userTokens.length, 1);
        assertEq(userTokens[0], userToken);
    }

    // ============ IsTokenFromFactory Tests ============

    function test_IsTokenFromFactory_ReturnsTrueForFactoryToken() public {
        vm.prank(user);
        address tokenAddress = factory.createSimpleToken("Factory NFT", "FNFT", BASE_URI);

        assertTrue(factory.isTokenFromFactory(tokenAddress));
    }

    function test_IsTokenFromFactory_ReturnsFalseForExternalToken() public {
        vm.prank(user);
        DewizERC721 externalToken = new DewizERC721(
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

    // ============ Invariant Tests ============

    function invariant_TokenCountMatchesArrayLength() public view {
        assertEq(factory.getTokenCount(), factory.getAllTokens().length);
    }
}
