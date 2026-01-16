# Dewiz Token Factory - Security Audit Context Building
## Phase 1: Initial Orientation (Bottom-Up Scan)

**Analysis Date:** 2026-01-16
**Methodology:** Trail of Bits Ultra-Granular Context Building
**Analyzer:** Claude Sonnet 4.5 via audit-context-building skill

---

## 1. Contract Inventory & Sizing

**Total: 13 Solidity Files | 1,644 Lines of Code**

| Contract | Lines | Category | Purpose |
|----------|-------|----------|---------|
| DewizERC1155.sol | 348 | Token Implementation | Multi-token standard with compliance hooks |
| DewizERC721.sol | 272 | Token Implementation | NFT with royalties and compliance hooks |
| DewizERC20.sol | 194 | Token Implementation | Fungible token with compliance hooks |
| TokenFactoryRegistry.sol | 302 | Registry/Coordinator | Central entry point for all token creation |
| ERC1155Factory.sol | 164 | Factory | Creates DewizERC1155 instances |
| ERC20Factory.sol | 154 | Factory | Creates DewizERC20 instances |
| ERC721Factory.sol | 154 | Factory | Creates DewizERC721 instances |
| IComplianceHook.sol | 106 | Interface | Compliance validation hooks |
| TemplateComplianceHook.sol | 112 | Compliance | Reference implementation (allows all) |
| ITokenFactory.sol | 46 | Interface | Base factory interface |
| IERC20Factory.sol | 35 | Interface | ERC20 factory interface |
| IERC721Factory.sol | 35 | Interface | ERC721 factory interface |
| IERC1155Factory.sol | 36 | Interface | ERC1155 factory interface |

**File Locations:**
```
src/
├── TokenFactoryRegistry.sol (302 lines)
├── factories/
│   ├── ERC20Factory.sol (154 lines)
│   ├── ERC721Factory.sol (154 lines)
│   └── ERC1155Factory.sol (164 lines)
├── tokens/
│   ├── DewizERC20.sol (194 lines)
│   ├── DewizERC721.sol (272 lines)
│   └── DewizERC1155.sol (348 lines)
├── interfaces/
│   ├── ITokenFactory.sol (46 lines)
│   ├── IERC20Factory.sol (35 lines)
│   ├── IERC721Factory.sol (35 lines)
│   ├── IERC1155Factory.sol (36 lines)
│   └── IComplianceHook.sol (106 lines)
└── compliance/
    └── TemplateComplianceHook.sol (112 lines)
```

---

## 2. Actor Identification & Privilege Mapping

### Actor Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│ REGISTRY OWNER (Ownable)                                     │
│ - Registers/updates factory addresses                        │
│ - Single point of control for factory coordination           │
└─────────────────────────────────────────────────────────────┘
                             │
                 ┌───────────┼───────────┐
                 ▼           ▼           ▼
        ┌────────────┐ ┌─────────────┐ ┌──────────────┐
        │ERC20Factory│ │ERC721Factory│ │ERC1155Factory│
        │   OWNER    │ │   OWNER     │ │    OWNER     │
        └────────────┘ └─────────────┘ └──────────────┘
                 │           │           │
                 └───────────┼───────────┘
                             ▼
        ┌─────────────────────────────────────────────┐
        │        TOKEN CREATORS (msg.sender)          │
        │ - Anyone can create tokens through registry  │
        │ - Become DEFAULT_ADMIN_ROLE of their tokens │
        └─────────────────────────────────────────────┘
                             │
                             ▼
        ┌─────────────────────────────────────────────┐
        │      TOKEN-LEVEL ROLES (AccessControl)      │
        │                                              │
        │  DEFAULT_ADMIN_ROLE (Token Creator)         │
        │    ├─ Grant/revoke all roles                │
        │    ├─ Set compliance hooks                  │
        │    └─ Update URIs (ERC1155/721)             │
        │                                              │
        │  MINTER_ROLE (if mintable=true)             │
        │    └─ Call mint() functions                 │
        │                                              │
        │  PAUSER_ROLE (if pausable=true)             │
        │    └─ Call pause()/unpause()                │
        │                                              │
        │  URI_SETTER_ROLE (ERC1155/721)              │
        │    └─ Update token URIs                     │
        └─────────────────────────────────────────────┘
                             │
                             ▼
        ┌─────────────────────────────────────────────┐
        │       COMPLIANCE HOOK (External Contract)   │
        │ - Validates mint/transfer/burn/approval ops │
        │ - Can block operations via revert           │
        │ - Optional, updatable by admin              │
        └─────────────────────────────────────────────┘
