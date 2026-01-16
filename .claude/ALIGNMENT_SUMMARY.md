# Claude Code ↔ GitHub Copilot Configuration Alignment

This document shows how Claude Code configuration aligns with GitHub Copilot instructions.

## Configuration Files Mapping

| Purpose | Copilot | Claude Code |
|---------|---------|-------------|
| Main instructions | `.github/copilot-instructions.md` | `.clauderc` |
| Context exclusions | N/A (implicit) | `.claudeignore` |
| Detailed context | Embedded in copilot-instructions.md | `.claude/project-context.md` |
| Reusable prompts | N/A | `.claude/prompts.md` |

## Key Alignments

### ✅ Code Style & Conventions
Both configurations enforce:
- File header: `// SPDX-License-Identifier: MIT` + `pragma solidity ^0.8.24;`
- Named imports with curly braces
- Custom errors (NEVER require strings)
- NatSpec for all public/external functions
- Same naming conventions (PascalCase, camelCase, SCREAMING_SNAKE, _ prefix)

### ✅ Architecture Understanding
Both know:
- Abstract Factory Pattern implementation
- TokenFactoryRegistry as coordinator
- Three factory types → Three token products
- Token tracking pattern (_tokens[], _isFactoryToken, _creatorTokens)
- Feature flags pattern (immutable booleans)

### ✅ Access Control
Both understand:
- DEFAULT_ADMIN_ROLE, MINTER_ROLE, PAUSER_ROLE, URI_SETTER_ROLE
- Role hierarchy and permissions
- Feature flag checks before operations

### ✅ Testing Standards
Both follow:
- test_FunctionName_Description (success cases)
- test_RevertWhen_Condition (failure cases)
- testFuzz_FunctionName (fuzz tests)
- Arrange-Act-Assert pattern
- Use of makeAddr(), vm.prank(), vm.expectRevert()

### ✅ Security Checklist
Both enforce:
- Access control on privileged functions
- Custom errors only
- Events for state changes
- Zero address checks
- Input validation
- Checks-Effects-Interactions pattern

### ✅ Project Mission & Context
Both understand:
- Enterprise-grade tokenization for financial institutions
- Dewiz's MOAT: reducing legal/technical risk
- RWA tokenization, stablecoins, bonds
- Regulatory compliance (OFAC, SEC, ECB)
- Compliance hook system (NEW)

## Unique to Claude Code

### Reusable Prompts (.claude/prompts.md)
- Security analysis workflow
- Add new token feature workflow
- Create compliance hook workflow
- Deployment checklist
- Test coverage analysis

### Enhanced Context (.claude/project-context.md)
- Detailed compliance system documentation
- Access control hierarchy visualization
- Common workflows with code examples
- Gas optimization patterns
- Key differences from standard tokens

## Usage Recommendation

1. **For detailed code standards**: Both AIs reference `.github/copilot-instructions.md`
2. **For project context**: Both understand architecture and patterns
3. **For workflows**: Claude has additional prompt templates
4. **For quick reference**: Claude `.clauderc` has condensed essentials

## Keeping in Sync

When updating code standards:
1. Update `.github/copilot-instructions.md` (source of truth for code style)
2. Update `.clauderc` if changes affect core patterns
3. Update `.claude/project-context.md` for new architectural components
4. Update `.claude/prompts.md` for new workflows

## Testing Alignment

Both configurations should produce code that:
- ✅ Passes all 202+ tests
- ✅ Follows Solidity style guide
- ✅ Matches existing code patterns exactly
- ✅ Passes Slither analysis
- ✅ Has comprehensive NatSpec
- ✅ Uses custom errors exclusively
