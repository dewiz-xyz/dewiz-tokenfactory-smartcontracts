# Copilot Instructions for Dewiz Token Factory

## Project Context

Dewiz Token Factory is an **enterprise-grade tokenization platform** for financial institutions. It enables creation of:
- Stablecoins for payments and international remittances
- Real World Asset (RWA) tokenization
- Government bonds and corporate debentures
- Regulatory-compliant tokens (OFAC, SEC, ECB)

The project implements the **Abstract Factory Pattern** with three concrete factories creating ERC-20, ERC-721, and ERC-1155 tokens.

## Tech Stack

| Component | Version | Notes |
|-----------|---------|-------|
| **Solidity** | ^0.8.24 | Use latest stable features |
| **Foundry/Forge** | Latest | Development, testing, deployment |
| **OpenZeppelin** | v5.5 | Always use OZ for standard patterns |
| **Compiler** | Via IR enabled | `optimizer_runs = 200` |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   TokenFactoryRegistry                       │
│              (Abstract Factory Coordinator)                  │
│     Uses: Ownable, registers factories, delegates creation   │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  ERC20Factory   │  │  ERC721Factory  │  │ ERC1155Factory  │
│  implements:    │  │  implements:    │  │  implements:    │
│  IERC20Factory  │  │  IERC721Factory │  │ IERC1155Factory │
│  extends:       │  │  extends:       │  │  extends:       │
│  Ownable        │  │  Ownable        │  │  Ownable        │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   DewizERC20    │  │   DewizERC721   │  │  DewizERC1155   │
│  Features:      │  │  Features:      │  │  Features:      │
│  - AccessControl│  │  - AccessControl│  │  - AccessControl│
│  - Mintable     │  │  - ERC2981      │  │  - ERC2981      │
│  - Burnable     │  │  - URIStorage   │  │  - SupplyTrack  │
│  - Pausable     │  │  - Pausable     │  │  - Pausable     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Code Style & Conventions

### File Header (Required)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
```

### NatSpec Documentation (Required for all public/external)
```solidity
/**
 * @title ContractName
 * @author Dewiz
 * @notice User-facing explanation of the contract
 * @dev Technical implementation details
 */
contract ContractName {
    /// @notice Single-line for simple items
    uint256 public value;

    /**
     * @notice Creates a new token with specified parameters
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @return tokenAddress The address of the newly created token
     */
    function createToken(string calldata name, string calldata symbol) 
        external 
        returns (address tokenAddress) 
    {
        // implementation
    }
}
```

### Naming Conventions (Project-Specific)

| Element | Convention | Example |
|---------|------------|---------|
| Contracts | PascalCase | `TokenFactoryRegistry`, `ERC20Factory` |
| Interfaces | `I` prefix | `ITokenFactory`, `IERC20Factory` |
| Functions | camelCase | `createToken`, `getTokenCount` |
| Constants | SCREAMING_SNAKE | `MINTER_ROLE`, `DEFAULT_DECIMALS` |
| Private/Internal vars | `_` prefix | `_tokens`, `_isFactoryToken`, `_decimals` |
| Immutables | no prefix | `factory`, `mintable`, `burnable` |
| Events | PascalCase | `TokenCreated`, `FactoryRegistered` |
| Custom Errors | ContractName prefix | `TokenCreationFailed`, `ZeroAddressFactory` |
| Struct params | No prefix | `ERC20TokenParams` |
| Enums | PascalCase | `TokenType` |

### Custom Errors (ALWAYS use instead of require strings)
```solidity
// ❌ NEVER do this
require(factory != address(0), "Zero address");

// ✅ ALWAYS do this
error ZeroAddressFactory();
error FactoryNotRegistered(TokenType tokenType);

if (factory == address(0)) revert ZeroAddressFactory();
if (address(erc20Factory) == address(0)) revert FactoryNotRegistered(TokenType.ERC20);
```

### Function Ordering (Solidity Style Guide)
```solidity
contract Example {
    // 1. State variables (constants, immutables, storage)
    uint8 public constant DEFAULT_DECIMALS = 18;
    address public immutable factory;
    address[] private _tokens;

    // 2. Events
    event TokenCreated(address indexed tokenAddress, address indexed creator);

    // 3. Errors
    error TokenCreationFailed();

    // 4. Modifiers
    modifier onlyFactory() { ... }

    // 5. Constructor
    constructor(address initialOwner) Ownable(initialOwner) {}

    // 6. External functions
    function createToken(...) external returns (address) { ... }

    // 7. Public functions
    function tokenType() public pure returns (string memory) { ... }

    // 8. Internal functions
    function _registerToken(...) internal { ... }

    // 9. Private functions
    function _validateParams(...) private { ... }

    // 10. View/Pure functions (within each visibility group, place at end)
    function getTokenCount() external view returns (uint256) { ... }
}
```

### Import Style (Named imports with curly braces)
```solidity
// 1. OpenZeppelin contracts (alphabetical within category)
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// 2. Project interfaces
import {IERC20Factory} from "../interfaces/IERC20Factory.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";