```

### Actor Definitions

**1. Registry Owner**
- **Who:** Single address with Ownable control over TokenFactoryRegistry
- **Powers:**
  - Register ERC20Factory via `registerERC20Factory(address)`
  - Register ERC721Factory via `registerERC721Factory(address)`
  - Register ERC1155Factory via `registerERC1155Factory(address)`
  - Batch register via `registerAllFactories(address, address, address)`
- **Trust Level:** HIGH - Can redirect token creation to malicious factories
- **Risk:** Central point of failure for system integrity

**2. Factory Owners**
- **Who:** Single address per factory with Ownable control
- **Powers:** Factory-level administrative functions (none implemented currently)
- **Trust Level:** MEDIUM - Currently no privileged functions, but pattern supports future extensions
- **Risk:** Could introduce privileged functions in upgrades

**3. Token Creators**
- **Who:** Any address that calls `createToken()` or `createSimpleToken()` functions
- **Powers:**
  - Create new tokens with custom parameters
  - Automatically receive DEFAULT_ADMIN_ROLE on created tokens
  - No permissions on other tokens
- **Trust Level:** LOW - Untrusted, anyone can create tokens
- **Risk:** Can create tokens with malicious parameters (name/symbol squatting, etc.)

**4. Token Admins (DEFAULT_ADMIN_ROLE)**
- **Who:** Token creator initially, can delegate to others
- **Powers:**
  - Grant/revoke MINTER_ROLE, PAUSER_ROLE, URI_SETTER_ROLE
  - Set/update compliance hooks via `setComplianceHook(address)`
  - Update token URIs (ERC1155/721) if also has URI_SETTER_ROLE
- **Trust Level:** HIGH for specific token - Full control over token lifecycle
- **Risk:** Can add malicious compliance hooks, grant roles to attackers

**5. Minters (MINTER_ROLE)**
- **Who:** Addresses granted MINTER_ROLE by DEFAULT_ADMIN_ROLE
- **Powers:**
  - Mint new tokens via `mint(to, amount)` (if mintable=true)
  - Create token types via `createTokenType()` (ERC1155)
- **Trust Level:** MEDIUM - Can inflate supply
- **Risk:** Unconstrained minting can devalue token

**6. Pausers (PAUSER_ROLE)**
- **Who:** Addresses granted PAUSER_ROLE by DEFAULT_ADMIN_ROLE
- **Powers:**
  - Pause all transfers via `pause()`
  - Unpause via `unpause()`
- **Trust Level:** MEDIUM - Can DoS token transfers
- **Risk:** Malicious pausing can freeze assets

**7. URI Setters (URI_SETTER_ROLE)**
- **Who:** Addresses granted URI_SETTER_ROLE by DEFAULT_ADMIN_ROLE (ERC721/1155 only)
- **Powers:**
  - Update individual token URIs via `setTokenURI(tokenId, uri)`
  - Update base URI via `setURI(uri)` (ERC1155)
- **Trust Level:** LOW - Metadata manipulation only
- **Risk:** Can mislead users with fake metadata

**8. Compliance Hooks**
- **Who:** External contract implementing IComplianceHook interface
- **Powers:**
  - Validate mint operations via `onMint(operator, to, id, amount)`
  - Validate transfers via `onTransfer(operator, from, to, id, amount)`
  - Validate burns via `onBurn(operator, from, id, amount)`
  - Validate approvals via `onApproval(operator, owner, spender, id, amount)`
  - Check if address is restricted via `isRestricted(account)`
  - **Can revert to block any operation**
- **Trust Level:** CRITICAL - Can freeze token permanently
- **Risk:** Malicious hooks can DoS token, steal funds via reentrancy, or censor users

---

## 3. Public/External Entry Points

### TokenFactoryRegistry (10 external functions)

**Factory Management (3 functions - Owner Only):**
- `registerERC20Factory(address factory)` - Register/update ERC20 factory
- `registerERC721Factory(address factory)` - Register/update ERC721 factory
- `registerERC1155Factory(address factory)` - Register/update ERC1155 factory
- `registerAllFactories(address erc20, address erc721, address erc1155)` - Batch register

**Token Creation (6 functions - Anyone):**
- `createERC20Token(ERC20TokenParams calldata params)` - Advanced ERC20 creation
- `createSimpleERC20Token(string name, string symbol, uint256 initialSupply)` - Basic ERC20
- `createERC721Token(ERC721TokenParams calldata params)` - Advanced ERC721 creation
- `createSimpleERC721Token(string name, string symbol, string baseURI)` - Basic ERC721
- `createERC1155Token(ERC1155TokenParams calldata params)` - Advanced ERC1155 creation
- `createSimpleERC1155Token(string name, string symbol, string uri)` - Basic ERC1155

**Query Functions (5 functions - View):**
- `getFactory(TokenType tokenType) view returns (address)` - Get factory for token type
- `getAllFactories() view returns (address[] memory)` - All registered factories
- `getTotalTokenCount() view returns (uint256)` - Total tokens across all factories
- `isFactoryRegistered(TokenType tokenType) view returns (bool)` - Check if factory exists
- `isTokenFromAnyFactory(address tokenAddress) view returns (bool)` - Verify token origin

### Factories (8 external functions each)

**All three factories (ERC20Factory, ERC721Factory, ERC1155Factory) implement:**

**Creation Functions (2 functions - Anyone):**
- `createToken(TokenParams calldata params) returns (address)` - Advanced token creation
- `createSimpleToken(...) returns (address)` - Basic token creation (ERC721Factory doesn't have this)

**Query Functions (6 functions - View):**
- `tokenType() pure returns (string memory)` - Returns "ERC20", "ERC721", or "ERC1155"
- `getTokenCount() view returns (uint256)` - Total tokens created by this factory
- `getTokenAt(uint256 index) view returns (address)` - Token at array index
- `getAllTokens() view returns (address[] memory)` - All tokens from this factory
- `isTokenFromFactory(address tokenAddress) view returns (bool)` - Verify token origin
- `getTokensByCreator(address creator) view returns (address[] memory)` - Tokens by creator

### DewizERC20 (8 privileged external functions)

**Administrative Functions:**
- `setComplianceHook(address newHook)` - DEFAULT_ADMIN_ROLE only

**Lifecycle Functions:**
- `mint(address to, uint256 amount)` - MINTER_ROLE only, requires mintable=true
- `burn(uint256 amount)` - Public, burns own tokens, requires burnable=true
- `burnFrom(address account, uint256 amount)` - Public, burns with allowance, requires burnable=true
- `pause()` - PAUSER_ROLE only, requires pausable=true
- `unpause()` - PAUSER_ROLE only, requires pausable=true

**Transfer Functions (with compliance checks):**
- `approve(address spender, uint256 value) returns (bool)` - Public, calls complianceHook.onApproval()
- `transfer(address to, uint256 value)` - Public (inherited), calls _update() which checks compliance
- `transferFrom(address from, address to, uint256 value)` - Public (inherited), calls _update()

**View Functions:**
- `decimals() view returns (uint8)` - Returns configured decimals (not always 18)

### DewizERC721 (10 privileged external functions)

**Administrative Functions:**
- `setComplianceHook(address newHook)` - DEFAULT_ADMIN_ROLE only

**Lifecycle Functions:**
- `safeMint(address to) returns (uint256 tokenId)` - MINTER_ROLE only, auto-increments tokenId
- `burn(uint256 tokenId)` - Public, requires token owner or approval, requires burnable=true
- `pause()` - PAUSER_ROLE only, requires pausable=true
- `unpause()` - PAUSER_ROLE only, requires pausable=true

**Metadata Functions:**
- `setTokenURI(uint256 tokenId, string calldata uri)` - Token owner or DEFAULT_ADMIN_ROLE
- `tokenURI(uint256 tokenId) view returns (string memory)` - Public (inherited)

**Transfer Functions (with compliance checks):**
- `setApprovalForAll(address operator, bool approved)` - Public, calls complianceHook.onApproval()
- `approve(address to, uint256 tokenId)` - Public, calls complianceHook.onApproval()
- `transferFrom(address from, address to, uint256 tokenId)` - Public (inherited), calls _update()
- `safeTransferFrom(...)` - Public (inherited), calls _update()

**View Functions:**
- `totalSupply() view returns (uint256)` - Returns _nextTokenId (count of minted tokens)

### DewizERC1155 (13 privileged external functions)

**Administrative Functions:**
- `setComplianceHook(address newHook)` - DEFAULT_ADMIN_ROLE only
- `setURI(string calldata newuri)` - URI_SETTER_ROLE only
- `setTokenURI(uint256 tokenId, string calldata tokenURI)` - URI_SETTER_ROLE only

**Lifecycle Functions:**
- `createTokenType(string calldata tokenURI, address royaltyReceiver, uint96 royaltyBps) returns (uint256)` - MINTER_ROLE only
- `mint(address to, uint256 id, uint256 amount, bytes calldata data)` - MINTER_ROLE only
- `mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data)` - MINTER_ROLE only
- `burn(address from, uint256 id, uint256 amount)` - Public, requires approval, requires burnable=true
- `burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts)` - Public, requires approval
- `pause()` - PAUSER_ROLE only, requires pausable=true
- `unpause()` - PAUSER_ROLE only, requires pausable=true

**Transfer Functions (with compliance checks):**
- `setApprovalForAll(address operator, bool approved)` - Public, calls complianceHook.onApproval()
- `safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data)` - Public (inherited), calls _update()
- `safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data)` - Public (inherited), calls _update() in loop

**View Functions:**
- `uri(uint256 tokenId) view returns (string memory)` - Returns token-specific URI or base URI
- `nextTokenTypeId() view returns (uint256)` - Returns next available token type ID

### IComplianceHook (5 external functions)

**Validation Functions (Called by Tokens):**
- `onMint(address operator, address to, uint256 id, uint256 amount)` - Called before minting
- `onTransfer(address operator, address from, address to, uint256 id, uint256 amount)` - Called before transfer
- `onBurn(address operator, address from, uint256 id, uint256 amount)` - Called before burning
- `onApproval(address operator, address tokenOwner, address spender, uint256 id, uint256 amount)` - Called before approval

**Query Functions (View):**
- `isRestricted(address account) view returns (bool)` - Check if address is blocked

---

## 4. Critical Storage Variables

### TokenFactoryRegistry Storage

```solidity
// Line 26-32: Factory references (public, updatable by owner)
IERC20Factory public erc20Factory;           // Registered ERC20 factory interface
IERC721Factory public erc721Factory;         // Registered ERC721 factory interface
IERC1155Factory public erc1155Factory;       // Registered ERC1155 factory interface

