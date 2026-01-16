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
