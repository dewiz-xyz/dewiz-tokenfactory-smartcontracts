// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DewizERC20
 * @author Dewiz
 * @notice A feature-rich ERC-20 token implementation for the Dewiz Token Factory
 * @dev Implements ERC-20 with optional minting, burning, and pausability features
 *      Uses OpenZeppelin's AccessControl for role-based permissions
 */
contract DewizERC20 is ERC20, ERC20Burnable, ERC20Pausable, AccessControl {
    /// @notice Role identifier for minters
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    /// @notice Role identifier for pausers
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice The number of decimals for this token
    uint8 private immutable _decimals;

    /// @notice Whether minting is enabled for this token
    bool public immutable mintable;

    /// @notice Whether burning is enabled for this token
    bool public immutable burnable;

    /// @notice Whether pausing is enabled for this token
    bool public immutable pausable;

    /// @notice The factory that created this token
    address public immutable factory;

    /// @notice Error thrown when trying to mint on a non-mintable token
    error MintingDisabled();

    /// @notice Error thrown when trying to burn on a non-burnable token
    error BurningDisabled();

    /// @notice Error thrown when trying to pause a non-pausable token
    error PausingDisabled();

    /**
     * @notice Creates a new DewizERC20 token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param decimals_ The number of decimals
     * @param initialSupply_ The initial supply to mint
     * @param initialHolder_ The address to receive the initial supply
     * @param admin_ The address to receive admin roles
     * @param isMintable_ Whether minting is enabled
     * @param isBurnable_ Whether burning is enabled
     * @param isPausable_ Whether pausing is enabled
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address initialHolder_,
        address admin_,
        bool isMintable_,
        bool isBurnable_,
        bool isPausable_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        mintable = isMintable_;
        burnable = isBurnable_;
        pausable = isPausable_;
        factory = msg.sender;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        
        if (isMintable_) {
            _grantRole(MINTER_ROLE, admin_);
        }
        
        if (isPausable_) {
            _grantRole(PAUSER_ROLE, admin_);
        }

        if (initialSupply_ > 0 && initialHolder_ != address(0)) {
            _mint(initialHolder_, initialSupply_);
        }
    }

    /**
     * @notice Returns the number of decimals for this token
     * @return The number of decimals
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Mints new tokens to the specified address
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (!mintable) revert MintingDisabled();
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from the caller's account
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) public virtual override {
        if (!burnable) revert BurningDisabled();
        super.burn(amount);
    }

    /**
     * @notice Burns tokens from the specified account
     * @param account The account to burn from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public virtual override {
        if (!burnable) revert BurningDisabled();
        super.burnFrom(account, amount);
    }

    /**
     * @notice Pauses all token transfers
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        if (!pausable) revert PausingDisabled();
        _pause();
    }

    /**
     * @notice Unpauses all token transfers
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        if (!pausable) revert PausingDisabled();
        _unpause();
    }

    /**
     * @dev Hook that is called before any transfer of tokens
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