// Line 35: Mapping for factory lookup by enum
mapping(TokenType => address) public factories;  // TokenType enum to factory address

// Line 38: Array of all registered factories
address[] private _registeredFactories;      // Used for getAllFactories() query
```

**Security Notes:**
- Factory addresses can be updated by owner at any time
- No validation that factory addresses implement correct interfaces (only address(0) check)
- `_registeredFactories` can contain duplicates (checked in `_addToRegisteredFactories`)

### Factory Storage (ERC20Factory, ERC721Factory, ERC1155Factory)

All three factories share identical storage pattern:

```solidity
// Line 17: Array of all tokens created by this factory
address[] private _tokens;

// Line 20: Mapping for O(1) token verification
mapping(address => bool) private _isFactoryToken;

// Line 23: Mapping to track tokens by creator
mapping(address => address[]) private _creatorTokens;
```

**Tracking Invariants:**
- Every address in `_tokens[]` MUST have `_isFactoryToken[address] == true`
- Every token MUST appear in `_creatorTokens[creator]` array
- Arrays are append-only (no deletion mechanism)
- Token addresses are registered AFTER creation (not before)

### Token Storage - Shared Pattern (DewizERC20, DewizERC721, DewizERC1155)

**Immutable Feature Flags:**
```solidity
bool public immutable mintable;      // Can tokens be minted after initial creation?
bool public immutable burnable;      // Can tokens be burned by holders?
bool public immutable pausable;      // Can admin pause all transfers?
address public immutable factory;    // Factory that created this token
```

**Role Definitions (AccessControl):**
```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE"); // ERC1155/721 only
// DEFAULT_ADMIN_ROLE inherited from AccessControl (0x00...00)
```

**Compliance Integration:**
```solidity
IComplianceHook public complianceHook;  // Optional regulatory validation contract
```

**Token-Specific State:**

**DewizERC20:**
```solidity
uint8 private immutable _decimals;  // Token decimals (configurable, not always 18)
```

**DewizERC721:**
```solidity
uint256 private _nextTokenId;  // Auto-incrementing token ID counter
mapping(uint256 => string) private _tokenURIs;  // Per-token URI storage (ERC721URIStorage)
```

**DewizERC1155:**
```solidity
uint256 private _nextTokenTypeId;  // Auto-incrementing token type ID counter
mapping(uint256 => string) private _tokenURIs;  // Per-token-type URI storage
```

---

## 5. Primary System Flows

### Flow 1: System Deployment & Setup

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Deploy Core Contracts                               │
└─────────────────────────────────────────────────────────────┘
    1. Deploy TokenFactoryRegistry(owner)
       └─ Sets msg.sender or specified address as Ownable owner

    2. Deploy ERC20Factory(owner)
       └─ Sets owner as factory owner

    3. Deploy ERC721Factory(owner)
       └─ Sets owner as factory owner

    4. Deploy ERC1155Factory(owner)
       └─ Sets owner as factory owner

┌─────────────────────────────────────────────────────────────┐
│ Step 2: Register Factories with Registry                    │
└─────────────────────────────────────────────────────────────┘
    Registry Owner → registry.registerAllFactories(erc20Addr, erc721Addr, erc1155Addr)

    ├─ Validation:
    │  └─ Revert if any address == address(0)
    │
    ├─ State Changes:
    │  ├─ erc20Factory = IERC20Factory(erc20Addr)
    │  ├─ erc721Factory = IERC721Factory(erc721Addr)
    │  ├─ erc1155Factory = IERC1155Factory(erc1155Addr)
    │  ├─ factories[TokenType.ERC20] = erc20Addr
    │  ├─ factories[TokenType.ERC721] = erc721Addr
    │  └─ factories[TokenType.ERC1155] = erc1155Addr
    │
    ├─ Array Management:
    │  ├─ _addToRegisteredFactories(erc20Addr)
    │  ├─ _addToRegisteredFactories(erc721Addr)
    │  └─ _addToRegisteredFactories(erc1155Addr)
    │
    └─ Events:
       ├─ emit FactoryRegistered(TokenType.ERC20, erc20Addr)
       ├─ emit FactoryRegistered(TokenType.ERC721, erc721Addr)
       └─ emit FactoryRegistered(TokenType.ERC1155, erc1155Addr)

Result: Registry is operational, ready to create tokens
```

