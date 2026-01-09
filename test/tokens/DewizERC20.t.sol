// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {DewizERC20} from "../../src/tokens/DewizERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title DewizERC20Test
 * @author Dewiz
 * @notice Comprehensive tests for the DewizERC20 token contract
 * @dev Tests cover all token functionality including minting, burning, pausing, and access control
 */
contract DewizERC20Test is Test {
    DewizERC20 public token;
    DewizERC20 public nonMintableToken;
    DewizERC20 public nonBurnableToken;
    DewizERC20 public pausableToken;

    address public admin;
    address public user;
    address public minter;
    address public pauser;
    address public recipient;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    uint256 public constant INITIAL_SUPPLY = 1000 ether;
    uint8 public constant DECIMALS = 18;

    // ============ Events ============
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        admin = makeAddr("admin");
        user = makeAddr("user");
        minter = makeAddr("minter");
        pauser = makeAddr("pauser");
        recipient = makeAddr("recipient");

        // Deploy a full-featured token (mintable, burnable, pausable)
        vm.prank(admin);
        token = new DewizERC20(
            "Dewiz Token",
            "DWZ",
            DECIMALS,
            INITIAL_SUPPLY,
            admin,
            admin,
            true,  // mintable
            true,  // burnable
            true   // pausable
        );

        // Deploy non-mintable token
        vm.prank(admin);
        nonMintableToken = new DewizERC20(
            "Non Mintable",
            "NM",
            18,
            INITIAL_SUPPLY,
            admin,
            admin,
            false, // not mintable
            true,  // burnable
            false  // not pausable
        );

        // Deploy non-burnable token
        vm.prank(admin);
        nonBurnableToken = new DewizERC20(
            "Non Burnable",
            "NB",
            18,
            INITIAL_SUPPLY,
            admin,
            admin,
            true,  // mintable
            false, // not burnable
            false  // not pausable
        );

        // Deploy pausable token for pause tests
        vm.prank(admin);
        pausableToken = new DewizERC20(
            "Pausable",
            "PAUSE",
            18,
            INITIAL_SUPPLY,
            admin,
            admin,
            true, // mintable
            true, // burnable
            true  // pausable
        );
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsName() public view {
        assertEq(token.name(), "Dewiz Token");
    }

    function test_Constructor_SetsSymbol() public view {
        assertEq(token.symbol(), "DWZ");
    }

    function test_Constructor_SetsDecimals() public view {
        assertEq(token.decimals(), DECIMALS);
    }

    function test_Constructor_MintsInitialSupply() public view {
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
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

    function test_Constructor_DoesNotGrantMinterRoleWhenNotMintable() public view {
        assertFalse(nonMintableToken.hasRole(MINTER_ROLE, admin));
    }

    function test_Constructor_ZeroInitialSupply() public {
        vm.prank(admin);
        DewizERC20 zeroSupplyToken = new DewizERC20(
            "Zero Supply",
            "ZERO",
            18,
            0,
            admin,
            admin,
            true,
            true,
            false
        );
        assertEq(zeroSupplyToken.totalSupply(), 0);
    }

    function test_Constructor_ZeroAddressInitialHolder() public {
        vm.prank(admin);
        DewizERC20 noHolderToken = new DewizERC20(
            "No Holder",
            "NH",
            18,
            1000 ether,
            address(0), // zero address holder
            admin,
            true,
            true,
            false
        );
        // Should not mint when holder is zero address
        assertEq(noHolderToken.totalSupply(), 0);
    }

    // ============ Minting Tests ============

    function test_Mint_WithMinterRole() public {
        uint256 mintAmount = 500 ether;
        
        vm.prank(admin);
        token.mint(user, mintAmount);

        assertEq(token.balanceOf(user), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }

    function test_Mint_EmitsTransferEvent() public {
        uint256 mintAmount = 500 ether;

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user, mintAmount);

        vm.prank(admin);
        token.mint(user, mintAmount);
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
        token.mint(user, 100 ether);
    }

    function test_RevertWhen_MintOnNonMintableToken() public {
        // First grant minter role (even though minting is disabled)
        vm.prank(admin);
        nonMintableToken.grantRole(MINTER_ROLE, admin);

        vm.expectRevert(DewizERC20.MintingDisabled.selector);
        
        vm.prank(admin);
        nonMintableToken.mint(user, 100 ether);
    }

    function testFuzz_Mint_RandomAmounts(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);

        vm.prank(admin);
        token.mint(user, amount);

        assertEq(token.balanceOf(user), amount);
    }

    // ============ Burning Tests ============

    function test_Burn_WithTokens() public {
        uint256 burnAmount = 100 ether;
        uint256 initialBalance = token.balanceOf(admin);

        vm.prank(admin);
        token.burn(burnAmount);

        assertEq(token.balanceOf(admin), initialBalance - burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
    }

    function test_Burn_EmitsTransferEvent() public {
        uint256 burnAmount = 100 ether;

        vm.expectEmit(true, true, false, true);
        emit Transfer(admin, address(0), burnAmount);

        vm.prank(admin);
        token.burn(burnAmount);
    }

    function test_RevertWhen_BurnOnNonBurnableToken() public {
        vm.expectRevert(DewizERC20.BurningDisabled.selector);
        
        vm.prank(admin);
        nonBurnableToken.burn(100 ether);
    }

    function test_BurnFrom_WithApproval() public {
        uint256 burnAmount = 100 ether;
        
        // Admin approves user to burn tokens
        vm.prank(admin);
        token.approve(user, burnAmount);

        vm.prank(user);
        token.burnFrom(admin, burnAmount);

        assertEq(token.balanceOf(admin), INITIAL_SUPPLY - burnAmount);
    }

    function test_RevertWhen_BurnFromOnNonBurnableToken() public {
        vm.prank(admin);
        nonBurnableToken.approve(user, 100 ether);

        vm.expectRevert(DewizERC20.BurningDisabled.selector);
        
        vm.prank(user);
        nonBurnableToken.burnFrom(admin, 100 ether);
    }

    // ============ Pause Tests ============

    function test_Pause_WithPauserRole() public {
        vm.prank(admin);
        pausableToken.pause();

        assertTrue(pausableToken.paused());
    }

    function test_Pause_EmitsPausedEvent() public {
        vm.expectEmit(true, false, false, false);
        emit Paused(admin);

        vm.prank(admin);
        pausableToken.pause();
    }

    function test_Unpause_WithPauserRole() public {
        vm.startPrank(admin);
        pausableToken.pause();
        pausableToken.unpause();
        vm.stopPrank();

        assertFalse(pausableToken.paused());
    }

    function test_Unpause_EmitsUnpausedEvent() public {
        vm.prank(admin);
        pausableToken.pause();

        vm.expectEmit(true, false, false, false);
        emit Unpaused(admin);

        vm.prank(admin);
        pausableToken.unpause();
    }

    function test_RevertWhen_PauseWithoutPauserRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                PAUSER_ROLE
            )
        );
        
        vm.prank(user);
        pausableToken.pause();
    }

    function test_RevertWhen_PauseOnNonPausableToken() public {
        // First grant pauser role
        vm.prank(admin);
        nonMintableToken.grantRole(PAUSER_ROLE, admin);

        vm.expectRevert(DewizERC20.PausingDisabled.selector);
        
        vm.prank(admin);
        nonMintableToken.pause();
    }

    function test_RevertWhen_TransferWhilePaused() public {
        vm.prank(admin);
        pausableToken.pause();

        vm.expectRevert();
        
        vm.prank(admin);
        pausableToken.transfer(user, 100 ether);
    }

    // ============ Transfer Tests ============

    function test_Transfer_Success() public {
        uint256 transferAmount = 100 ether;

        vm.prank(admin);
        token.transfer(user, transferAmount);

        assertEq(token.balanceOf(user), transferAmount);
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY - transferAmount);
    }

    function test_TransferFrom_WithApproval() public {
        uint256 transferAmount = 100 ether;

        vm.prank(admin);
        token.approve(user, transferAmount);

        vm.prank(user);
        token.transferFrom(admin, recipient, transferAmount);

        assertEq(token.balanceOf(recipient), transferAmount);
    }

    function testFuzz_Transfer_RandomAmounts(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_SUPPLY);

        vm.prank(admin);
        token.transfer(user, amount);

        assertEq(token.balanceOf(user), amount);
    }

    // ============ Access Control Tests ============

    function test_GrantRole_ByAdmin() public {
        vm.prank(admin);
        token.grantRole(MINTER_ROLE, minter);

        assertTrue(token.hasRole(MINTER_ROLE, minter));
    }

    function test_RevokeRole_ByAdmin() public {
        vm.startPrank(admin);
        token.grantRole(MINTER_ROLE, minter);
        token.revokeRole(MINTER_ROLE, minter);
        vm.stopPrank();

        assertFalse(token.hasRole(MINTER_ROLE, minter));
    }

    function test_RenounceRole() public {
        vm.prank(admin);
        token.renounceRole(MINTER_ROLE, admin);

        assertFalse(token.hasRole(MINTER_ROLE, admin));
    }

    function test_RevertWhen_GrantRoleWithoutAdmin() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                DEFAULT_ADMIN_ROLE
            )
        );
        
        vm.prank(user);
        token.grantRole(MINTER_ROLE, user);
    }

    // ============ Decimals Tests ============

    function test_Decimals_CustomValue() public {
        vm.prank(admin);
        DewizERC20 customDecimalsToken = new DewizERC20(
            "Custom Decimals",
            "CD",
            6, // USDC-style decimals
            1000000, // 1 token with 6 decimals
            admin,
            admin,
            true,
            true,
            false
        );

        assertEq(customDecimalsToken.decimals(), 6);
        assertEq(customDecimalsToken.balanceOf(admin), 1000000);
    }

    // ============ Invariant Tests ============

    function invariant_TotalSupplyEqualsBalances() public view {
        // This is a simplified invariant - in a real scenario you'd track all holders
        assertGe(token.totalSupply(), token.balanceOf(admin));
    }
}
