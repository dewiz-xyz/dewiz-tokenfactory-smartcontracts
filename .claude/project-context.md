# Dewiz Token Factory - Project Context for Claude

> This document supplements .github/copilot-instructions.md with Claude-specific context

## Project Mission

Dewiz's MOAT is **reducing legal and technical risk for enterprise clients** based on years of experience in Corporate and MakerDAO/Sky ecosystem. We "de-wizardry" DeFi to make it accessible to Financial Institutions.

## What This Project Enables

- **Stablecoins**: For payments and international remittances
- **RWA Tokenization**: Real estate, commodities, securities
- **Government/Corporate Bonds**: Tokenized debt instruments
- **Compliance Integration**: OFAC, SEC, ECB regulatory adherence

## Architecture Pattern: Abstract Factory

```
┌─────────────────────────────────────────────────────────────┐
│                   TokenFactoryRegistry                       │
│              (Abstract Factory Coordinator)                  │
│           Uses: Ownable, delegates token creation            │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  ERC20Factory   │  │  ERC721Factory  │  │ ERC1155Factory  │
│  (Ownable)      │  │  (Ownable)      │  │  (Ownable)      │
│  implements:    │  │  implements:    │  │  implements:    │
│  IERC20Factory  │  │  IERC721Factory │  │ IERC1155Factory │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   DewizERC20    │  │   DewizERC721   │  │  DewizERC1155   │
│   (Product)     │  │   (Product)     │  │   (Product)     │
│  AccessControl  │  │  AccessControl  │  │  AccessControl  │
│  + Burnable     │  │  + URIStorage   │  │  + Supply       │
│  + Pausable     │  │  + ERC2981      │  │  + ERC2981      │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Core Components (src/)

### 1. TokenFactoryRegistry (Coordinator)
- **Purpose**: Central entry point for all token creation
- **Pattern**: Abstract Factory client/coordinator
- **Key Functions**:
  - `registerERC20Factory()`, `registerERC721Factory()`, `registerERC1155Factory()`
  - `createERC20Token()`, `createERC721Token()`, `createERC1155Token()`
  - `createSimpleERC20Token()`, etc. (convenience methods)
  - `isTokenFromAnyFactory()` (cross-factory verification)

### 2. Factories (src/factories/)
Each factory:
- Implements `ITokenFactory` + specific interface (IERC20Factory, etc.)
- Extends `Ownable`
- Tracks tokens: `_tokens[]`, `_isFactoryToken`, `_creatorTokens`
- Provides `createToken()` (advanced) and `createSimpleToken()` (basic)

**Token Tracking Pattern:**
```solidity
address[] private _tokens;
mapping(address => bool) private _isFactoryToken;
mapping(address => address[]) private _creatorTokens;

function _registerToken(...) internal {
    _tokens.push(tokenAddress);
    _isFactoryToken[tokenAddress] = true;
    _creatorTokens[msg.sender].push(tokenAddress);
    emit TokenCreated(tokenAddress, msg.sender, name, symbol);
}
```

### 3. Token Implementations (src/tokens/)

**DewizERC20:**
- ERC20 + ERC20Burnable + ERC20Pausable + AccessControl
- Feature flags: `mintable`, `burnable`, `pausable` (immutable)
- Configurable decimals
- Optional initial supply
- Compliance hook support

**DewizERC721:**
- ERC721 + ERC721Burnable + ERC721Pausable + ERC721URIStorage + ERC721Royalty + AccessControl
- Auto-incrementing token IDs
- Per-token URI storage
- ERC2981 royalty support
- Compliance hook support

**DewizERC1155:**
- ERC1155 + ERC1155Burnable + ERC1155Pausable + ERC1155Supply + ERC2981 + AccessControl
- Token type creation system
- Per-token URIs
- Supply tracking
- Batch operations
- Compliance hook support

### 4. Compliance System (NEW)

**IComplianceHook Interface:**
```solidity
interface IComplianceHook {
    function onMint(address operator, address to, uint256 id, uint256 amount) external;
    function onTransfer(address operator, address from, address to, uint256 id, uint256 amount) external;
    function onBurn(address operator, address from, uint256 id, uint256 amount) external;
    function onApproval(address operator, address tokenOwner, address spender, uint256 id, uint256 amount) external;
    function isRestricted(address account) external view returns (bool);
}
```

**TemplateComplianceHook:**
- Reference implementation (allows all operations)
- Emits events for validation tracking
- Template for real compliance implementations (OFAC, KYC/AML, etc.)

**Integration:**
- Tokens have `complianceHook` storage (optional, updatable)
- `setComplianceHook()` - admin can update/remove
- Hooks called in `_update()` and approval functions
- **INTENTIONAL DESIGN**: External calls in loops for batch validation

## Access Control Hierarchy

```
DEFAULT_ADMIN_ROLE (full control)
    ├── Can grant/revoke all roles
    ├── Can set compliance hooks
    └── Can update URIs (ERC1155)