### Flow 2: Token Creation (Simple ERC20 via Registry)

```
User → registry.createSimpleERC20Token("USDC", "USDC", 1_000_000e6)

┌─────────────────────────────────────────────────────────────┐
│ Registry: TokenFactoryRegistry.createSimpleERC20Token       │
└─────────────────────────────────────────────────────────────┘
    Line 156-163:

    1. Validation:
       if (address(erc20Factory) == address(0))
           revert FactoryNotRegistered(TokenType.ERC20)

    2. Delegate to Factory:
       return erc20Factory.createSimpleToken("USDC", "USDC", 1_000_000e6)

┌─────────────────────────────────────────────────────────────┐
│ Factory: ERC20Factory.createSimpleToken                     │
└─────────────────────────────────────────────────────────────┘
    Line 75-95:

    1. Token Deployment:
       DewizERC20 token = new DewizERC20(
           "USDC",                    // name
           "USDC",                    // symbol
           18,                        // decimals (DEFAULT_DECIMALS)
           1_000_000e6,              // initialSupply
           msg.sender,               // initialHolder (token creator)
           msg.sender,               // admin (token creator)
           true,                     // mintable
           true,                     // burnable
           false,                    // not pausable
           address(0)                // no compliance hook
       )

    2. Registration:
       tokenAddress = address(token)
       _registerToken(tokenAddress, "USDC", "USDC")

┌─────────────────────────────────────────────────────────────┐
│ Token: DewizERC20 Constructor                               │
└─────────────────────────────────────────────────────────────┘
    Line 52-88:

    1. Initialize Base Contracts:
       ERC20("USDC", "USDC")
       ERC20Burnable()
       ERC20Pausable()
       AccessControl()

    2. Set Immutables:
       factory = msg.sender          // ERC20Factory address
       mintable = true
       burnable = true
       pausable = false
       _decimals = 18

    3. Grant Roles to Admin (msg.sender = token creator):
       _grantRole(DEFAULT_ADMIN_ROLE, msg.sender)
       _grantRole(MINTER_ROLE, msg.sender)
       _grantRole(PAUSER_ROLE, msg.sender)  // Even though pausable=false

    4. Set Compliance Hook:
       complianceHook = IComplianceHook(address(0))  // None

    5. Mint Initial Supply:
       if (1_000_000e6 > 0):
           _mint(msg.sender, 1_000_000e6)  // Mint to creator

┌─────────────────────────────────────────────────────────────┐
│ Factory: ERC20Factory._registerToken                        │
└─────────────────────────────────────────────────────────────┘
    Line 146-152:

    1. Add to Tracking Arrays:
       _tokens.push(tokenAddress)
       _isFactoryToken[tokenAddress] = true
       _creatorTokens[msg.sender].push(tokenAddress)

    2. Emit Event:
       emit TokenCreated(tokenAddress, msg.sender, "USDC", "USDC")

Result: Token created at tokenAddress, creator has full admin control + initial supply
```

