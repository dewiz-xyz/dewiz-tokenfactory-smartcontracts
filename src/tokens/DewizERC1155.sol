// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DewizERC1155
 * @author Dewiz
 * @notice A feature-rich ERC-1155 token implementation for the Dewiz Token Factory
 * @dev Implements ERC-1155 with optional minting, burning, pausability, supply tracking, and royalty features
 *      Uses OpenZeppelin's AccessControl for role-based permissions
 */
contract DewizERC1155 is 
    ERC1155, 
    ERC1155Burnable, 
    ERC1155Pausable, 
    ERC1155Supply,
    ERC2981,
    AccessControl 
{
    /// @notice Role identifier for minters
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    /// @notice Role identifier for pausers
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role identifier for URI setters
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    /// @notice The name of the token collection
    string public name;

    /// @notice The symbol of the token collection
    string public symbol;

    /// @notice Counter for token type IDs
    uint256 private _nextTokenTypeId;

    /// @notice Whether minting is enabled for this token
    bool public immutable mintable;

    /// @notice Whether burning is enabled for this token
    bool public immutable burnable;

    /// @notice Whether pausing is enabled for this token
    bool public immutable pausable;

    /// @notice The factory that created this token
    address public immutable factory;

    /// @notice Mapping from token ID to its specific URI
    mapping(uint256 => string) private _tokenURIs;

    /// @notice Error thrown when trying to mint on a non-mintable token
    error MintingDisabled();

    /// @notice Error thrown when trying to burn on a non-burnable token
    error BurningDisabled();

    /// @notice Error thrown when trying to pause a non-pausable token
    error PausingDisabled();

    /// @notice Error thrown when arrays have mismatched lengths
    error ArrayLengthMismatch();

    /**
     * @notice Creates a new DewizERC1155 token
     * @param name_ The name of the token collection
     * @param symbol_ The symbol of the token collection
     * @param uri_ The base URI for token metadata
     * @param admin_ The address to receive admin roles
     * @param isMintable_ Whether minting is enabled
     * @param isBurnable_ Whether burning is enabled
     * @param isPausable_ Whether pausing is enabled
     * @param hasRoyalty_ Whether royalties are enabled
     * @param royaltyReceiver_ The address to receive royalties
     * @param royaltyFeeNumerator_ The royalty fee in basis points
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address admin_,
        bool isMintable_,
        bool isBurnable_,
        bool isPausable_,
        bool hasRoyalty_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_
    ) ERC1155(uri_) {
        name = name_;
        symbol = symbol_;
        mintable = isMintable_;
        burnable = isBurnable_;
        pausable = isPausable_;
        factory = msg.sender;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(URI_SETTER_ROLE, admin_);
        
        if (isMintable_) {
            _grantRole(MINTER_ROLE, admin_);
        }
        
        if (isPausable_) {
            _grantRole(PAUSER_ROLE, admin_);
        }

        if (hasRoyalty_ && royaltyReceiver_ != address(0)) {
            _setDefaultRoyalty(royaltyReceiver_, royaltyFeeNumerator_);
        }
    }

    /**
     * @notice Returns the URI for a specific token ID
     * @param tokenId The token ID
     * @return The token URI
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        
        // If there's a specific URI for this token, return it
        if (bytes(tokenURI).length > 0) {
            return tokenURI;
        }
        
        // Otherwise, return the base URI
        return super.uri(tokenId);
    }

    /**
     * @notice Sets the URI for a specific token ID
     * @param tokenId The token ID
     * @param tokenURI The new URI
     */
    function setTokenURI(uint256 tokenId, string calldata tokenURI) external onlyRole(URI_SETTER_ROLE) {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }

    /**
     * @notice Sets the base URI for all tokens
     * @param newuri The new base URI
     */
    function setURI(string calldata newuri) external onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    /**
     * @notice Creates a new token type and mints initial supply
     * @param to The address to mint tokens to
     * @param amount The amount to mint
     * @param data Additional data
     * @return tokenId The ID of the new token type
     */
    function createTokenType(
        address to,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        if (!mintable) revert MintingDisabled();
        tokenId = _nextTokenTypeId++;
        _mint(to, tokenId, amount, data);
    }

    /**
     * @notice Mints tokens of an existing type
     * @param to The address to mint tokens to
     * @param id The token ID
     * @param amount The amount to mint
     * @param data Additional data
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        if (!mintable) revert MintingDisabled();
        _mint(to, id, amount, data);
    }

    /**
     * @notice Mints multiple token types in a batch
     * @param to The address to mint tokens to
     * @param ids The token IDs
     * @param amounts The amounts to mint
     * @param data Additional data
     */
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        if (!mintable) revert MintingDisabled();
        if (ids.length != amounts.length) revert ArrayLengthMismatch();
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @notice Burns tokens from a specific account
     * @param account The account to burn from
     * @param id The token ID
     * @param value The amount to burn
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override {
        if (!burnable) revert BurningDisabled();
        super.burn(account, id, value);
    }

    /**
     * @notice Burns multiple token types in a batch
     * @param account The account to burn from
     * @param ids The token IDs
     * @param values The amounts to burn
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        if (!burnable) revert BurningDisabled();
        super.burnBatch(account, ids, values);
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
     * @notice Sets the royalty info for a specific token
     * @param tokenId The token ID
     * @param receiver The royalty receiver
     * @param feeNumerator The fee in basis points
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Returns the next token type ID
     * @return The next token type ID
     */
    function nextTokenTypeId() external view returns (uint256) {
        return _nextTokenTypeId;
    }

    // Required overrides for multiple inheritance

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
