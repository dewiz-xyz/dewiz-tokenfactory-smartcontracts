// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IComplianceHook} from "../interfaces/IComplianceHook.sol";

/**
 * @title TemplateComplianceHook
 * @author Dewiz
 * @notice A template implementation of IComplianceHook that allows all operations
 * @dev Use this contract as a starting point for real compliance implementations
 *      or for testing purposes where no restrictions are needed.
 *      This implementation emits events but performs no validation checks.
 */
contract TemplateComplianceHook is IComplianceHook, Ownable {
    
    /**
     * @notice Initializes the compliance hook
     * @param initialOwner The address that will own the contract
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @inheritdoc IComplianceHook
    function onMint(
        address operator,
        address to,
        uint256 id,
        uint256 amount
    ) external override {
        // Template: Add OFAC/KYC checks here
        // e.g. if (isRestricted(to)) revert RestrictedAddress(to);
        
        emit ComplianceValidation(
            this.onMint.selector,
            operator,
            address(0),
            to,
            amount
        );
    }

    /// @inheritdoc IComplianceHook
    function onTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external override {
        // Template: Add checks for blocked addresses or transfer limits
        // e.g. if (isRestricted(from) || isRestricted(to)) revert RestrictedAddress();
        
        emit ComplianceValidation(
            this.onTransfer.selector,
            operator,
            from,
            to,
            amount
        );
    }

    /// @inheritdoc IComplianceHook
    function onBurn(
        address operator,
        address from,
        uint256 id,
        uint256 amount
    ) external override {
        // Template: Add checks if burning is allowed for this user/token
        
        emit ComplianceValidation(
            this.onBurn.selector,
            operator,
            from,
            address(0),
            amount
        );
    }

    /// @inheritdoc IComplianceHook
    function onApproval(
        address operator,
        address owner,
        address spender,
        uint256 id,
        uint256 amount
    ) external override {
        // Template: Add checks if approvals are allowed to specific spenders
        
        emit ComplianceValidation(
            this.onApproval.selector,
            operator,
            owner,
            spender,
            amount
        );
    }

    /// @inheritdoc IComplianceHook
    function isRestricted(address /* account */) external pure override returns (bool) {
        // Template: Check against a sanctions list (e.g. Chainalysis oracle)
        return false;
    }
}