### Flow 3: Compliance-Checked Transfer (ERC20)

```
Token Holder → token.transfer(recipient, 1000e6)

┌─────────────────────────────────────────────────────────────┐
│ Token: DewizERC20.transfer (ERC20 inherited)                │
└─────────────────────────────────────────────────────────────┘
    Calls _update(msg.sender, recipient, 1000e6)

┌─────────────────────────────────────────────────────────────┐
│ Token: DewizERC20._update (Overridden)                      │
└─────────────────────────────────────────────────────────────┘
    Line 166-186:

    1. Compliance Check:
       if (address(complianceHook) != address(0)):

           // Determine operation type
           if (from == address(0)):
               // Minting operation
               complianceHook.onMint(msg.sender, to, 0, amount)

           else if (to == address(0)):
               // Burning operation
               complianceHook.onBurn(msg.sender, from, 0, amount)

           else:
               // Transfer operation
               complianceHook.onTransfer(msg.sender, from, to, 0, amount)

           // Hook can revert here to block operation

    2. Execute Transfer:
       super._update(from, to, amount)
       └─ ERC20Pausable._update
          └─ Checks if paused
             └─ ERC20._update (actual balance changes)

Result: Transfer succeeds if compliance hook allows (or no hook set)
```

### Flow 4: Compliance Hook Integration

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Deploy Compliance Hook Contract                     │
└─────────────────────────────────────────────────────────────┘
    Deploy MyComplianceHook(owner)
    └─ Must implement IComplianceHook interface:
       - onMint(operator, to, id, amount)
       - onTransfer(operator, from, to, id, amount)
       - onBurn(operator, from, id, amount)
       - onApproval(operator, owner, spender, id, amount)
       - isRestricted(account) view returns (bool)

┌─────────────────────────────────────────────────────────────┐
│ Step 2: Attach Hook to Token                                │
└─────────────────────────────────────────────────────────────┘
    Token Admin → token.setComplianceHook(hookAddress)

    Line 113-121 (DewizERC20.sol):

    1. Access Control:
       onlyRole(DEFAULT_ADMIN_ROLE)
       └─ Reverts if msg.sender doesn't have admin role

    2. Validation:
       address oldHook = address(complianceHook)

       if (newHook != address(0)):
           if (newHook.code.length == 0):
               revert ComplianceHookNotContract()

    3. Update State:
       complianceHook = IComplianceHook(newHook)

    4. Emit Event:
       emit ComplianceHookUpdated(oldHook, newHook)

┌─────────────────────────────────────────────────────────────┐
│ Step 3: All Operations Now Validated                        │
└─────────────────────────────────────────────────────────────┘
    Every mint/transfer/burn/approval now calls:

    Mint:     complianceHook.onMint(operator, to, id, amount)
    Transfer: complianceHook.onTransfer(operator, from, to, id, amount)
    Burn:     complianceHook.onBurn(operator, from, id, amount)
    Approval: complianceHook.onApproval(operator, owner, spender, id, amount)

    Hook Implementation Can:
    ├─ Revert to block operation
    ├─ Check whitelist/blacklist via isRestricted(account)
    ├─ Enforce transfer limits
    ├─ Log validation events
    └─ Call external regulatory APIs (OFAC, etc.)

Result: Token is now compliance-enforced, hook controls all operations
```

### Flow 5: Batch Operations with Compliance (ERC1155)

```
Minter → token.mintBatch(recipient, [1, 2, 3], [100, 200, 300], "0x")

┌─────────────────────────────────────────────────────────────┐
│ Token: DewizERC1155.mintBatch                               │
└─────────────────────────────────────────────────────────────┘
    Line 207-224:

    1. Access Control:
       onlyRole(MINTER_ROLE)

    2. Feature Flag Check:
       if (!mintable):
           revert MintingDisabled()

    3. Call Internal Mint:
       _mintBatch(to, ids, amounts, data)
       └─ Calls _update() hook

┌─────────────────────────────────────────────────────────────┐
│ Token: DewizERC1155._update (Overridden)                    │
└─────────────────────────────────────────────────────────────┘
    Line 275-305:

    1. Compliance Checks (IN LOOP):
       if (address(complianceHook) != address(0)):

           uint256 length = ids.length  // Gas optimization: cached length

           for (uint256 i = 0; i < length; i++):
               if (from == address(0)):
                   // Minting
                   complianceHook.onMint(msg.sender, to, ids[i], values[i])
               else if (to == address(0)):
                   // Burning
                   complianceHook.onBurn(msg.sender, from, ids[i], values[i])
               else:
                   // Transfer
                   complianceHook.onTransfer(msg.sender, from, to, ids[i], values[i])

               // External call per iteration - INTENTIONAL DESIGN

    2. Execute Batch Operation:
       super._update(from, to, ids, values)
       └─ ERC1155Supply._update
          └─ ERC1155Pausable._update
             └─ ERC1155._update (actual balance changes)