MINTER_ROLE (if mintable=true)
    └── Can call mint() functions

PAUSER_ROLE (if pausable=true)
    ├── Can call pause()
    └── Can call unpause()

URI_SETTER_ROLE (ERC1155/ERC721)
    └── Can update token URIs
```

## Feature Flags Pattern

Tokens use **immutable feature flags** set in constructor:
```solidity
bool public immutable mintable;   // Can tokens be minted after creation?
bool public immutable burnable;   // Can tokens be burned?
bool public immutable pausable;   // Can transfers be paused?

// Usage:
function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
    if (!mintable) revert MintingDisabled();
    _mint(to, amount);
}
```

## Gas Optimization Patterns

1. **Array Length Caching:**
```solidity
uint256 length = ids.length;
for (uint256 i = 0; i < length; i++) { ... }
```

2. **Immutables Over Storage:**
```solidity
address public immutable factory;  // Set once in constructor
bool public immutable mintable;    // Never changes
```

3. **Custom Errors (not require):**
```solidity
error MintingDisabled();
if (!mintable) revert MintingDisabled();
```

## Security Patterns

### 1. Checks-Effects-Interactions
```solidity
// ✅ Correct pattern (used in factories)
function createToken(...) external returns (address tokenAddress) {
    // Interaction (contract creation)
    DewizERC20 token = new DewizERC20(...);
    tokenAddress = address(token);

    // Effects (state changes)
    _registerToken(tokenAddress, name, symbol);
}
```

### 2. Access Control on All Privileged Functions
```solidity
function mint(address to, uint256 amount)
    external
    onlyRole(MINTER_ROLE)  // ✅ Access control
{
    if (!mintable) revert MintingDisabled();  // ✅ Feature flag check
    _mint(to, amount);
}
```

### 3. Input Validation
```solidity
function registerERC20Factory(address factory) external onlyOwner {
    if (factory == address(0)) revert ZeroAddressFactory();  // ✅ Zero check
    // ... rest of function
}
```

## Testing Architecture

**Test File Structure:**
```
test/
├── TokenFactoryRegistry.t.sol    # Registry tests
├── factories/
│   ├── ERC20Factory.t.sol
│   ├── ERC721Factory.t.sol
│   └── ERC1155Factory.t.sol
└── tokens/
    ├── DewizERC20.t.sol
    ├── DewizERC721.t.sol
    └── DewizERC1155.t.sol
```

**Test Coverage: 202+ tests**
- Unit tests per contract
- Integration tests for workflows
- Fuzz tests for edge cases
- Access control verification
- Event emission checks
- Gas optimization tests

## Common Workflows

### 1. Deploy Full System
```solidity
// 1. Deploy registry
TokenFactoryRegistry registry = new TokenFactoryRegistry(owner);

// 2. Deploy factories
ERC20Factory erc20Factory = new ERC20Factory(owner);
ERC721Factory erc721Factory = new ERC721Factory(owner);
ERC1155Factory erc1155Factory = new ERC1155Factory(owner);

// 3. Register factories
registry.registerAllFactories(
    address(erc20Factory),
    address(erc721Factory),
    address(erc1155Factory)
);
```

### 2. Create Token with Compliance
```solidity
// Create token
address token = registry.createSimpleERC20Token("USDC", "USDC", 1_000_000e6);

// Deploy compliance hook
TemplateComplianceHook hook = new TemplateComplianceHook(owner);

// Attach compliance
DewizERC20(token).setComplianceHook(address(hook));
```

### 3. Manage Token Lifecycle
```solidity
// Grant minting rights
token.grantRole(MINTER_ROLE, minter);

// Mint tokens
token.mint(recipient, amount);

// Pause in emergency
token.pause();

// Resume
token.unpause();
```

## Key Differences from Standard Tokens

1. **Factory Creation**: Tokens created via factories, not direct deployment
2. **Factory Tracking**: Each token stores its `factory` address (immutable)
3. **Feature Flags**: Optional capabilities controlled by immutable booleans
4. **Compliance Integration**: Optional hooks for regulatory requirements
5. **Registry System**: Centralized tracking across all token types

## When Adding New Features

1. ✅ Follow existing patterns (especially token tracking)
2. ✅ Add to ALL three token types (ERC20, ERC721, ERC1155) if applicable
3. ✅ Update factory interfaces if needed
4. ✅ Write comprehensive tests
5. ✅ Add NatSpec documentation
6. ✅ Run Slither analysis
7. ✅ Update this context document

## Commit Message Standards (Conventional Commits)

All commit messages and PR titles MUST follow the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification.

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature | `feat(ERC20): add compliance hook support` |
| `fix` | Bug fix | `fix(factory): prevent address(0) admin` |
| `docs` | Documentation only | `docs: update README with deployment guide` |
| `style` | Code style changes (formatting, etc.) | `style: format contracts with prettier` |
| `refactor` | Code change that neither fixes bug nor adds feature | `refactor(registry): optimize factory lookup` |
| `perf` | Performance improvement | `perf(ERC1155): cache array length in loop` |
| `test` | Adding or updating tests | `test(ERC20): add reentrancy attack scenarios` |
| `build` | Build system or dependencies | `build: upgrade to OpenZeppelin 5.1.0` |
| `ci` | CI/CD changes | `ci: add Slither static analysis workflow` |
| `chore` | Maintenance tasks | `chore: clean up unused imports` |
| `revert` | Revert previous commit | `revert: "feat: add batch minting"` |

### Scopes (Optional but Recommended)

Use these to indicate which part of the codebase is affected:

- `ERC20`, `ERC721`, `ERC1155` - Specific token implementations
- `factory` - Factory contracts
- `registry` - TokenFactoryRegistry
- `compliance` - Compliance hook system
- `security` - Security-related changes
- `gas` - Gas optimization changes
- `deploy` - Deployment scripts

### Breaking Changes

**IMPORTANT**: Breaking changes MUST be indicated with `!` after type/scope OR in footer:

```
feat(ERC20)!: remove deprecated createTokenV1 function