// 3. Project contracts
import {DewizERC20} from "../tokens/DewizERC20.sol";
```

### Access Control Roles (Project Standard)
```solidity
// Standard roles used across all tokens
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
// DEFAULT_ADMIN_ROLE is inherited from AccessControl
```

### Constructor Patterns

**Factory Pattern:**
```solidity
constructor(address initialOwner) Ownable(initialOwner) {}
```

**Token Pattern (with feature flags):**
```solidity
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
```

## Design Patterns Used

### 1. Abstract Factory Pattern
- `TokenFactoryRegistry` = Coordinator/Client
- `ERC20Factory`, `ERC721Factory`, `ERC1155Factory` = Concrete Factories
- `DewizERC20`, `DewizERC721`, `DewizERC1155` = Products

### 2. Interface Segregation
```
ITokenFactory (base)
    ├── IERC20Factory (extends with ERC20-specific)
    ├── IERC721Factory (extends with ERC721-specific)
    └── IERC1155Factory (extends with ERC1155-specific)
```

### 3. Factory Registration Pattern
```solidity
// Register factories with registry
function registerERC20Factory(address factory) external onlyOwner {
    if (factory == address(0)) revert ZeroAddressFactory();
    erc20Factory = IERC20Factory(factory);
    factories[TokenType.ERC20] = factory;
    _addToRegisteredFactories(factory);
    emit FactoryRegistered(TokenType.ERC20, factory);
}
```

### 4. Token Tracking Pattern
```solidity
// Track all created tokens
address[] private _tokens;
mapping(address => bool) private _isFactoryToken;
mapping(address => address[]) private _creatorTokens;

function _registerToken(address tokenAddress, string memory name, string memory symbol) internal {
    _tokens.push(tokenAddress);
    _isFactoryToken[tokenAddress] = true;
    _creatorTokens[msg.sender].push(tokenAddress);
    emit TokenCreated(tokenAddress, msg.sender, name, symbol);
}
```

### 5. Feature Flags Pattern (for tokens)
```solidity
bool public immutable mintable;
bool public immutable burnable;
bool public immutable pausable;

function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
    if (!mintable) revert MintingDisabled();
    _mint(to, amount);
}
```

## Project Structure

```
src/
├── TokenFactoryRegistry.sol    # Central coordinator (Ownable)
├── interfaces/
│   ├── ITokenFactory.sol       # Base: tokenType(), getTokenCount(), getAllTokens(), isTokenFromFactory()
│   ├── IERC20Factory.sol       # Adds: ERC20TokenParams struct, createToken(), createSimpleToken()
│   ├── IERC721Factory.sol      # Adds: ERC721TokenParams struct, createToken(), createSimpleToken()
│   └── IERC1155Factory.sol     # Adds: ERC1155TokenParams struct, createToken(), createSimpleToken()
├── factories/
│   ├── ERC20Factory.sol        # Ownable, creates DewizERC20
│   ├── ERC721Factory.sol       # Ownable, creates DewizERC721
│   └── ERC1155Factory.sol      # Ownable, creates DewizERC1155
└── tokens/
    ├── DewizERC20.sol          # ERC20 + Burnable + Pausable + AccessControl
    ├── DewizERC721.sol         # ERC721 + URIStorage + Royalties + AccessControl
    └── DewizERC1155.sol        # ERC1155 + Supply + Royalties + AccessControl

test/                            # Mirror src/ structure with .t.sol suffix
script/
    └── DeployTokenFactory.s.sol # Deployment scripts