Result: All tokens in batch are minted, each validated individually by compliance hook

⚠️ SECURITY NOTE: External calls in loops
   - Gas costs scale linearly with batch size
   - Compliance hooks must be gas-efficient
   - Malicious hook can DoS with gas exhaustion
   - Design tradeoff: Individual validation vs. gas efficiency
```

---

## 6. Invariants & Assumptions

### System Invariants (MUST always be true)

**Factory Tracking Invariants:**
1. `∀ token ∈ _tokens[] ⟹ _isFactoryToken[token] == true`
   - Every token in array MUST be marked in mapping

2. `∀ token ∈ _creatorTokens[creator] ⟹ _isFactoryToken[token] == true`
   - Every creator-tracked token MUST exist in factory

3. `∀ token ∈ _tokens[] ⟹ ∃! creator : token ∈ _creatorTokens[creator]`
   - Every token MUST have exactly one creator

4. `_tokens.length == Σ(length of all _creatorTokens[creator])`
   - Total tokens MUST equal sum of all creator tokens

**Token Property Invariants:**
1. `token.factory == address(factory that created it)`
   - Factory address MUST be immutable and correct

2. `token.mintable, token.burnable, token.pausable` are immutable
   - Feature flags NEVER change after deployment

3. `token creator always has DEFAULT_ADMIN_ROLE` (at creation)
   - Creator starts with admin role (can be revoked later)

4. `if token.complianceHook != address(0) ⟹ complianceHook.code.length > 0`
   - Non-zero compliance hook MUST be a contract

**Role Invariants:**
1. `hasRole(MINTER_ROLE, addr) ⟹ token.mintable == true` (for mint to succeed)
   - Minter role is useless if mintable=false

2. `hasRole(PAUSER_ROLE, addr) ⟹ token.pausable == true` (for pause to succeed)
   - Pauser role is useless if pausable=false

**Registry Invariants:**
1. `factories[TokenType.ERC20] == address(erc20Factory)`
   - Enum mapping MUST match direct reference

2. `∀ factory ∈ _registeredFactories ⟹ factory appears at most once`
   - No duplicate factories in array

### Security Assumptions (Trust Model)

**Trusted Actors:**
1. **Registry Owner**: Trusted to register correct factory implementations
   - **Risk**: Can redirect token creation to malicious factories
   - **Mitigation**: Multi-sig or governance for registry ownership

2. **Factory Owners**: Trusted to not add malicious functionality
   - **Risk**: Currently no privileged functions, but pattern supports future extensions
   - **Mitigation**: Immutable factory pattern (no upgradeability)

3. **Token Admins (DEFAULT_ADMIN_ROLE)**: Trusted with their specific token
   - **Risk**: Can set malicious compliance hooks, grant roles to attackers
   - **Mitigation**: Token creators choose their own admin model

4. **Compliance Hooks**: Trusted to not DoS or steal funds
   - **Risk**: External calls can revert, consume gas, or reenter
   - **Mitigation**: Hooks are optional, updatable by admin

**Untrusted Actors:**
1. **Token Creators**: Anyone can create tokens (permissionless)
   - **Risk**: Name/symbol squatting, misleading tokens
   - **Mitigation**: Factory tracks creator, registry can be queried

2. **Token Holders**: Assumed to be adversarial
   - **Risk**: Standard ERC20/721/1155 risks (frontrunning, MEV, etc.)
   - **Mitigation**: Compliance hooks can enforce transfer restrictions

3. **Minters/Pausers**: Can abuse their roles
   - **Risk**: Unconstrained minting, malicious pausing
   - **Mitigation**: Admin can revoke roles

### Operational Assumptions

**Gas Assumptions:**
1. Array length caching is used consistently (`uint256 length = array.length`)
2. Immutables preferred over storage for constant values
3. Custom errors used instead of require strings
4. Compliance hooks must be gas-efficient (called on every operation)

**External Call Assumptions:**
1. Compliance hooks can revert (intentional, for blocking operations)
2. Compliance hooks should not reenter (no reentrancy guards on tokens)
3. External calls in loops (ERC1155 batch) are intentional design tradeoff
4. Hook gas costs scale linearly with batch size

**OpenZeppelin Assumptions:**
1. OZ v5.5 contracts are secure and audited
2. AccessControl role management is correct
3. Pausable pattern works as expected
4. ERC standards are correctly implemented

---

## 7. Risk Surface Area

### High-Risk Components (Critical)

**1. Compliance Hooks (CRITICAL)**
- **Location**: `tokens/DewizERC*.sol` - `_update()` and approval functions
- **Risk**: External calls to untrusted contracts
- **Attack Vectors**:
  - Reentrancy: Hook calls back into token during transfer
  - DoS: Hook reverts or consumes excessive gas
  - Censorship: Hook blocks legitimate transfers
  - Griefing: Hook in ERC1155 batch causes entire batch to fail
- **Impact**: Token freeze, fund theft, gas exhaustion
- **Mitigation**:
  - Hooks are optional (can be set to address(0))
  - Admin can update hook with `setComplianceHook()`
  - Consider: Add reentrancy guards, gas limits, hook timeouts

**2. Factory Registration (HIGH)**
- **Location**: `TokenFactoryRegistry.sol` - `register*Factory()` functions
- **Risk**: Owner can redirect token creation to malicious factories
- **Attack Vectors**:
  - Owner registers factory that creates backdoored tokens
  - Owner updates factory mid-flight, affecting subsequent creations
  - No validation that factory implements correct interface
- **Impact**: Users create compromised tokens
- **Mitigation**:
  - Registry owner should be multi-sig or governance
  - Consider: Factory immutability after first registration
  - Consider: Interface validation via ERC165

**3. Access Control (HIGH)**
- **Location**: All tokens - `AccessControl` roles
- **Risk**: DEFAULT_ADMIN_ROLE has full control over token lifecycle
- **Attack Vectors**:
  - Admin sets malicious compliance hook
  - Admin grants MINTER_ROLE to attacker
  - Admin pauses token permanently
  - Admin loses private key (frozen token)
- **Impact**: Token compromise, loss of funds, DoS
- **Mitigation**:
  - Token creators choose their own admin model (multi-sig, DAO, etc.)
  - Consider: Role renunciation mechanism
  - Consider: Time-locks on critical operations

**4. Batch Operations (MEDIUM-HIGH)**
- **Location**: `DewizERC1155.sol` - `_update()` with array iteration
- **Risk**: External calls in loops (compliance hooks)
- **Attack Vectors**:
  - Gas exhaustion with large batches
  - Single hook revert fails entire batch
  - O(n) external calls per batch operation
- **Impact**: DoS, gas griefing, failed transactions
- **Mitigation**:
  - Documented as intentional design (line-by-line validation)
  - Gas optimization: array length cached
  - Consider: Max batch size limit

**5. Token Creation (MEDIUM)**
- **Location**: Factories - `createToken()` using `new` keyword
- **Risk**: Out-of-gas attacks, unbounded gas costs
- **Attack Vectors**:
  - Attacker creates tokens with massive initial supply
  - Constructor gas costs are unbounded
  - No rate limiting on token creation
- **Impact**: Failed token creations, wasted gas
- **Mitigation**:
  - Factories are permissionless (anyone can create)
  - Consider: Creation fee, rate limiting, gas stipends

### Medium-Risk Components

**6. Feature Flags (MEDIUM)**
- **Location**: All tokens - `immutable` booleans (mintable, burnable, pausable)
- **Risk**: Immutable design means mistakes are permanent
- **Attack Vectors**:
  - Creator sets mintable=false, can never mint more tokens
  - Creator sets pausable=false, can never pause in emergency
  - No way to upgrade token with new features
- **Impact**: Locked token functionality, inflexible design
- **Mitigation**:
  - Documented clearly in NatSpec
  - `createSimpleToken()` uses sensible defaults
  - Consider: Proxy pattern for upgradeability (tradeoff: complexity)

**7. Creator Tracking (MEDIUM)**
- **Location**: Factories - `_tokens[]` and `_creatorTokens[]` arrays
- **Risk**: Arrays can grow unbounded
- **Attack Vectors**:
  - Attacker creates millions of tokens, bloating arrays
  - `getAllTokens()` runs out of gas with large arrays
  - `getTokensByCreator()` DOS with many tokens per creator
- **Impact**: Gas exhaustion, failed queries
- **Mitigation**:
  - View functions only (no state changes)
  - Pagination patterns can be added externally
  - Consider: Limit token creation per address

**8. Pausability (MEDIUM)**
- **Location**: All tokens - `pause()`/`unpause()` functions
- **Risk**: PAUSER_ROLE can freeze all transfers
- **Attack Vectors**:
  - Malicious pauser freezes token indefinitely
  - Pauser loses key, token frozen permanently
  - Pauser frontrunts large transactions with pause
- **Impact**: DoS, frozen funds, MEV attacks
- **Mitigation**:
  - Pausable is opt-in (immutable flag)
  - Admin can revoke PAUSER_ROLE
  - Consider: Auto-unpause after timeout

**9. Royalty Settings (MEDIUM)**
- **Location**: `DewizERC721.sol`, `DewizERC1155.sol` - ERC2981 royalties
- **Risk**: Admin can change royalty receiver and basis points
- **Attack Vectors**:
  - Admin changes royalty receiver to attacker address
  - Admin sets royalty to 100% (DoS marketplaces)
  - No event emissions for royalty changes (inherited from OZ)
- **Impact**: Stolen royalties, marketplace incompatibility
- **Mitigation**:
  - Standard ERC2981 behavior (marketplaces expect mutability)
  - Consider: Max royalty caps, immutable royalties

### Low-Risk Components

**10. View Functions (LOW)**
- **Location**: All contracts - `view` and `pure` functions
- **Risk**: Read-only, no state changes
- **Attack Vectors**:
  - Gas exhaustion on large array returns (already noted in #7)
  - No direct security impact
- **Impact**: Failed queries only
- **Mitigation**: None needed, queries can be done off-chain

**11. Event Emissions (LOW)**
- **Location**: All contracts - `emit` statements
- **Risk**: Purely informational
- **Attack Vectors**:
  - Missing events (information loss)
  - Incorrect event parameters (misleading off-chain indexers)
- **Impact**: Poor UX, inaccurate off-chain data
- **Mitigation**: Comprehensive event coverage, indexed parameters

**12. Token Counting (LOW)**
- **Location**: Factories - `_nextTokenId` incrementing
- **Risk**: Incrementing counters with no side effects
- **Attack Vectors**:
  - Counter overflow (uint256, practically impossible)
  - No security impact
- **Impact**: None
- **Mitigation**: None needed

---

## 8. Dependencies & External Calls

### OpenZeppelin v5.5 Dependencies

**Access Control:**
- `@openzeppelin/contracts/access/Ownable.sol` - Registry and factories
- `@openzeppelin/contracts/access/AccessControl.sol` - All tokens

**Token Standards:**
- `@openzeppelin/contracts/token/ERC20/ERC20.sol`
- `@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol`
- `@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol`
- `@openzeppelin/contracts/token/ERC721/ERC721.sol`
- `@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol`
- `@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol`
- `@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol`
- `@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol`
- `@openzeppelin/contracts/token/ERC1155/ERC1155.sol`
- `@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol`
- `@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol`
- `@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol`

**Interfaces:**
- `@openzeppelin/contracts/interfaces/IERC2981.sol` - NFT royalties (ERC721, ERC1155)

### External Calls

**1. Compliance Hook Calls (CRITICAL - see Risk #1)**
```solidity
// Called in _update() and approval functions
complianceHook.onMint(operator, to, id, amount);
complianceHook.onTransfer(operator, from, to, id, amount);
complianceHook.onBurn(operator, from, id, amount);
complianceHook.onApproval(operator, tokenOwner, spender, id, amount);