BREAKING CHANGE: createTokenV1 has been removed. Use createToken instead.
```

OR:

```
feat(ERC20): add compliance hook support

BREAKING CHANGE: Token constructor now requires complianceHook parameter.
Existing deployments must pass address(0) for no compliance.
```

### Examples

**Good commit messages:**

```
feat(compliance): add IComplianceHook interface

Add standardized interface for regulatory compliance hooks.
Supports onMint, onTransfer, onBurn, and onApproval callbacks.

Closes #42
```

```
fix(ERC1155): add reentrancy guard to _update

BREAKING CHANGE: _update function now uses ReentrancyGuard.
Gas cost increased by ~23,000 per transaction.

This fixes critical reentrancy vulnerability in batch operations
where external calls in loops created N attack vectors.

Fixes #156
```

```
perf(registry): use cached factory addresses

Reduces gas cost of createERC20Token from 65k to 58k gas
by caching factory addresses instead of SLOAD per call.
```

```
test(security): add reentrancy attack scenarios

Add fuzzing tests for:
- Constructor reentrancy via compliance hooks
- _update reentrancy with privilege escalation
- Batch operation reentrancy amplification
```

```
docs(README): add audit findings section

Document Trail of Bits audit findings and remediations.
```

**Bad commit messages (DO NOT USE):**

```
❌ update code
❌ fix bug
❌ WIP
❌ changes
❌ asdfasdf
❌ Fix stuff
```

### PR Titles

Pull request titles MUST also follow Conventional Commits format:

```
feat(ERC20): add pausable functionality
fix(factory): prevent duplicate token registration
refactor(compliance): extract validation logic
```

### Commit Message Body Guidelines

1. **Use imperative mood**: "add feature" not "added feature"
2. **Explain WHY, not just WHAT**: Context is valuable
3. **Reference issues**: Use "Fixes #123" or "Closes #123"
4. **Keep lines < 72 characters**: For better readability
5. **Separate subject from body**: Use blank line

### Footer Keywords

- `Fixes #123` - Closes issue automatically on merge
- `Closes #123` - Same as Fixes
- `Refs #123` - References issue without closing
- `BREAKING CHANGE:` - Documents breaking changes
- `Reviewed-by:` - Credit reviewers
- `Co-authored-by:` - Credit human co-authors (NEVER include Claude/AI as co-author)

### Multi-paragraph Body Example

```
feat(ERC1155): add batch size limit

Add MAX_BATCH_SIZE constant to prevent DoS attacks via
unbounded loops in _update function.

The compliance hook is called N times in a loop where N is
the batch size. Without a limit, malicious users could submit
batches of 10,000+ tokens, causing transactions to exceed
block gas limits and brick the contract.

Limit set to 100 tokens per batch based on gas analysis:
- 100 tokens = ~210k gas overhead (acceptable)
- 1000 tokens = ~2.1M gas overhead (excessive)

BREAKING CHANGE: Batch operations now limited to 100 tokens.
Large batches must be split into multiple transactions.

Fixes #234
Refs #156 (reentrancy audit finding)
```

### Automated Tools

When using `git commit` or creating PRs, Claude Code will automatically:
1. ✅ Validate commit message format
2. ✅ Suggest appropriate type and scope
3. ✅ Draft commit body with context
4. ✅ Add footer references (Fixes #, issue references)
5. ✅ Flag breaking changes

**IMPORTANT**: NEVER add "Co-authored-by: Claude" or any AI attribution to commits. All commits are authored by the human developer.

### Security Commits

For security-sensitive changes, use:

```
fix(security): add reentrancy guard to _update

SECURITY: This fixes a critical vulnerability where malicious
compliance hooks could reenter during _update and grant
themselves unlimited minting privileges.

DO NOT disclose publicly until after deployment.

CVE: Pending assignment
Severity: Critical
CVSS: 9.1 (Critical)
```