```

## Foundry Testing Standards

### Test File Structure
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20Factory} from "../src/factories/ERC20Factory.sol";
import {DewizERC20} from "../src/tokens/DewizERC20.sol";
import {IERC20Factory} from "../src/interfaces/IERC20Factory.sol";

contract ERC20FactoryTest is Test {
    ERC20Factory public factory;
    address public owner;
    address public user;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        
        vm.prank(owner);
        factory = new ERC20Factory(owner);
    }

    // Success cases: test_FunctionName_Description
    function test_CreateToken_WithValidParams() public {
        // Arrange
        IERC20Factory.ERC20TokenParams memory params = IERC20Factory.ERC20TokenParams({
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            initialSupply: 1000 ether,
            initialHolder: user,
            isMintable: true,
            isBurnable: true,
            isPausable: false
        });

        // Act
        vm.prank(user);
        address tokenAddress = factory.createToken(params);

        // Assert
        DewizERC20 token = DewizERC20(tokenAddress);
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
        assertEq(token.balanceOf(user), 1000 ether);
        assertTrue(token.mintable());
    }

    // Failure cases: test_RevertWhen_Condition
    function test_RevertWhen_FactoryNotRegistered() public {
        // Arrange & Act & Assert
        vm.expectRevert(abi.encodeWithSelector(
            TokenFactoryRegistry.FactoryNotRegistered.selector,
            TokenFactoryRegistry.TokenType.ERC20
        ));
        registry.createSimpleERC20Token("Test", "TST", 1000);
    }

    // Fuzz tests: testFuzz_FunctionName
    function testFuzz_CreateToken_WithRandomSupply(uint256 supply) public {
        vm.assume(supply > 0 && supply < type(uint128).max);
        
        vm.prank(user);
        address token = factory.createSimpleToken("Test", "TST", supply);
        
        assertEq(DewizERC20(token).totalSupply(), supply);
    }

    // Invariant tests
    function invariant_TokenCountMatchesArray() public {
        assertEq(factory.getTokenCount(), factory.getAllTokens().length);
    }
}
```

### Common Test Helpers
```solidity
// Create addresses
address owner = makeAddr("owner");
address user = makeAddr("user");

// Fund accounts
vm.deal(user, 100 ether);

// Impersonate
vm.prank(user);           // Single call
vm.startPrank(user);      // Multiple calls
vm.stopPrank();

// Time manipulation
vm.warp(block.timestamp + 1 days);
skip(1 hours);

// Expect events
vm.expectEmit(true, true, false, true);
emit TokenCreated(expectedAddress, user, "Test", "TST");

// Expect reverts
vm.expectRevert(ZeroAddressFactory.selector);
vm.expectRevert(abi.encodeWithSelector(FactoryNotRegistered.selector, TokenType.ERC20));
```

## Security Checklist

When generating or reviewing code:

- [ ] All external/public functions have appropriate access control
- [ ] Custom errors used (not require strings)
- [ ] Events emitted for state changes
- [ ] Zero address checks for address parameters
- [ ] Input validation on all external parameters
- [ ] Follows Checks-Effects-Interactions pattern
- [ ] No reentrancy vulnerabilities (use nonReentrant if external calls)
- [ ] Pausable functionality for emergencies (where applicable)
- [ ] NatSpec documentation complete

## Common Commands

```bash
# Build
forge build

# Test
forge test                      # Run all tests
forge test -vvv                 # Verbose output
forge test --match-test testName # Run specific test
forge test --match-contract Contract # Run tests for contract
forge test --gas-report         # With gas reporting

# Coverage
forge coverage
forge coverage --report lcov

# Format
forge fmt
forge fmt --check              # Check only

# Deploy
forge script script/DeployTokenFactory.s.sol:DeployTokenFactoryLocal --rpc-url http://localhost:8545 --broadcast

# Verify
forge verify-contract <ADDRESS> <CONTRACT> --chain <CHAIN_ID>

# Analyze
forge snapshot                  # Gas snapshots
forge inspect <CONTRACT> abi   # Get ABI
```

## When Generating Code

1. **ALWAYS** include SPDX license and pragma
2. **ALWAYS** add NatSpec for public/external functions
3. **ALWAYS** use custom errors (not require strings)
4. **ALWAYS** emit events for state changes
5. **ALWAYS** validate inputs (especially addresses)
6. **FOLLOW** the existing code patterns exactly
7. **USE** named imports with curly braces
8. **PREFER** `calldata` over `memory` for external function params
9. **USE** `immutable` for constructor-set values that don't change
10. **TRACK** created tokens using the existing registration pattern

## Interface Contracts Must Include

- `TokenCreated` event (from ITokenFactory)
- `tokenType()` - returns "ERC20", "ERC721", or "ERC1155"
- `getTokenCount()` - total tokens created
- `getTokenAt(uint256 index)` - token at index
- `getAllTokens()` - all token addresses
- `isTokenFromFactory(address)` - verification check

## Token Contracts Must Include

- `AccessControl` for role management
- `factory` immutable pointing to creator factory
- Feature flags (mintable, burnable, pausable) as immutables
- Proper role checks on privileged functions