// Called in view functions
complianceHook.isRestricted(account);
```

**Call Context:**
- **When**: Before every mint/transfer/burn/approval operation
- **Gas**: Unbounded (hook controls gas consumption)
- **Reentrancy**: Possible (no guards on tokens)
- **Trust**: Hook is set by token admin (trusted for that token)

**2. Factory Interface Calls (MEDIUM)**
```solidity
// Registry calls factories
erc20Factory.createToken(params);
erc20Factory.createSimpleToken(name, symbol, supply);
erc20Factory.getTokenCount();
erc20Factory.isTokenFromFactory(tokenAddress);
```

**Call Context:**
- **When**: During token creation and queries
- **Gas**: Bounded (known factory implementations)
- **Reentrancy**: Not applicable (factories don't call back)
- **Trust**: Factories registered by registry owner (trusted)

**3. No Other External Calls**
- Token creation uses `new` keyword (not external call)
- All other operations are internal or view functions

---

## 9. Testing Coverage

**Test File Structure:**
```
test/
├── TokenFactoryRegistry.t.sol    # Registry tests (30+ tests)
├── factories/
│   ├── ERC20Factory.t.sol        # ERC20 factory tests (25+ tests)
│   ├── ERC721Factory.t.sol       # ERC721 factory tests (25+ tests)
│   └── ERC1155Factory.t.sol      # ERC1155 factory tests (25+ tests)
└── tokens/
    ├── DewizERC20.t.sol          # ERC20 token tests (35+ tests)
    ├── DewizERC721.t.sol         # ERC721 token tests (35+ tests)
    └── DewizERC1155.t.sol        # ERC1155 token tests (35+ tests)
