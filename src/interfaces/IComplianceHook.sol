// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IComplianceHook
 * @author Dewiz
 * @notice Interface for regulatory compliance checks required by financial institutions
 * @dev Hook methods to be called before state changes in token contracts.
 *      Implementations should ensure OFAC, SEC, and other regulatory compliance.
 *      These methods should revert if the operation violates compliance rules.
 */
interface IComplianceHook {
    /**
     * @notice Emitted when a compliance validation is successfully triggered
     * @param functionSig The signature of the function being validated
     * @param operator The address initiating the transaction
     * @param from The address tokens are moving from (if applicable)
     * @param to The address tokens are moving to (if applicable)
     * @param value The amount or token ID involved
     */
    event ComplianceValidation(
        bytes4 indexed functionSig,
        address indexed operator,
        address from,
        address to,
        uint256 value
    );

    /**
     * @notice Validates a mint operation
     * @param operator The address performing the mint
     * @param to The recipient of the tokens
     * @param id The token ID (for ERC721/1155) or 0 (for ERC20)
     * @param amount The amount to mint (for ERC20/1155) or 1 (for ERC721)
     * @dev Should revert if compliance checks fail
     */
    function onMint(
        address operator,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @notice Validates a transfer operation
     * @param operator The address performing the transfer
     * @param from The sender of the tokens
     * @param to The recipient of the tokens
     * @param id The token ID (for ERC721/1155) or 0 (for ERC20)
     * @param amount The amount to transfer (for ERC20/1155) or 1 (for ERC721)
     * @dev Should revert if compliance checks fail
     */
    function onTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @notice Validates a burn operation
     * @param operator The address performing the burn
     * @param from The owner of the tokens being burned
     * @param id The token ID (for ERC721/1155) or 0 (for ERC20)
     * @param amount The amount to burn (for ERC20/1155) or 1 (for ERC721)
     * @dev Should revert if compliance checks fail
     */
    function onBurn(
        address operator,
        address from,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @notice Validates an approval operation (optional but recommended for SEC compliance)
     * @param operator The address performing the approval
     * @param owner The owner of the tokens
     * @param spender The address being approved
     * @param id The token ID (for ERC721/1155) or 0 (for ERC20)
     * @param amount The amount being approved (for ERC20)
     * @dev Should revert if compliance checks fail
     */
    function onApproval(
        address operator,
        address owner,
        address spender,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @notice Checks if an address is sanctioned or restricted
     * @param account The address to check
     * @return isRestricted True if the address is restricted from holding/transacting
     */
    function isRestricted(address account) external view returns (bool);
}
