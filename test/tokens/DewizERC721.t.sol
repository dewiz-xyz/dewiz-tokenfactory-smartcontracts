// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {DewizERC721} from "../../src/tokens/DewizERC721.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title DewizERC721Test
 * @author Dewiz
 * @notice Comprehensive tests for the DewizERC721 token contract
 * @dev Tests cover NFT minting, burning, pausing, royalties, and access control
 */
contract DewizERC721Test is Test, IERC721Receiver {
    DewizERC721 public token;
    DewizERC721 public nonMintableToken;
    DewizERC721 public royaltyToken;

    address public admin;
    address public user;
    address public minter;
    address public royaltyReceiver;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    string public constant BASE_URI = "https://api.dewiz.xyz/tokens/";
    uint96 public constant ROYALTY_FEE = 250; // 2.5%

    // ============ Events ============
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event Paused(address account);
    event Unpaused(address account);
    event ComplianceHookUpdated(address oldHook, address newHook);

    function setUp() public {
        admin = makeAddr("admin");
        user = makeAddr("user");
        minter = makeAddr("minter");
        royaltyReceiver = makeAddr("royaltyReceiver");

        // Deploy a full-featured NFT (mintable, burnable, pausable, no royalty)
        vm.prank(admin);
        token = new DewizERC721(
            "Dewiz NFT",
            "DNFT",
            BASE_URI,
            admin,
            true,  // mintable
            true,  // burnable
            true,  // pausable
            false, // no royalty
            address(0),
            0,
            address(0)
        );

        // Deploy non-mintable token
        vm.prank(admin);
        nonMintableToken = new DewizERC721(
            "Non Mintable NFT",
            "NMNFT",
            BASE_URI,
            admin,
            false, // not mintable
            true,  // burnable
            false, // not pausable
            false, // no royalty
            address(0),
            0,
            address(0)
        );

        // Deploy token with royalties
        vm.prank(admin);
        royaltyToken = new DewizERC721(
            "Royalty NFT",
            "RNFT",
            BASE_URI,
            admin,
            true,  // mintable
            true,  // burnable
            false, // not pausable
            true,  // has royalty
            royaltyReceiver,
            ROYALTY_FEE,
            address(0)
        );
    }

    // Implement IERC721Receiver for safe mint tests
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsName() public view {
        assertEq(token.name(), "Dewiz NFT");
    }

    function test_Constructor_SetsSymbol() public view {
        assertEq(token.symbol(), "DNFT");
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

    function test_Constructor_InitializesTotalSupplyZero() public view {
        assertEq(token.totalSupply(), 0);
    }

    // ============ Compliance Hook Tests ============

    function test_SetComplianceHook_Success() public {
        address newHook = makeAddr("newHook");
        
        vm.prank(admin);
        token.setComplianceHook(newHook);
        
        assertEq(address(token.complianceHook()), newHook);
    }

    function test_RevertWhen_SetComplianceHookWithoutAdmin() public {
        address newHook = makeAddr("newHook");
        
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                DEFAULT_ADMIN_ROLE
            )
        );
        
        vm.prank(user);
        token.setComplianceHook(newHook);
    }

    function test_SetComplianceHook_EmitsEvent() public {
        address newHook = makeAddr("newHook");
        
        vm.expectEmit(false, false, false, true);
        emit ComplianceHookUpdated(address(0), newHook);
        
        vm.prank(admin);
        token.setComplianceHook(newHook);
    }

    // ============ Minting Tests ============

    function test_SafeMint_Success() public {
        vm.prank(admin);
        uint256 tokenId = token.safeMint(user);

        assertEq(tokenId, 0);
        assertEq(token.ownerOf(0), user);
        assertEq(token.balanceOf(user), 1);
        assertEq(token.totalSupply(), 1);
    }

    function test_SafeMint_IncrementingIds() public {
        vm.startPrank(admin);
        uint256 id1 = token.safeMint(user);
        uint256 id2 = token.safeMint(user);
        uint256 id3 = token.safeMint(user);
        vm.stopPrank();

        assertEq(id1, 0);
        assertEq(id2, 1);
        assertEq(id3, 2);
    }

    function test_SafeMint_EmitsTransferEvent() public {
        vm.expectEmit(true, true, true, false);
        emit Transfer(address(0), user, 0);

        vm.prank(admin);
        token.safeMint(user);
    }

    function test_SafeMintWithURI_Success() public {
        string memory customURI = "ipfs://QmTest123";

        vm.prank(admin);
        uint256 tokenId = token.safeMintWithURI(user, customURI);

        // tokenURI returns baseURI + customURI when URIStorage is used with a base URI
        // The actual implementation concatenates baseURI with the stored tokenURI
        string memory expectedURI = string(abi.encodePacked(BASE_URI, customURI));
        assertEq(token.tokenURI(tokenId), expectedURI);
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
        token.safeMint(user);
    }

    function test_RevertWhen_MintOnNonMintableToken() public {
        // Grant minter role even though minting is disabled
        vm.prank(admin);
        nonMintableToken.grantRole(MINTER_ROLE, admin);

        vm.expectRevert(DewizERC721.MintingDisabled.selector);

        vm.prank(admin);
        nonMintableToken.safeMint(user);
    }

    // ============ Burning Tests ============

    function test_Burn_Success() public {
        vm.prank(admin);
        uint256 tokenId = token.safeMint(user);

        vm.prank(user);
        token.burn(tokenId);

        vm.expectRevert();
        token.ownerOf(tokenId);
    }

    function test_Burn_ByApprovedAddress() public {
        vm.prank(admin);
        uint256 tokenId = token.safeMint(user);

        vm.prank(user);
        token.approve(admin, tokenId);

        vm.prank(admin);
        token.burn(tokenId);

        vm.expectRevert();
        token.ownerOf(tokenId);
    }

    function test_RevertWhen_BurnOnNonBurnableToken() public {
        // Create a non-burnable token
        vm.prank(admin);
        DewizERC721 nonBurnable = new DewizERC721(
            "Non Burnable",
            "NB",
            BASE_URI,
            admin,
            true,  // mintable
            false, // not burnable
            false,
            false,
            address(0),
            0,
            address(0)
        );

        vm.prank(admin);
        uint256 tokenId = nonBurnable.safeMint(user);

        vm.expectRevert(DewizERC721.BurningDisabled.selector);

        vm.prank(user);
        nonBurnable.burn(tokenId);
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
        uint256 tokenId = token.safeMint(user);

        vm.prank(admin);
        token.pause();

        vm.expectRevert();

        vm.prank(user);
        token.transferFrom(user, admin, tokenId);
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

    function test_RevertWhen_SetTokenRoyaltyWithoutAdmin() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                DEFAULT_ADMIN_ROLE
            )
        );

        vm.prank(user);
        royaltyToken.setTokenRoyalty(1, user, 500);
    }

    // ============ Transfer Tests ============

    function test_Transfer_Success() public {
        vm.prank(admin);
        uint256 tokenId = token.safeMint(user);

        vm.prank(user);
        token.transferFrom(user, admin, tokenId);

        assertEq(token.ownerOf(tokenId), admin);
    }

    function test_SafeTransfer_ToContract() public {
        vm.prank(admin);
        uint256 tokenId = token.safeMint(user);

        vm.prank(user);
        token.safeTransferFrom(user, address(this), tokenId);

        assertEq(token.ownerOf(tokenId), address(this));
    }

    // ============ Token URI Tests ============

    function test_TokenURI_ReturnsBaseURIPlusTokenId() public {
        vm.prank(admin);
        uint256 tokenId = token.safeMint(user);

        // If no specific URI is set, it returns baseURI + tokenId
        string memory uri = token.tokenURI(tokenId);
        assertEq(uri, string(abi.encodePacked(BASE_URI, "0")));
    }

    // ============ SupportsInterface Tests ============

    function test_SupportsInterface_ERC721() public view {
        assertTrue(token.supportsInterface(type(IERC721).interfaceId));
    }

    function test_SupportsInterface_AccessControl() public view {
        assertTrue(token.supportsInterface(type(IAccessControl).interfaceId));
    }

    // ============ Fuzz Tests ============

    function testFuzz_SafeMint_MultipleTokens(uint8 count) public {
        vm.assume(count > 0 && count <= 100);

        vm.startPrank(admin);
        for (uint256 i = 0; i < count; i++) {
            token.safeMint(user);
        }
        vm.stopPrank();

        assertEq(token.balanceOf(user), count);
        assertEq(token.totalSupply(), count);
    }
}