```

**Total Tests: 202+ passing**

**Test Categories:**
1. Unit tests per contract
2. Integration tests for workflows
3. Fuzz tests for edge cases
4. Access control verification
5. Event emission checks
6. Gas optimization tests

**Known Test Status (from summary):**
- All 202 tests passing ✓
- Comprehensive coverage of happy paths
- Access control tests for all roles
- Feature flag tests (mintable, burnable, pausable)
- Compliance hook integration tests

**Test Gaps (to verify in Phase 2):**
- Reentrancy attack scenarios
- Gas exhaustion attacks (large batches)
- Malicious compliance hook behaviors
- Factory address validation edge cases
- Integer overflow/underflow (Solidity 0.8+ has built-in protection)

---

## 10. Solidity Version & Compiler Settings

**Solidity Version:**
```solidity
pragma solidity ^0.8.24;
```
- All contracts use Solidity 0.8.24
- Built-in overflow/underflow protection
- Custom errors supported
- OpenZeppelin v5.5 compatible

**Compiler Settings (from foundry.toml or project config):**
- `via_ir = true` - Use IR-based optimizer (better optimization)
- `optimizer_runs = 200` - Balanced for deployment and runtime costs
- EVM Version: Latest compatible (likely Shanghai or Cancun)

---

## Phase 1 Analysis Complete ✓

**Summary Statistics:**
- 13 Solidity contracts analyzed
- 1,644 total lines of code
- 8 actor types identified
- 50+ external/public functions mapped
- 20+ storage variables documented
- 5 primary system flows traced
- 12 risk components categorized
- 3 external call patterns identified

**Next Step: Phase 2 - Ultra-Granular Function Analysis**

Recommended starting points for Phase 2 (ordered by impact):
1. `TokenFactoryRegistry.registerERC20Factory()` - System setup foundation
2. `ERC20Factory.createToken()` - Token creation flow
3. `DewizERC20._update()` - Compliance integration (highest risk)
4. `DewizERC1155._update()` - Batch operations with external calls
5. `DewizERC20.setComplianceHook()` - Hook management

Each function will be analyzed:
- Line-by-line with First Principles
- Purpose, Inputs, Outputs, Effects
- 5 Whys (Why does this exist?)
- 5 Hows (How does this work?)
- Risk considerations per block
- Cross-function dependencies

---

**Document Version:** 1.0
**Status:** Phase 1 Complete, Ready for Phase 2
**Next Update:** After Phase 2 function analysis
