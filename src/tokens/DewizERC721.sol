// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IComplianceHook} from "../interfaces/IComplianceHook.sol";

/**
 * @title DewizERC721
 * @author Dewiz
 * @notice A feature-rich ERC-721 token implementation for the Dewiz Token Factory
 * @dev Implements ERC-721 with optional minting, burning, pausability, and royalty features
 *      Uses OpenZeppelin's AccessControl for role-based permissions
 */
contract DewizERC721 is 
    ERC721, 
    ERC721Burnable, 
    ERC721Pausable, 
    ERC721URIStorage, 
    ERC721Royalty, 
    AccessControl 
{
    /// @notice Role identifier for minters
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    /// @notice Role identifier for pausers
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Counter for token IDs
    uint256 private _nextTokenId;

    /// @notice Base URI for token metadata
    string private _baseTokenURI;

    /// @notice Whether minting is enabled for this token
    bool public immutable mintable;

    /// @notice Whether burning is enabled for this token
    bool public immutable burnable;

    /// @notice Whether pausing is enabled for this token
    bool public immutable pausable;

    /// @notice The factory that created this token
    address public immutable factory;

    /// @notice The compliance hook contract
    IComplianceHook public complianceHook;

    /// @notice Emitted when the compliance hook is updated
    event ComplianceHookUpdated(address oldHook, address newHook);

    /// @notice Error thrown when trying to mint on a non-mintable token
    error MintingDisabled();

    /// @notice Error thrown when trying to burn on a non-burnable token
    error BurningDisabled();

    /// @notice Error thrown when trying to pause a non-pausable token
    error PausingDisabled();

    /**
     * @notice Creates a new DewizERC721 token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param baseURI_ The base URI for token metadata
     * @param admin_ The address to receive admin roles
     * @param isMintable_ Whether minting is enabled
     * @param isBurnable_ Whether burning is enabled
     * @param isPausable_ Whether pausing is enabled
     * @param hasRoyalty_ Whether royalties are enabled
     * @param royaltyReceiver_ The address to receive royalties
     * @param royaltyFeeNumerator_ The royalty fee in basis points
     * @param complianceHook_ The compliance hook address (optional)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address admin_,
        bool isMintable_,
        bool isBurnable_,
        bool isPausable_,
        bool hasRoyalty_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_,
        address complianceHook_
    ) ERC721(name_, symbol_) {
        _baseTokenURI = baseURI_;
        mintable = isMintable_;
        burnable = isBurnable_;
        pausable = isPausable_;
        factory = msg.sender;
        complianceHook = IComplianceHook(complianceHook_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        
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
     * @notice Returns the base URI for token metadata
     * @return The base URI string
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Updates the compliance hook contract
     * @param newHook The new compliance hook address
     */
    function setComplianceHook(address newHook) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit ComplianceHookUpdated(address(complianceHook), newHook);
        complianceHook = IComplianceHook(newHook);
    }

    /**
     * @notice Safely mints a new token to the specified address
     * @param to The address to mint the token to
     * @return tokenId The ID of the newly minted token
     */
    function safeMint(address to) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        if (!mintable) revert MintingDisabled();
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    /**
     * @notice Safely mints a new token with a custom URI
     * @param to The address to mint the token to
     * @param uri The token URI
     * @return tokenId The ID of the newly minted token
     */
    function safeMintWithURI(
        address to, 
        string calldata uri
    ) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        if (!mintable) revert MintingDisabled();
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice Burns a token
     * @param tokenId The ID of the token to burn
     */
    function burn(uint256 tokenId) public virtual override {
        if (!burnable) revert BurningDisabled();
        super.burn(tokenId);
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
     * @notice Returns the current token count (next token ID)
     * @return The next token ID to be minted
     */
    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    // Required overrides for multiple inheritance

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) {
        if (address(complianceHook) != address(0) && approved) {
            // value 0 and id 0 used to signify "all"
            complianceHook.onApproval(msg.sender, msg.sender, operator, 0, 0);
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        if (address(complianceHook) != address(0) && to != address(0)) {
            complianceHook.onApproval(msg.sender, msg.sender, to, tokenId, 1);
        }
        super.approve(to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer.
     * @param to The address tokens are transferred to
     * @param tokenId The token ID being transferred
     * @param auth The authorized address for the transfer
     * @return The previous owner of the token
     * @dev External call to complianceHook is made after state changes but before return.
     *      This is intentional to validate transfers. Ensure compliance hooks are gas-efficient.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override(ERC721, ERC721Pausable) returns (address) {
        address previousOwner = super._update(to, tokenId, auth);

        if (address(complianceHook) != address(0)) {
            if (previousOwner == address(0)) {
                 complianceHook.onMint(msg.sender, to, tokenId, 1);
            } else if (to == address(0)) {
                 complianceHook.onBurn(msg.sender, previousOwner, tokenId, 1);
            } else {
                 complianceHook.onTransfer(msg.sender, previousOwner, to, tokenId, 1);
            }
        }

        return previousOwner;
    }
}
