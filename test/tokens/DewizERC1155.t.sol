// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {DewizERC1155} from "../../src/tokens/DewizERC1155.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title DewizERC1155Test
 * @author Dewiz
 * @notice Comprehensive tests for the DewizERC1155 token contract
 * @dev Tests cover multi-token minting, burning, pausing, royalties, and access control
 */
contract DewizERC1155Test is Test, IERC1155Receiver {
    DewizERC1155 public token;
    DewizERC1155 public nonMintableToken;
    DewizERC1155 public royaltyToken;

    address public admin;
    address public user;
    address public minter;
    address public royaltyReceiver;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    string public constant BASE_URI = "https://api.dewiz.xyz/tokens/{id}.json";
    uint96 public constant ROYALTY_FEE = 250; // 2.5%

    // ============ Events ============
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event URI(string value, uint256 indexed id);
    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        admin = makeAddr("admin");
        user = makeAddr("user");
        minter = makeAddr("minter");
        royaltyReceiver = makeAddr("royaltyReceiver");

        // Deploy a full-featured token (mintable, burnable, pausable)
        vm.prank(admin);
        token = new DewizERC1155(
            "Dewiz Multi Token",
            "DMT",
            BASE_URI,
            admin,
            true,  // mintable
            true,  // burnable
            true,  // pausable
            false, // no royalty
            address(0),
            0
        );

        // Deploy non-mintable token
        vm.prank(admin);
        nonMintableToken = new DewizERC1155(
            "Non Mintable",
            "NM",
            BASE_URI,
            admin,
            false, // not mintable
            true,  // burnable
            false, // not pausable
            false,
            address(0),
            0
        );

        // Deploy token with royalties
        vm.prank(admin);
        royaltyToken = new DewizERC1155(
            "Royalty Token",
            "RT",
            BASE_URI,
            admin,
            true,
            true,
            false,
            true, // has royalty
            royaltyReceiver,
            ROYALTY_FEE
        );
    }

    // Implement IERC1155Receiver for safe transfers
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsName() public view {
        assertEq(token.name(), "Dewiz Multi Token");
    }

    function test_Constructor_SetsSymbol() public view {
        assertEq(token.symbol(), "DMT");
    }

    function test_Constructor_SetsFactory() public view {
        assertEq(token.factory(), admin);
    }

    function test_Constructor_SetsFeatureFlags() public view {
        assertTrue(token.mintable());
        assertTrue(token.burnable());
        assertTrue(token.pausable());
    }

    function test_Constructor_GrantsAdminRole() public view {
        assertTrue(token.hasRole(DEFAULT_ADMIN_ROLE, admin));
    }

    function test_Constructor_GrantsMinterRoleWhenMintable() public view {
        assertTrue(token.hasRole(MINTER_ROLE, admin));
    }

    function test_Constructor_GrantsPauserRoleWhenPausable() public view {
        assertTrue(token.hasRole(PAUSER_ROLE, admin));
    }

    function test_Constructor_GrantsURISetterRole() public view {
        assertTrue(token.hasRole(URI_SETTER_ROLE, admin));
    }

    function test_Constructor_InitializesNextTokenTypeIdToZero() public view {
        assertEq(token.nextTokenTypeId(), 0);
    }

    // ============ CreateTokenType Tests ============

    function test_CreateTokenType_Success() public {
        uint256 amount = 1000;

        vm.prank(admin);
        uint256 tokenId = token.createTokenType(user, amount, "");

        assertEq(tokenId, 0);
        assertEq(token.balanceOf(user, tokenId), amount);
        assertEq(token.totalSupply(tokenId), amount);
    }

    function test_CreateTokenType_IncrementingIds() public {
        vm.startPrank(admin);
        uint256 id1 = token.createTokenType(user, 100, "");
        uint256 id2 = token.createTokenType(user, 200, "");
        uint256 id3 = token.createTokenType(user, 300, "");
        vm.stopPrank();

        assertEq(id1, 0);
        assertEq(id2, 1);
        assertEq(id3, 2);
    }

    function test_RevertWhen_CreateTokenTypeWithoutMinterRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                MINTER_ROLE
            )
        );

        vm.prank(user);
        token.createTokenType(user, 100, "");
    }

    function test_RevertWhen_CreateTokenTypeOnNonMintableToken() public {
        vm.prank(admin);
        nonMintableToken.grantRole(MINTER_ROLE, admin);

        vm.expectRevert(DewizERC1155.MintingDisabled.selector);

        vm.prank(admin);
        nonMintableToken.createTokenType(user, 100, "");
    }

    // ============ Mint Tests ============

    function test_Mint_ExistingTokenType() public {
        vm.prank(admin);
        token.createTokenType(user, 100, "");

        vm.prank(admin);
        token.mint(user, 0, 50, "");

        assertEq(token.balanceOf(user, 0), 150);
    }

    function test_RevertWhen_MintWithoutMinterRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                MINTER_ROLE
            )
        );

        vm.prank(user);
        token.mint(user, 0, 100, "");
    }

    // ============ MintBatch Tests ============

    function test_MintBatch_Success() public {
        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;

        vm.prank(admin);
        token.mintBatch(user, ids, amounts, "");

        assertEq(token.balanceOf(user, 0), 100);
        assertEq(token.balanceOf(user, 1), 200);
        assertEq(token.balanceOf(user, 2), 300);
    }

    function test_RevertWhen_MintBatchArrayLengthMismatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;

        vm.expectRevert(DewizERC1155.ArrayLengthMismatch.selector);

        vm.prank(admin);
        token.mintBatch(user, ids, amounts, "");
    }

    // ============ Burn Tests ============

    function test_Burn_Success() public {
        vm.prank(admin);
        token.createTokenType(user, 100, "");

        vm.prank(user);
        token.burn(user, 0, 30);

        assertEq(token.balanceOf(user, 0), 70);
    }

    function test_RevertWhen_BurnOnNonBurnableToken() public {
        // Create a non-burnable token
        vm.prank(admin);
        DewizERC1155 nonBurnable = new DewizERC1155(
            "Non Burnable",
            "NB",
            BASE_URI,
            admin,
            true,  // mintable
            false, // not burnable
            false,
            false,
            address(0),
            0
        );

        vm.prank(admin);
        nonBurnable.createTokenType(user, 100, "");

        vm.expectRevert(DewizERC1155.BurningDisabled.selector);

        vm.prank(user);
        nonBurnable.burn(user, 0, 30);
    }

    // ============ BurnBatch Tests ============

    function test_BurnBatch_Success() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        uint256[] memory mintAmounts = new uint256[](2);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;

        vm.prank(admin);
        token.mintBatch(user, ids, mintAmounts, "");

        uint256[] memory burnAmounts = new uint256[](2);
        burnAmounts[0] = 30;
        burnAmounts[1] = 50;

        vm.prank(user);
        token.burnBatch(user, ids, burnAmounts);

        assertEq(token.balanceOf(user, 0), 70);
        assertEq(token.balanceOf(user, 1), 150);
    }

    // ============ Pause Tests ============

    function test_Pause_Success() public {
        vm.prank(admin);
        token.pause();

        assertTrue(token.paused());
    }

    function test_Unpause_Success() public {
        vm.startPrank(admin);
        token.pause();
        token.unpause();
        vm.stopPrank();

        assertFalse(token.paused());
    }

    function test_RevertWhen_TransferWhilePaused() public {
        vm.prank(admin);
        token.createTokenType(user, 100, "");

        vm.prank(admin);
        token.pause();

        vm.expectRevert();

        vm.prank(user);
        token.safeTransferFrom(user, admin, 0, 50, "");
    }

    function test_RevertWhen_PauseWithoutRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                PAUSER_ROLE
            )
        );

        vm.prank(user);
        token.pause();
    }

    // ============ URI Tests ============

    function test_URI_ReturnsBaseURI() public view {
        string memory uri = token.uri(0);
        assertEq(uri, BASE_URI);
    }

    function test_SetTokenURI_Success() public {
        string memory customURI = "ipfs://QmCustomURI";

        vm.prank(admin);
        token.setTokenURI(0, customURI);

        assertEq(token.uri(0), customURI);
    }

    function test_SetURI_Success() public {
        string memory newBaseURI = "https://new.api.dewiz.xyz/";

        vm.prank(admin);
        token.setURI(newBaseURI);

        // Token 1 should use new base URI (token 0 might have custom URI)
        assertEq(token.uri(1), newBaseURI);
    }

    function test_RevertWhen_SetTokenURIWithoutRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                URI_SETTER_ROLE
            )
        );

        vm.prank(user);
        token.setTokenURI(0, "ipfs://test");
    }

    // ============ Royalty Tests ============

    function test_Royalty_DefaultRoyaltyInfo() public view {
        (address receiver, uint256 royaltyAmount) = royaltyToken.royaltyInfo(0, 10000);

        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, 250); // 2.5% of 10000
    }

    function test_SetTokenRoyalty_Success() public {
        address newReceiver = makeAddr("newReceiver");
        uint96 newFee = 500; // 5%

        vm.prank(admin);
        royaltyToken.setTokenRoyalty(1, newReceiver, newFee);

        (address receiver, uint256 royaltyAmount) = royaltyToken.royaltyInfo(1, 10000);
        assertEq(receiver, newReceiver);
        assertEq(royaltyAmount, 500);
    }

    // ============ Transfer Tests ============

    function test_SafeTransferFrom_Success() public {
        vm.prank(admin);
        token.createTokenType(user, 100, "");

        vm.prank(user);
        token.safeTransferFrom(user, address(this), 0, 50, "");

        assertEq(token.balanceOf(address(this), 0), 50);
        assertEq(token.balanceOf(user, 0), 50);
    }

    function test_SafeBatchTransferFrom_Success() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        vm.prank(admin);
        token.mintBatch(user, ids, amounts, "");

        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 30;
        transferAmounts[1] = 50;

        vm.prank(user);
        token.safeBatchTransferFrom(user, address(this), ids, transferAmounts, "");

        assertEq(token.balanceOf(address(this), 0), 30);
        assertEq(token.balanceOf(address(this), 1), 50);
    }

    // ============ Supply Tracking Tests ============

    function test_TotalSupply_TracksCorrectly() public {
        vm.prank(admin);
        token.createTokenType(user, 100, "");

        assertEq(token.totalSupply(0), 100);

        vm.prank(admin);
        token.mint(user, 0, 50, "");

        assertEq(token.totalSupply(0), 150);

        vm.prank(user);
        token.burn(user, 0, 30);

        assertEq(token.totalSupply(0), 120);
    }

    function test_Exists_ReturnsCorrectly() public {
        assertFalse(token.exists(0));

        vm.prank(admin);
        token.createTokenType(user, 100, "");

        assertTrue(token.exists(0));
    }

    // ============ Fuzz Tests ============

    function testFuzz_CreateTokenType_RandomAmounts(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);

        vm.prank(admin);
        uint256 tokenId = token.createTokenType(user, amount, "");

        assertEq(token.balanceOf(user, tokenId), amount);
        assertEq(token.totalSupply(tokenId), amount);
    }
}
