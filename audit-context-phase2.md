# Dewiz Token Factory - Security Audit Context Building
## Phase 2: Ultra-Granular Function Analysis

**Analysis Date:** 2026-01-16
**Methodology:** Trail of Bits Line-by-Line Analysis with First Principles, 5 Whys, 5 Hows
**Analyzer:** Claude Sonnet 4.5 via audit-context-building skill

---

## Analysis Structure

For each function:
1. **Purpose** - What does this function do and why does it exist?
2. **Inputs** - All parameters, types, validation
3. **Outputs** - Return values, side effects, events
4. **Line-by-Line Analysis** - Block-by-block breakdown
5. **5 Whys** - Deep reasoning about design decisions
6. **5 Hows** - Implementation mechanics
7. **Risk Analysis** - Security considerations per block
8. **Cross-Function Dependencies** - What calls this? What does this call?

---

## Function 1: TokenFactoryRegistry.registerERC20Factory()

**Location:** `src/TokenFactoryRegistry.sol:65-73`

```solidity
function registerERC20Factory(address factory) external onlyOwner {
    if (factory == address(0)) revert ZeroAddressFactory();

    erc20Factory = IERC20Factory(factory);
    factories[TokenType.ERC20] = factory;
    _addToRegisteredFactories(factory);

    emit FactoryRegistered(TokenType.ERC20, factory);
}
```

### Purpose

**What it does:**
Registers (or updates) the ERC20Factory address that will be used to create ERC20 tokens through the registry.

**Why it exists:**
The Abstract Factory pattern requires a central coordinator (TokenFactoryRegistry) to maintain references to concrete factories (ERC20Factory, ERC721Factory, ERC1155Factory). This function enables the registry owner to configure which factory implementation should be used for ERC20 token creation.

### Inputs

| Parameter | Type | Description | Validation |
|-----------|------|-------------|------------|
| `factory` | `address` | Address of the ERC20Factory contract | ✓ Non-zero check (line 66) |

**Access Control:**
- `external` visibility - Callable from outside the contract
- `onlyOwner` modifier - Only registry owner can execute (Ownable pattern)

### Outputs

**State Changes:**
1. `erc20Factory` (public IERC20Factory) - Set to new factory address
2. `factories[TokenType.ERC20]` (mapping) - Set to new factory address
3. `_registeredFactories` (array) - Factory address added if not already present

**Events:**
- `FactoryRegistered(TokenType.ERC20, factory)` - Emitted on successful registration

**Return Value:** None (void function)

### Line-by-Line Analysis

#### Block 1: Access Control (line 65)
```solidity
function registerERC20Factory(address factory) external onlyOwner {
```

**What happens:**
- Function signature declares external visibility and owner-only access
- `onlyOwner` modifier from OpenZeppelin's Ownable contract executes first

**First Principles:**
- **Why external?** Function is only called from outside the contract (by owner via EOA or other contract)
- **Why onlyOwner?** Factory registration is a privileged operation that controls system behavior

**onlyOwner Modifier Execution:**
```solidity
// From OpenZeppelin Ownable.sol
modifier onlyOwner() {
    _checkOwner();  // Reverts if msg.sender != owner()
    _;
}
```

**Risk Considerations:**
- ✅ **GOOD**: Access control prevents unauthorized factory updates
- ⚠️ **RISK**: Single owner (not multi-sig) is a centralization risk
- ⚠️ **RISK**: No time-lock on critical registry updates
- ⚠️ **RISK**: Owner key compromise = full registry control

**5 Whys - Why onlyOwner?**
1. **Why restrict access?** → To prevent malicious actors from redirecting token creation
2. **Why not role-based?** → Simple ownership model is sufficient for registry coordination
3. **Why not immutable?** → Flexibility to upgrade factory implementations without redeploying registry
4. **Why not governed?** → Current design favors simplicity over decentralization
5. **Why trust owner?** → Assumption: Owner is a trusted entity (multi-sig recommended but not enforced)

#### Block 2: Input Validation (line 66)
```solidity
if (factory == address(0)) revert ZeroAddressFactory();
```

**What happens:**
- Checks if input address is the zero address (0x0000...0000)
- Reverts with custom error `ZeroAddressFactory` if true
- No gas refund for revert (post-London fork)

**First Principles:**
- **Why check zero address?** → address(0) is never a valid contract, would break token creation
- **Why custom error?** → Gas efficiency (cheaper than require strings in Solidity 0.8+)
- **Why revert (not return false)?** → Fail-fast pattern, no ambiguity about success

**5 Hows - How does this validate?**
1. **How is equality checked?** → EVM opcode `EQ` compares 20-byte addresses
2. **How does revert work?** → EVM `REVERT` opcode undoes state changes and returns error data
3. **How is error encoded?** → Custom error selector (4-byte hash) + no additional data
4. **How much gas is saved?** → ~50-100 gas vs. require string (no string data in error)
5. **How does caller handle revert?** → Transaction fails, state rolled back, error surfaced to user

**Risk Considerations:**
- ✅ **GOOD**: Prevents obviously invalid factory address
- ⚠️ **MISSING**: No check that `factory` is actually a contract (could be EOA)
- ⚠️ **MISSING**: No check that `factory` implements IERC20Factory interface (no ERC165)
- ⚠️ **MISSING**: No check for contract code length (`factory.code.length > 0`)

**Attack Scenario - EOA as Factory:**
```solidity
// Attacker: Owner (malicious or key compromise)
registry.registerERC20Factory(attackerEOA)
// No revert! EOA address accepted

// Later, user tries to create token:
registry.createERC20Token(params)
// Line 145: return erc20Factory.createToken(params)
// This will revert with "low-level call failed" because EOA has no code
// Result: DoS on ERC20 token creation
```

**Recommendation:**
Add contract existence check:
```solidity
if (factory == address(0)) revert ZeroAddressFactory();
if (factory.code.length == 0) revert FactoryNotContract();  // Add this
```

#### Block 3: Factory Reference Update (line 68)
```solidity
erc20Factory = IERC20Factory(factory);
```

**What happens:**
- Type-casts `address` parameter to `IERC20Factory` interface
- Stores interface reference in state variable `erc20Factory`
- No validation that `factory` actually implements the interface

**First Principles:**
- **Why type-cast?** → Enables ABI encoding for future function calls
- **Why store as interface?** → Type safety at Solidity level (compile-time, not runtime)
- **Why not validate?** → Solidity interfaces are compile-time only, no runtime enforcement

**Interface Type-Casting Mechanics:**
```solidity
// What the cast does:
IERC20Factory(factory)
// 1. Compiler: "I'll assume this address has IERC20Factory functions"
// 2. Compiler: "I'll encode function calls using IERC20Factory ABI"
// 3. Runtime: No validation! Call will fail if interface mismatch

// What it DOESN'T do:
// ❌ Check if factory implements the interface
// ❌ Check if factory has any code at all
// ❌ Verify function signatures match
```

**5 Whys - Why no interface validation?**
1. **Why no ERC165 check?** → IERC20Factory doesn't inherit ERC165 (design choice)
2. **Why no function existence check?** → Expensive (would need to call every function)
3. **Why trust the address?** → Assumption: Owner provides correct factory
4. **Why not use ERC165?** → Additional complexity, gas costs, not standard for factories
5. **Why risk it?** → Tradeoff: Simplicity vs. safety (owner responsibility)

**Risk Considerations:**
- ⚠️ **RISK**: No runtime validation that `factory` implements IERC20Factory
- ⚠️ **RISK**: Wrong interface implementation will cause silent failures later
- ⚠️ **RISK**: Malicious owner can register contract with different ABI

**Attack Scenario - Interface Mismatch:**
```solidity
// Attacker: Malicious owner deploys fake factory
contract FakeFactory {
    // Has createToken() but different signature
    function createToken(bytes calldata maliciousData) external returns (address) {
        // Drain registry or do something malicious
    }
}

// Owner registers fake factory
registry.registerERC20Factory(address(fakeFactory))
// No revert! No validation!

// User creates token
registry.createERC20Token(goodParams)
// ABI encoding mismatch, call fails or succeeds with wrong data
```

**Recommendation:**
Consider ERC165 support:
```solidity
// In IERC20Factory.sol
interface IERC20Factory is IERC165 {
    // Interface ID: bytes4(keccak256("createToken(...)")) ^ ...
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    ...
}

// In registerERC20Factory()
if (!IERC165(factory).supportsInterface(type(IERC20Factory).interfaceId)) {
    revert InvalidFactoryInterface();
}
```

#### Block 4: Mapping Update (line 69)
```solidity
factories[TokenType.ERC20] = factory;
```

**What happens:**
- Updates `factories` mapping at key `TokenType.ERC20` (enum value 0)
- Stores raw `address` (not interface type)
- Overwrites previous value if factory was already registered

**First Principles:**
- **Why mapping?** → O(1) lookup by token type enum
- **Why store address?** → Generic storage for all factory types
- **Why also store in erc20Factory?** → Type-safe interface access vs. generic lookup

**Storage Layout:**
```solidity
// Storage slot calculation:
// keccak256(abi.encode(uint8(TokenType.ERC20), uint256(factoriesSlotNumber)))
// Value: 20 bytes (address)

// Redundant storage:
erc20Factory      → Stores factory as IERC20Factory interface (slot X)
factories[ERC20]  → Stores factory as address (slot Y)
// Both point to same address, different types
```

**5 Hows - How does mapping update work?**
1. **How is key computed?** → Enum TokenType.ERC20 = uint8(0)
2. **How is storage slot determined?** → keccak256(key || mapping slot)
3. **How is overwrite handled?** → Direct replacement, no checks for existing value
4. **How much gas?** → SSTORE (cold: 22,100 gas if new, warm: 5,000 gas if update)
5. **How is old value handled?** → Overwritten, no refund, no event for old value

**Risk Considerations:**
- ⚠️ **RISK**: Silent overwrite of existing factory (no warning to owner)
- ⚠️ **RISK**: No event emission for previous factory address
- ⚠️ **INFO**: Redundant storage (erc20Factory + factories[ERC20]) costs extra gas

**Attack Scenario - Accidental Factory Overwrite:**
```solidity
// Scenario: Owner accidentally re-registers factory
registry.registerERC20Factory(factoryV1)  // Initial registration
// ... time passes, tokens created with factoryV1 ...

registry.registerERC20Factory(factoryV2)  // Oops! Owner meant to deploy new registry
// No warning! No confirmation! Silent overwrite!

// Impact:
// - Old tokens still reference factoryV1 (their `factory` immutable)
// - New tokens will use factoryV2
// - `isTokenFromAnyFactory()` might return unexpected results
// - No event indicating which factory was replaced
```

**Recommendation:**
Consider emitting old factory address:
```solidity
address oldFactory = address(erc20Factory);
erc20Factory = IERC20Factory(factory);
factories[TokenType.ERC20] = factory;
emit FactoryRegistered(TokenType.ERC20, factory, oldFactory);  // Add oldFactory param
```

Or require explicit confirmation for updates:
```solidity
if (address(erc20Factory) != address(0)) {
    // Factory already registered, require explicit update flag
    revert FactoryAlreadyRegistered();
}
```

#### Block 5: Array Management (line 70)
```solidity
_addToRegisteredFactories(factory);
```

**What happens:**
- Calls internal helper function to add `factory` to `_registeredFactories[]` array
- Function checks for duplicates before adding (see detailed analysis below)

**Function Call Flow:**
```
registerERC20Factory()
    └─> _addToRegisteredFactories(factory)
        ├─ Loop through _registeredFactories[]
        ├─ If factory already exists, return early
        └─ Otherwise, push to array
```

**First Principles:**
- **Why array?** → Enables `getAllFactories()` query function
- **Why check duplicates?** → Prevent array bloat from repeated registrations
- **Why internal function?** → Code reuse (called by all 4 register functions)

**5 Whys - Why maintain _registeredFactories array?**
1. **Why track all factories?** → Query interface for off-chain clients (getAllFactories)
2. **Why not iterate factories mapping?** → Solidity mappings are not iterable
3. **Why not skip this?** → Useful for UIs to discover all available factories
4. **Why risk array growth?** → Bounded by number of token types (currently 3)
5. **Why not just use events?** → Events are not queryable on-chain

**_addToRegisteredFactories() Deep Dive:**
```solidity
// Line 291-300
function _addToRegisteredFactories(address factory) internal {
    // Check if already registered
    uint256 length = _registeredFactories.length;  // Gas optimization: cached length
    for (uint256 i = 0; i < length; i++) {
        if (_registeredFactories[i] == factory) {
            return;  // Early return, no push
        }
    }
    _registeredFactories.push(factory);  // Add to array
}
```

**Loop Gas Analysis:**
- Best case: Factory at index 0 → 1 iteration → ~300 gas
- Worst case: Factory not found → N iterations → ~300N gas
- Current system: N = 3 (ERC20, ERC721, ERC1155) → ~900 gas max
- If 100 factories: 30,000 gas (still acceptable)

**Risk Considerations:**
- ✅ **GOOD**: Duplicate prevention avoids array bloat
- ✅ **GOOD**: Gas optimization with cached array length
- ⚠️ **RISK**: O(N) loop, but N is small (acceptable)
- ⚠️ **RISK**: No maximum array size (theoretical DoS if owner registers millions of factories)

**Attack Scenario - Array Bloat:**
```solidity
// Attacker: Malicious owner
for (uint i = 0; i < 10000; i++) {
    registry.registerERC20Factory(generateFakeFactory(i));
}
// _registeredFactories.length = 10,000 (only 1 real factory needed)

// Later, anyone calls:
address[] memory factories = registry.getAllFactories();
// Returns array with 10,000 addresses
// Gas cost: ~300,000 gas just to copy array to memory
// Most RPC nodes will timeout or reject the call
// Result: DoS on getAllFactories() query
```

**Recommendation:**
Add maximum factory limit:
```solidity
uint256 public constant MAX_FACTORIES = 10;  // Reasonable limit

function _addToRegisteredFactories(address factory) internal {
    if (_registeredFactories.length >= MAX_FACTORIES) {
        revert TooManyFactories();
    }
    // ... rest of function
}
```

#### Block 6: Event Emission (line 72)
```solidity
emit FactoryRegistered(TokenType.ERC20, factory);
```

**What happens:**
- Emits `FactoryRegistered` event with token type enum and factory address
- Event data is stored in transaction logs (not in contract storage)
- Indexed parameters enable efficient log filtering

**Event Definition:**
```solidity
// Line 41
event FactoryRegistered(TokenType indexed tokenType, address indexed factoryAddress);
```

**Log Entry Structure:**
```
Log Entry {
    address: 0x<TokenFactoryRegistry address>
    topics: [
        0x<event signature hash: keccak256("FactoryRegistered(uint8,address)")>
        0x<indexed tokenType: 0x00...00 (ERC20 = 0)>
        0x<indexed factoryAddress: 0x1234...>
    ]
    data: (none, all params are indexed)
}
```

**First Principles:**
- **Why emit event?** → Off-chain monitoring, UI updates, historical record
- **Why indexed params?** → Enable filtering by tokenType or factoryAddress
- **Why 2 indexed params?** → Maximum 3 indexed params in Solidity (1 used for event signature)

**5 Hows - How are events stored?**
1. **How is event logged?** → EVM LOG2 opcode (2 indexed topics + event signature)
2. **How much gas?** → 375 gas base + 375 per topic + 8 gas per byte of data = ~1,125 gas
3. **How are events retrieved?** → JSON-RPC eth_getLogs with topic filters
4. **How long are logs stored?** → Indefinitely in blockchain history
5. **How do clients use this?** → Index events to track factory registrations over time

**Risk Considerations:**
- ✅ **GOOD**: Event enables off-chain tracking of factory updates
- ✅ **GOOD**: Indexed parameters enable efficient filtering
- ⚠️ **MISSING**: No event parameter for previous factory address (if overwriting)
- ℹ️ **INFO**: Event cannot be used for on-chain logic (logs not accessible in EVM)

**Example Event Usage:**
```typescript
// Off-chain client (ethers.js)
const filter = registry.filters.FactoryRegistered(
    TokenType.ERC20,  // Filter for ERC20 only
    null              // Any factory address
);

const events = await registry.queryFilter(filter);
// Returns all ERC20 factory registrations

events.forEach(event => {
    console.log(`ERC20 Factory registered: ${event.args.factoryAddress}`);
    console.log(`Block number: ${event.blockNumber}`);
    console.log(`Transaction: ${event.transactionHash}`);
});
```

### Cross-Function Dependencies

**Called By:**
- External actors (registry owner only)
- Possible contracts with owner role (if ownership transferred to contract)

**Calls:**
- `onlyOwner()` modifier (OpenZeppelin Ownable)
- `_addToRegisteredFactories(address)` internal function
- `emit FactoryRegistered(...)` event logger

**Related Functions:**
- `registerERC721Factory(address)` - Identical pattern for ERC721
- `registerERC1155Factory(address)` - Identical pattern for ERC1155
- `registerAllFactories(address, address, address)` - Batch version
- `getAllFactories()` - Returns `_registeredFactories[]` array
- `getFactory(TokenType)` - Returns factory from `factories` mapping
- `isFactoryRegistered(TokenType)` - Checks if `factories[type] != address(0)`

### Summary Risk Assessment

**Critical Risks:**
1. ❌ **No contract code validation** - EOA can be registered as factory (DoS)
2. ❌ **No interface validation** - Wrong interface can break token creation
3. ⚠️ **Silent factory overwrites** - No warning when replacing existing factory

**Medium Risks:**
4. ⚠️ **Centralized owner control** - Single owner key compromise = full registry control
5. ⚠️ **No time-lock on updates** - Instant factory changes (no grace period for users)

**Low Risks:**
6. ℹ️ **Array bloat potential** - Malicious owner could fill `_registeredFactories[]` (DoS on getAllFactories)
7. ℹ️ **Redundant storage** - `erc20Factory` and `factories[ERC20]` store same address

**Recommendations Priority:**
1. **HIGH**: Add `factory.code.length > 0` check
2. **HIGH**: Consider ERC165 interface validation
3. **MEDIUM**: Emit old factory address in event
4. **MEDIUM**: Add confirmation for factory overwrites
5. **LOW**: Add maximum factory limit constant
6. **LOW**: Consider time-lock for critical registry updates

---

## Function 2: ERC20Factory.createToken()

**Location:** `src/factories/ERC20Factory.sol:50-66`

```solidity
function createToken(ERC20TokenParams calldata params) external override returns (address tokenAddress) {
    DewizERC20 token = new DewizERC20(
        params.name,
        params.symbol,
        params.decimals,
        params.initialSupply,
        params.initialHolder,
        msg.sender,
        params.isMintable,
        params.isBurnable,
        params.isPausable,
        params.complianceHook
    );

    tokenAddress = address(token);
    _registerToken(tokenAddress, params.name, params.symbol);
}
```

### Purpose

**What it does:**
Creates a new DewizERC20 token instance with advanced configuration parameters and registers it in the factory's tracking system.

**Why it exists:**
Implements the Factory pattern to enable permissionless token creation with custom parameters. This is the "advanced" creation function (vs. `createSimpleToken()`) that exposes all configuration options.

### Inputs

**Parameter Struct:**
```solidity
struct ERC20TokenParams {
    string name;              // Token name (e.g., "Dewiz USDC")
    string symbol;            // Token symbol (e.g., "USDC")
    uint8 decimals;           // Decimal places (e.g., 6 for USDC, 18 for ETH-like)
    uint256 initialSupply;    // Initial mint amount (in base units)
    address initialHolder;    // Address to receive initial supply
    bool isMintable;          // Can tokens be minted after creation?
    bool isBurnable;          // Can tokens be burned by holders?
    bool isPausable;          // Can admin pause transfers?
    address complianceHook;   // Optional compliance validation contract
}
```

**Input Validation:** None in this function (validation in DewizERC20 constructor)

**Access Control:**
- `external` visibility - Callable by anyone
- No modifiers - **Permissionless token creation**
- `override` keyword - Implements IERC20Factory interface

### Outputs

**State Changes:**
1. New DewizERC20 contract deployed to blockchain
2. `_tokens[]` array extended with new token address
3. `_isFactoryToken[tokenAddress]` set to true
4. `_creatorTokens[msg.sender]` array extended

**Events:**
- `TokenCreated(tokenAddress, msg.sender, params.name, params.symbol)` - Emitted by `_registerToken()`

**Return Value:**
- `tokenAddress` (address) - Address of newly deployed token contract

### Line-by-Line Analysis

#### Block 1: Token Deployment (lines 51-62)
```solidity
DewizERC20 token = new DewizERC20(
    params.name,
    params.symbol,
    params.decimals,
    params.initialSupply,
    params.initialHolder,
    msg.sender,              // admin = token creator
    params.isMintable,
    params.isBurnable,
    params.isPausable,
    params.complianceHook
);
```

**What happens:**
- `new` keyword triggers contract deployment
- EVM creates new account at deterministic address: `keccak256(rlp([creator, nonce]))`
- Constructor executes with provided parameters
- Gas cost: ~3,000,000 gas for full deployment + initialization

**First Principles:**
- **Why `new` keyword?** → Solidity syntax for CREATE opcode (deploy new contract)
- **Why not CREATE2?** → CREATE is simpler, deterministic address not needed here
- **Why pass msg.sender as admin?** → Token creator becomes DEFAULT_ADMIN_ROLE

**Contract Creation Mechanics:**
```
EVM CREATE Opcode Flow:
1. Calculate new contract address: address = keccak256(rlp([sender_address, nonce]))
2. Allocate new account at address
3. Transfer value (0 in this case, no payable)
4. Set code to init bytecode
5. Execute constructor
6. Store deployed bytecode at address
7. Return address to caller

Gas Costs:
- CREATE base: 32,000 gas
- Constructor execution: ~2,500,000 gas (ERC20 + AccessControl + initialization)
- Code storage: ~200 gas per byte * ~15KB = ~3,000,000 gas
- Total: ~5,500,000 gas per token deployment
```

**5 Whys - Why pass msg.sender as admin?**
1. **Why not params.initialHolder?** → Holder receives tokens, creator controls access (separation of concerns)
2. **Why not factory?** → Factory shouldn't control user tokens (avoid centralization)
3. **Why not params.admin?** → Actually, constructor takes `admin_` param! Line 57: `msg.sender` is passed as admin
4. **Why does creator become admin?** → Creator (who pays gas) should control their token
5. **Why is this secure?** → Each token creator controls only their own tokens (isolation)

**Parameter Flow Analysis:**
```solidity
// User calls:
factory.createToken({
    name: "MyToken",
    initialHolder: 0xAlice,  // Alice gets tokens
    // ... other params
})

// Factory passes:
new DewizERC20(
    params.name,
    params.initialHolder,    // Alice gets initial supply
    msg.sender,              // User becomes admin (NOT Alice)
    // ...
)

// Result:
// - Alice: Has tokens, no admin rights
// - User (msg.sender): Has admin rights, no tokens
// - Separation of economic rights (tokens) and control rights (admin)
```

**Risk Considerations:**
- ✅ **GOOD**: Permissionless token creation (no gatekeeping)
- ⚠️ **RISK**: No validation on params (empty strings, zero decimals, etc.)
- ⚠️ **RISK**: Out-of-gas attacks possible with extreme parameters
- ⚠️ **RISK**: Front-running: Attacker can deploy same name/symbol first
- ⚠️ **RISK**: No uniqueness enforcement (multiple tokens with same name/symbol)

**Attack Scenario - Token Squatting:**
```solidity
// Scenario: Front-running token creation
// 1. Victim submits: createToken("USDC", "USDC", ...)
// 2. Attacker sees mempool, submits same with higher gas price
// 3. Attacker's token deploys first
// 4. Victim's token deploys with same name/symbol (no revert)
// 5. Users confused about which is the "real" USDC

// Impact: Phishing, confusion, loss of trust
// Mitigation: Off-chain verification, factory tracking, whitelists
```

#### Block 2: Token Registration (lines 64-65)
```solidity
tokenAddress = address(token);
_registerToken(tokenAddress, params.name, params.symbol);
```

**What happens:**
- Line 64: Extract address from deployed contract instance
- Line 65: Call internal function to register token in tracking arrays

**First Principles:**
- **Why extract address?** → Return value must be `address` type (not contract instance)
- **Why register after deployment?** → Follows Checks-Effects-Interactions (though CREATE is interaction)
- **Why not register before?** → Can't know address before deployment

**_registerToken() Execution:**
```solidity
// Line 146-152
function _registerToken(address tokenAddress, string memory name, string memory symbol) internal {
    _tokens.push(tokenAddress);                          // Add to global array
    _isFactoryToken[tokenAddress] = true;                // Mark as factory token
    _creatorTokens[msg.sender].push(tokenAddress);       // Add to creator's array

    emit TokenCreated(tokenAddress, msg.sender, name, symbol);  // Emit event
}
```

**Checks-Effects-Interactions Violation?**
```
Traditional CEI Pattern:
1. Checks   ✓ (none needed for permissionless creation)
2. Effects  ❌ SHOULD BE HERE (but actually happens after Interaction)
3. Interaction ✓ (new DewizERC20 - external contract creation)
4. Effects  ✓ (actually here: _registerToken updates state)

Why this is (probably) safe:
- new keyword creates fresh contract, no reentrancy risk from constructor
- Constructor doesn't call back to factory
- No external calls during registration

Why this could be risky:
- If constructor had malicious code, it could call back before registration
- If compliance hook in constructor made external calls
- Factory state would be inconsistent during constructor execution
```

**Reentrancy Analysis:**
```solidity
// Attack scenario (theoretical):
contract MaliciousToken is DewizERC20 {
    constructor(...) DewizERC20(...) {
        // Inside constructor, before factory._registerToken() is called
        // Factory state: _isFactoryToken[address(this)] = false (not yet set)

        // Attacker could call back:
        ERC20Factory(factory).isTokenFromFactory(address(this));
        // Returns: false (token not registered yet!)

        // But what can attacker do with this?
        // - Very limited: most functions are view-only
        // - Can't exploit for financial gain
        // - Worst case: confuse off-chain indexers
    }
}

// Verdict: Low risk, but technically violates CEI
```

**Risk Considerations:**
- ✅ **ACCEPTABLE**: CEI violation is low-risk due to fresh contract deployment
- ⚠️ **INFO**: Factory state temporarily inconsistent during constructor execution
- ⚠️ **INFO**: _registerToken() does 3 state updates + event (gas: ~60,000)

**5 Hows - How does registration work?**
1. **How is tokenAddress stored?** → Pushed to _tokens[] dynamic array (SSTORE)
2. **How is mapping updated?** → _isFactoryToken[addr] = true (SSTORE, 22,100 gas if new slot)
3. **How is creator tracking done?** → _creatorTokens[msg.sender].push(addr) (nested mapping + array)
4. **How much gas for registration?** → ~60,000 gas (3 SSTOREs + event)
5. **How to query later?** → isTokenFromFactory(addr) in O(1), getAllTokens() in O(n)

### Function 2 Complete: Cross-Function Dependencies

**Called By:**
- `TokenFactoryRegistry.createERC20Token(params)` - Advanced creation via registry
- External users - Direct factory calls (bypassing registry)

**Calls:**
- `new DewizERC20(...)` - Constructor execution (analyzed next)
- `_registerToken(address, string, string)` - Internal registration

**Related Functions:**
- `createSimpleToken(name, symbol, supply)` - Simplified version with defaults
- `isTokenFromFactory(address)` - Verify if token came from this factory
- `getTokensByCreator(address)` - Query tokens by creator

### Function 2 Summary Risk Assessment

**Critical Risks:**
1. ⚠️ **No input validation** - Empty strings, zero decimals, malicious compliance hooks accepted
2. ⚠️ **Unbounded gas costs** - Large initial supply can exceed block gas limit
3. ⚠️ **Token squatting** - No uniqueness enforcement on name/symbol

**Medium Risks:**
4. ⚠️ **CEI violation** - State updates after external interaction (low exploitability)
5. ⚠️ **Front-running** - Mempool visibility enables token name/symbol sniping

**Low Risks:**
6. ℹ️ **Permissionless creation** - Anyone can create tokens (design choice, not bug)

**Recommendations:**
1. **HIGH**: Add input validation for params (non-empty strings, reasonable decimals)
2. **MEDIUM**: Consider name/symbol registry to prevent squatting
3. **LOW**: Document CEI violation and why it's acceptable

---

## Function 3: DewizERC20 Constructor

**Location:** `src/tokens/DewizERC20.sol:67-99`

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
    bool isPausable_,
    address complianceHook_
) ERC20(name_, symbol_) {
    _decimals = decimals_;
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

    if (initialSupply_ > 0 && initialHolder_ != address(0)) {
        _mint(initialHolder_, initialSupply_);
    }
}
```

### Purpose

**What it does:**
Initializes a new DewizERC20 token with configurable feature flags, access control roles, compliance hook, and optional initial supply.

**Why it exists:**
Constructor is the one-time initialization phase for the token. Sets immutable values (feature flags, factory address) and configurable state (roles, compliance hook, balances).

### Inputs

| Parameter | Type | Description | Validation |
|-----------|------|-------------|------------|
| `name_` | `string memory` | Token name | ❌ None (empty string accepted) |
| `symbol_` | `string memory` | Token symbol | ❌ None (empty string accepted) |
| `decimals_` | `uint8` | Decimal places (0-255) | ❌ None (0 accepted, 255 allowed) |
| `initialSupply_` | `uint256` | Initial mint amount | ✅ Checked > 0 before minting |
| `initialHolder_` | `address` | Receives initial supply | ✅ Checked != address(0) before minting |
| `admin_` | `address` | Receives admin roles | ❌ None (address(0) accepted - breaks token!) |
| `isMintable_` | `bool` | Enable minting | ✅ No validation needed (boolean) |
| `isBurnable_` | `bool` | Enable burning | ✅ No validation needed (boolean) |
| `isPausable_` | `bool` | Enable pausing | ✅ No validation needed (boolean) |
| `complianceHook_` | `address` | Compliance contract | ❌ None (any address accepted, even EOA) |

### Outputs

**State Changes:**
1. **Immutable State (Cannot Change):**
   - `_decimals` - Token decimals
   - `mintable` - Can mint after creation
   - `burnable` - Can burn tokens
   - `pausable` - Can pause transfers
   - `factory` - Factory that created this token

2. **Mutable State (Can Change):**
   - `complianceHook` - Compliance validation contract
   - Role grants for admin (DEFAULT_ADMIN_ROLE, MINTER_ROLE, PAUSER_ROLE)
   - Initial token balance for initialHolder_

**Events:**
- `RoleGranted(role, admin_, msg.sender)` - Emitted for each role grant (up to 3 times)
- `Transfer(address(0), initialHolder_, initialSupply_)` - If initial supply > 0

**Return Value:** None (constructors don't return)

### Line-by-Line Analysis

#### Block 1: Base Contract Initialization (line 78)
```solidity
) ERC20(name_, symbol_) {
```

**What happens:**
- Calls OpenZeppelin ERC20 base constructor
- Sets token name and symbol in parent contract storage
- Initializes _balances and _allowances mappings (empty)
- Total supply starts at 0

**ERC20 Constructor (OpenZeppelin):**
```solidity
// From @openzeppelin/contracts/token/ERC20/ERC20.sol
constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
}
```

**First Principles:**
- **Why call parent constructor?** → Required by Solidity for contract inheritance
- **Why pass name/symbol?** → ERC20 standard requires these metadata fields
- **Why not validate?** → OpenZeppelin accepts any strings (including empty)

**5 Whys - Why allow empty name/symbol?**
1. **Why no validation?** → OpenZeppelin prioritizes flexibility over opinionation
2. **Why not revert on empty?** → Some use cases might want anonymous tokens
3. **Why is this risky?** → Empty strings make tokens indistinguishable in UIs
4. **Why not add validation here?** → Design choice: factory should validate, not token
5. **Why does factory not validate?** → Missing requirement (should be added)

**Risk Considerations:**
- ⚠️ **RISK**: Empty name/symbol accepted (UX nightmare)
- ⚠️ **RISK**: Very long strings accepted (gas DOS on string operations)
- ⚠️ **RISK**: Unicode/emoji in name/symbol (display issues in UIs)

**Attack Scenario - Empty Name Token:**
```solidity
// Attacker creates token with empty name/symbol
factory.createToken({
    name: "",
    symbol: "",
    // ... other params
})

// Result in UI:
// Token Name: [blank]
// Symbol: [blank]
// Users can't distinguish from other empty-name tokens
// Phishing: "This is the real [blank] token!"
```

#### Block 2: Immutable Assignments (lines 79-84)
```solidity
_decimals = decimals_;
mintable = isMintable_;
burnable = isBurnable_;
pausable = isPausable_;
factory = msg.sender;
complianceHook = IComplianceHook(complianceHook_);
```

**What happens:**
- Lines 79-83: Set immutable feature flags (CANNOT be changed later)
- Line 84: Set compliance hook (CAN be changed via setComplianceHook)

**Storage vs. Immutable:**
```solidity
// Immutable (lines 79-83):
// - Stored in contract bytecode, not storage slots
// - Read via PUSH opcode (3 gas) instead of SLOAD (2,100 gas)
// - Cannot be modified after deployment
// - ~70x cheaper to read than storage

// Mutable (line 84):
// - Stored in storage slot
// - Read via SLOAD (2,100 gas)
// - Can be modified by admin via setComplianceHook()
// - Expensive to read, but flexible
```

**5 Hows - How do immutables work?**
1. **How are they stored?** → Appended to deployed bytecode, not in storage
2. **How are they read?** → PUSH opcode loads from code section
3. **How much gas?** → 3 gas (PUSH) vs. 2,100 gas (SLOAD) = 700x cheaper
4. **How are they set?** → Once during constructor, then hardcoded in bytecode
5. **How to change them?** → Impossible, must deploy new contract

**Decimal Analysis:**
```solidity
_decimals = decimals_;  // Can be 0-255 (uint8 range)

// Impact of different decimals:
// decimals = 0  → 1 token = 1 smallest unit (like a counter)
// decimals = 6  → 1 token = 1,000,000 smallest units (USDC style)
// decimals = 18 → 1 token = 1e18 smallest units (ETH style)
// decimals = 255 → 1 token = 1.157e77 smallest units (absurd precision)

// Why no validation?
// - ERC20 standard allows any uint8
// - Some use cases need 0 decimals (NFT-like tokens)
// - Some need high precision (scientific calculations)

// Risk: User confusion if decimals != 18
```

**Factory Address Assignment:**
```solidity
factory = msg.sender;  // msg.sender = ERC20Factory address

// Why store factory?
// 1. Provenance: Token knows its origin
// 2. Verification: Factory can prove it created this token
// 3. Upgrades: Future features might need factory reference

// Why immutable?
// - Factory address never needs to change
// - Gas optimization: cheap reads
// - Security: Prevents malicious factory address updates
```

**Compliance Hook Assignment:**
```solidity
complianceHook = IComplianceHook(complianceHook_);

// Critical Security Analysis:
// ❌ No validation that complianceHook_ is a contract
// ❌ No validation that it implements IComplianceHook
// ❌ address(0) is accepted (treated as "no hook")
// ❌ EOA address is accepted (will fail on first call)

// Why is hook mutable?
// - Compliance requirements change over time
// - Admin needs flexibility to update/remove hook
// - Tradeoff: Flexibility vs. immutability security
```

**Risk Considerations - Compliance Hook:**
- ❌ **CRITICAL**: No code existence check (`complianceHook_.code.length == 0` is allowed)
- ❌ **CRITICAL**: No interface validation (ERC165 not used)
- ⚠️ **HIGH**: Malicious hook can DoS or steal funds
- ✅ **ACCEPTABLE**: address(0) is valid (means "no hook")

**Attack Scenario - EOA as Compliance Hook:**
```solidity
// Factory call with EOA as hook:
factory.createToken({
    complianceHook: 0xAttackerEOA,  // Not a contract!
    // ... other params
})

// Token deploys successfully (no validation)
complianceHook = IComplianceHook(0xAttackerEOA)

// Later, user tries to transfer:
token.transfer(recipient, amount)
└─> _update(from, to, amount)
    └─> complianceHook.onTransfer(...)  // External call to EOA
        └─> REVERTS: EOA has no code
        └─> All transfers permanently broken!

// Result: Token is bricked, all funds frozen
```

**Attack Scenario - Malicious Hook Contract:**
```solidity
contract MaliciousHook is IComplianceHook {
    function onTransfer(address, address from, address to, uint256, uint256 amount) external {
        // Steal funds via reentrancy
        DewizERC20(msg.sender).transferFrom(from, attacker, amount);
    }
    // ... other functions
}

// Impact: Every transfer doubles as a theft
// Mitigation: Reentrancy guards (not implemented!)
```

#### Block 3: Role Grants (lines 86-94)
```solidity
_grantRole(DEFAULT_ADMIN_ROLE, admin_);

if (isMintable_) {
    _grantRole(MINTER_ROLE, admin_);
}

if (isPausable_) {
    _grantRole(PAUSER_ROLE, admin_);
}
```

**What happens:**
- Line 86: Grant DEFAULT_ADMIN_ROLE unconditionally to admin_
- Lines 88-90: Grant MINTER_ROLE only if mintable=true
- Lines 92-94: Grant PAUSER_ROLE only if pausable=true

**_grantRole() Mechanics (OpenZeppelin AccessControl):**
```solidity
function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
    if (!hasRole(role, account)) {
        _roles[role].hasRole[account] = true;
        emit RoleGranted(role, account, _msgSender());
        return true;
    }
    return false;
}

// Storage layout:
// _roles[role].hasRole[account] = bool
// Example: _roles[MINTER_ROLE].hasRole[0xAlice] = true

// Gas cost: ~22,100 per new role (cold SSTORE)
```

**First Principles - Why conditional role grants?**
- **Why not always grant MINTER_ROLE?** → If mintable=false, role is useless
- **Why grant if useless?** → Still granted! Admin has role but can't use it
- **Why not skip grant?** → Design choice: consistent admin powers regardless of flags

**Role Grant Analysis:**
```
Role Grant Logic:
┌────────────────────────────────────────────────────────────────┐
│ ALWAYS GRANTED:                                                │
│ - DEFAULT_ADMIN_ROLE → admin_                                  │
│   (Can grant/revoke roles, set compliance hook)                │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ CONDITIONALLY GRANTED (based on immutable flags):              │
│                                                                 │
│ if (isMintable_ == true):                                      │
│   - MINTER_ROLE → admin_                                       │
│   - Admin can later grant MINTER_ROLE to others                │
│                                                                 │
│ if (isPausable_ == true):                                      │
│   - PAUSER_ROLE → admin_                                       │
│   - Admin can later grant PAUSER_ROLE to others                │
└────────────────────────────────────────────────────────────────┘

Oddity: PAUSER_ROLE granted even if pausable=false!
- Lines 92-94: Grant PAUSER_ROLE if isPausable_
- But pause() function checks both: onlyRole(PAUSER_ROLE) AND pausable flag
- If pausable=false, admin has useless PAUSER_ROLE

Actually, looking at lines 92-94 more carefully:
if (isPausable_) { _grantRole(PAUSER_ROLE, admin_); }
- PAUSER_ROLE is NOT granted if pausable=false (correct!)
```

**Risk Considerations - Role Grants:**
- ❌ **CRITICAL**: No validation that `admin_` != address(0)
- ⚠️ **HIGH**: If admin_=address(0), roles go to null address (token is unmanageable!)
- ✅ **GOOD**: Conditional role grants match feature flags
- ✅ **GOOD**: Admin can later delegate roles to others

**Attack Scenario - Null Admin:**
```solidity
// Factory call with address(0) as admin:
factory.createToken({
    admin: address(0),  // Typo or malicious intent
    // ... other params
})

// Constructor executes:
_grantRole(DEFAULT_ADMIN_ROLE, address(0))  // Grants to null address!
_grantRole(MINTER_ROLE, address(0))         // If mintable
_grantRole(PAUSER_ROLE, address(0))         // If pausable

// Result:
// - No one has admin rights (address(0) can't sign transactions)
// - Token is permanently unmanageable
// - Can't set compliance hook
// - Can't grant roles to legitimate admins
// - Can't mint more tokens (if mintable)
// - Can't pause in emergency (if pausable)

// Impact: Token is bricked from admin perspective
// Funds are safe (transfers still work) but no governance
```

#### Block 4: Initial Supply Minting (lines 96-98)
```solidity
if (initialSupply_ > 0 && initialHolder_ != address(0)) {
    _mint(initialHolder_, initialSupply_);
}
```

**What happens:**
- Double condition check: both supply > 0 AND holder != address(0)
- If both true, mint initial supply to holder
- If either false, skip minting (totalSupply remains 0)

**First Principles:**
- **Why double condition?** → Prevent minting to address(0) (burns tokens) and prevent zero mints (waste gas)
- **Why allow skipping?** → Some tokens start with 0 supply (mint later)
- **Why not validate earlier?** → Constructor optimizes for common case (supply > 0)

**_mint() Execution (OpenZeppelin ERC20):**
```solidity
function _mint(address account, uint256 value) internal {
    if (account == address(0)) {
        revert ERC20InvalidReceiver(address(0));
    }
    _update(address(0), account, value);  // Calls our overridden _update()!
}

// Which calls:
_update(address(0), initialHolder_, initialSupply_)
  └─> Line 173-181: Compliance hook check
      if (complianceHook != address(0)):
          if (from == address(0)):  // TRUE for minting
              complianceHook.onMint(msg.sender, to, 0, value)
      super._update(from, to, value)
```

**Reentrancy Risk During Construction:**
```solidity
// Call flow during constructor:
constructor()
  └─> _mint(initialHolder_, initialSupply_)
      └─> _update(address(0), initialHolder_, supply)
          └─> complianceHook.onMint(...)  // ⚠️ EXTERNAL CALL IN CONSTRUCTOR!
              └─> [Malicious hook could call back]

// What can malicious hook do?
// - Token is not fully constructed yet
// - Factory hasn't registered token yet (if called via factory)
// - Hook could try to manipulate token state
// - Hook could try to reenter constructor (impossible - constructor runs once)
// - Hook could call token functions (most will work since roles are set)

// Attack scenario:
contract MaliciousHook {
    function onMint(address, address to, uint256, uint256) external {
        // Token is DewizERC20(msg.sender)
        DewizERC20(msg.sender).setComplianceHook(attacker);  // Change hook!
        // This WILL work because DEFAULT_ADMIN_ROLE was granted at line 86
        // Attacker is now admin!
    }
}
```

**Critical Finding - Constructor Reentrancy:**
- ❌ **CRITICAL**: External call to compliance hook during constructor
- ❌ **CRITICAL**: Hook is called AFTER admin roles are granted (line 86 → line 97)
- ❌ **CRITICAL**: Hook can call back and execute admin functions (setComplianceHook, grantRole, etc.)
- ⚠️ **HIGH**: Token state is fully functional during hook callback (all roles set, all immutables set)

**Recommendation - Constructor Reentrancy Fix:**
```solidity
// Option 1: Set compliance hook AFTER initial mint
constructor(...) ERC20(name_, symbol_) {
    _decimals = decimals_;
    mintable = isMintable_;
    burnable = isBurnable_;
    pausable = isPausable_;
    factory = msg.sender;
    // complianceHook = address(0);  // Don't set yet

    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    if (isMintable_) { _grantRole(MINTER_ROLE, admin_); }
    if (isPausable_) { _grantRole(PAUSER_ROLE, admin_); }

    if (initialSupply_ > 0 && initialHolder_ != address(0)) {
        _mint(initialHolder_, initialSupply_);  // No hook call
    }

    complianceHook = IComplianceHook(complianceHook_);  // Set AFTER mint
}

// Option 2: Skip compliance check during construction
uint256 private _constructing = 1;

function _update(...) internal virtual override {
    if (_constructing == 0 && address(complianceHook) != address(0)) {
        // ... compliance checks
    }
    super._update(from, to, value);
}

constructor(...) {
    // ... setup
    if (initialSupply_ > 0 && initialHolder_ != address(0)) {
        _mint(initialHolder_, initialSupply_);
    }
    _constructing = 0;  // Enable compliance checks
}
```

### Function 3 Complete: Cross-Function Dependencies

**Called By:**
- `ERC20Factory.createToken(params)` - Via `new` keyword
- `ERC721Factory.createToken(params)` - Different token type
- `ERC1155Factory.createToken(params)` - Different token type

**Calls:**
- `ERC20(name_, symbol_)` - Parent constructor
- `_grantRole(role, account)` - OpenZeppelin AccessControl
- `_mint(initialHolder_, initialSupply_)` - OpenZeppelin ERC20
  - Which calls `_update(address(0), holder, supply)`
    - Which calls `complianceHook.onMint(...)` - **EXTERNAL CALL**

**Related Functions:**
- `setComplianceHook(address)` - Can change hook after deployment
- `mint(to, amount)` - Admin can mint more tokens (if mintable=true)
- `_update(from, to, value)` - Called for ALL transfers/mints/burns

### Function 3 Summary Risk Assessment

**Critical Risks:**
1. ❌ **No admin_ validation** - address(0) makes token unmanageable
2. ❌ **Constructor reentrancy** - Compliance hook called during construction
3. ❌ **No complianceHook_ validation** - EOA or malicious contract accepted

**High Risks:**
4. ⚠️ **No name/symbol validation** - Empty strings accepted
5. ⚠️ **No decimals validation** - 0 or 255 accepted

**Medium Risks:**
6. ⚠️ **Feature flag permanence** - Immutable flags can't be changed if mistake

**Recommendations Priority:**
1. **CRITICAL**: Add `require(admin_ != address(0))` validation
2. **CRITICAL**: Fix constructor reentrancy (set hook after mint OR skip compliance during construction)
3. **HIGH**: Add `require(complianceHook_.code.length > 0 || complianceHook_ == address(0))` validation
4. **MEDIUM**: Add name/symbol non-empty validation
5. **LOW**: Document decimal choices and risks

---

## Function 4: DewizERC20._update() - THE CRITICAL FUNCTION

**Location:** `src/tokens/DewizERC20.sol:172-183`

```solidity
function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Pausable) {
    if (address(complianceHook) != address(0)) {
        if (from == address(0)) {
            complianceHook.onMint(msg.sender, to, 0, value);
        } else if (to == address(0)) {
            complianceHook.onBurn(msg.sender, from, 0, value);
        } else {
            complianceHook.onTransfer(msg.sender, from, to, 0, value);
        }
    }
    super._update(from, to, value);
}
```

### Purpose

**What it does:**
Intercepts EVERY token transfer (including mints and burns) to call compliance hook for validation BEFORE executing the transfer.

**Why it exists:**
This is the **SINGLE MOST CRITICAL FUNCTION** in the entire codebase. It's the enforcement point for ALL regulatory compliance requirements. Every mint, burn, and transfer MUST go through this function.

### Inputs

| Parameter | Type | Description | Source |
|-----------|------|-------------|--------|
| `from` | `address` | Source address (address(0) for mints) | Caller |
| `to` | `address` | Destination address (address(0) for burns) | Caller |
| `value` | `uint256` | Amount of tokens | Caller |

**Context Variables:**
- `msg.sender` - The operator (who initiated the transfer)
- `complianceHook` - The registered compliance contract

### Outputs

**State Changes:**
- Token balances updated (via `super._update()`)
- Total supply changes (mints/burns)

**External Calls:**
- `complianceHook.onMint()` - If minting
- `complianceHook.onTransfer()` - If transferring
- `complianceHook.onBurn()` - If burning

**Return Value:** None (internal function)

**Can Revert:** Yes (if compliance hook reverts)

### Line-by-Line Analysis

#### Block 1: Function Signature & Override (line 172)
```solidity
function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Pausable) {
```

**What happens:**
- Declares override of BOTH ERC20 and ERC20Pausable _update() functions
- Internal visibility (only callable within contract and children)
- Virtual (can be overridden by children)

**Diamond Inheritance Resolution:**
```
DewizERC20
    ├─> ERC20 (has _update)
    └─> ERC20Pausable
            └─> ERC20 (has _update)

// Solidity C3 linearization:
DewizERC20 → ERC20Pausable → ERC20

// override(ERC20, ERC20Pausable) means:
// "I'm overriding _update from both ERC20 and ERC20Pausable"
// super._update() will call ERC20Pausable._update()
//   which calls ERC20._update()
```

**First Principles:**
- **Why override both?** → Both parent contracts have _update(), must specify which
- **Why internal?** → Hook function, not meant for external calls
- **Why virtual?** → Allow future inheritance (though unlikely)

#### Block 2: Compliance Hook Check (line 173)
```solidity
if (address(complianceHook) != address(0)) {
```

**What happens:**
- Type-cast interface to address for comparison
- Check if hook is set (non-zero address)
- Skip compliance checks if no hook (optimization)

**First Principles:**
- **Why check address(0)?** → Hook is optional, address(0) means "no compliance needed"
- **Why type-cast?** → complianceHook is IComplianceHook type, need address for comparison
- **Why not just `if (complianceHook)`?** → Solidity doesn't allow implicit bool conversion of interfaces

**Gas Optimization:**
```
Gas costs:
- address(complianceHook): Type-cast (compile-time, 0 gas)
- != address(0): EQ + ISZERO opcodes (~6 gas)
- Branch prediction: If false, skip entire block (~100 gas saved)

If hook is address(0):
- Total gas for compliance check: ~6 gas (just the comparison)

If hook is set:
- Comparison: ~6 gas
- External call: ~2,100 gas (cold) + hook execution gas
- Total: ~2,100+ gas

Design tradeoff: Small overhead when no hook, large overhead when hook active
```

#### Block 3: Operation Type Detection (lines 174-180)
```solidity
if (from == address(0)) {
    complianceHook.onMint(msg.sender, to, 0, value);
} else if (to == address(0)) {
    complianceHook.onBurn(msg.sender, from, 0, value);
} else {
    complianceHook.onTransfer(msg.sender, from, to, 0, value);
}
```

**What happens:**
- Detects operation type based on from/to addresses
- Minting: from == address(0) (tokens created from nowhere)
- Burning: to == address(0) (tokens sent to nowhere)
- Transfer: both addresses non-zero (tokens moved)

**First Principles - Why detect operation type?**
1. **Why not use same function for all?** → Different operations have different compliance requirements
2. **Why pass different parameters?** → Mint doesn't have "from", burn doesn't have "to"
3. **Why not auto-detect in hook?** → Explicit is better than implicit (hook knows what to validate)
4. **Why pass msg.sender as operator?** → Hook needs to know WHO initiated operation (not just from/to)
5. **Why pass 0 as id?** → ERC20 has no token IDs (interface compatibility with ERC721/1155)

**Parameter Analysis:**
```solidity
// Mint: complianceHook.onMint(msg.sender, to, 0, value)
// - operator: msg.sender (who called mint())
// - to: recipient address
// - id: 0 (no token IDs in ERC20)
// - amount: value (how many tokens)

// Burn: complianceHook.onBurn(msg.sender, from, 0, value)
// - operator: msg.sender (who called burn())
// - from: token holder being burned from
// - id: 0
// - amount: value

// Transfer: complianceHook.onTransfer(msg.sender, from, to, 0, value)
// - operator: msg.sender (who called transfer() or transferFrom())
// - from: sender address
// - to: recipient address
// - id: 0
// - amount: value
```

**5 Whys - Why external call BEFORE state changes?**
1. **Why before, not after?** → Compliance must PREVENT invalid operations, not just log them
2. **Why not after?** → Too late - tokens already transferred, can't undo without another transfer
3. **Why allow hook to revert?** → Revert is the ONLY way to block invalid operations
4. **Why not return bool?** → Revert is clearer intent, saves gas (no return value handling)
5. **Why trust hook?** → Hook is set by admin who owns the token (trust assumption)

**Checks-Effects-Interactions Violation:**
```
Traditional CEI:
1. Checks   ✓ (pausable check in super._update)
2. Effects  ❌ SHOULD BE HERE (balance updates)
3. Interaction ✓ complianceHook.onMint/Transfer/Burn()
4. Effects  ✓ (actually here: super._update() updates balances)

Why this violates CEI:
- External call (compliance hook) happens BEFORE state changes
- Hook could reenter token contract
- Hook sees OLD balances (before transfer)

Why this is INTENTIONAL:
- Compliance MUST validate BEFORE transfer
- If validation after, too late to stop
- Hook seeing old balances is correct (validating proposed change)

Why this is RISKY:
- Reentrancy vulnerability if hook is malicious
- Hook could call transfer() again (nested transfers)
- Hook could drain token or manipulate state
```

#### Block 4: Reentrancy Analysis - THE CRITICAL VULNERABILITY

**Reentrancy Attack Scenario 1: Drain via onTransfer:**
```solidity
contract MaliciousHook is IComplianceHook {
    bool attacking = false;

    function onTransfer(address operator, address from, address to, uint256, uint256 amount) external {
        if (!attacking && from == victim) {
            attacking = true;
            // Reenter token contract
            // At this point: victim's balance is UNCHANGED (old state)
            DewizERC20(msg.sender).transferFrom(victim, attacker, amount * 10);
            // This calls _update() again!
            // Inner call sees same old balance, allows over-withdrawal
            attacking = false;
        }
    }

    // Implement other interface functions...
}

// Attack execution:
// 1. Victim has 1000 tokens
// 2. Victim calls: token.transfer(recipient, 100)
// 3. _update(victim, recipient, 100) called
// 4. complianceHook.onTransfer() called
// 5. Hook reenters: token.transferFrom(victim, attacker, 1000)
// 6. Inner _update(victim, attacker, 1000) called
// 7. Inner call sees balance = 1000 (state not yet updated!)
// 8. Inner call succeeds, transfers 1000 to attacker
// 9. Outer call resumes, transfers 100 to recipient
// 10. Total transferred: 1100 tokens from balance of 1000!
// 11. Underflow in balance (reverts in Solidity 0.8+)

// Verdict: Attack FAILS due to Solidity 0.8 underflow protection!
// But still demonstrates reentrancy vulnerability exists
```

**Reentrancy Attack Scenario 2: State manipulation:**
```solidity
contract MaliciousHook is IComplianceHook {
    function onMint(address operator, address to, uint256, uint256 amount) external {
        // Called during _update(address(0), to, amount)
        // State: balances not yet updated

        // Attack 1: Change compliance hook to attacker's hook
        DewizERC20(msg.sender).setComplianceHook(attackerHook);
        // Now all future operations use attacker's hook!

        // Attack 2: Grant attacker MINTER_ROLE
        DewizERC20 token = DewizERC20(msg.sender);
        bytes32 adminRole = token.DEFAULT_ADMIN_ROLE();
        token.grantRole(token.MINTER_ROLE(), attacker);
        // Attacker can now mint unlimited tokens!

        // Attack 3: Pause token (if pausable)
        if (token.pausable()) {
            token.pause();
        }
        // DoS attack: all transfers frozen!
    }

    // Implement other interface functions...
}

// Impact: Complete token takeover
// - Attacker controls compliance (can censor users)
// - Attacker can mint unlimited tokens (inflation attack)
// - Attacker can pause token (DoS)
```

**Critical Finding - Reentrancy Vulnerabilities:**
- ❌ **CRITICAL**: No reentrancy guard on _update()
- ❌ **CRITICAL**: Hook can call setComplianceHook() and take over token
- ❌ **CRITICAL**: Hook can call grantRole() and give itself privileges
- ❌ **CRITICAL**: Hook can call pause() and DoS token
- ✅ **MITIGATED**: Balance manipulation prevented by Solidity 0.8 underflow checks
- ⚠️ **HIGH**: Admin functions callable during compliance hook execution

**Why Reentrancy Guard Wasn't Added:**
```
Possible reasons:
1. Gas optimization - OpenZeppelin's ReentrancyGuard costs ~23,000 gas per protected function
2. Assumption: "Admin-set hooks are trusted"
3. Oversight: Developers didn't consider admin-callable functions during hook
4. Design choice: Flexibility over security

Counter-arguments:
1. Gas cost is acceptable for security (23k gas << cost of exploit)
2. Trust assumption breaks if admin key compromised or malicious hook deployed
3. Defense in depth: Even trusted components should have guards
4. Admin might not realize hook they're setting is malicious (supply chain attack)
```

#### Block 5: State Update (line 182)
```solidity
super._update(from, to, value);
```

**What happens:**
- Calls parent implementation (ERC20Pausable._update)
- Which calls ERC20._update (actual balance changes)
- Updates from.balance, to.balance, totalSupply

**super Resolution:**
```
super._update() resolves to:
DewizERC20._update (current)
  └─> super = ERC20Pausable._update
      └─> Checks if paused (reverts if paused)
      └─> super = ERC20._update
          └─> Actual balance updates
          └─> Emit Transfer event
```

**ERC20Pausable._update() Code:**
```solidity
function _update(address from, address to, uint256 value) internal virtual override {
    if (paused()) {
        revert EnforcedPause();
    }
    super._update(from, to, value);
}
```

**ERC20._update() Code (simplified):**
```solidity
function _update(address from, address to, uint256 value) internal virtual {
    if (from == address(0)) {
        _totalSupply += value;  // Minting
    } else {
        uint256 fromBalance = _balances[from];
        if (fromBalance < value) {
            revert ERC20InsufficientBalance(from, fromBalance, value);
        }
        unchecked {
            _balances[from] = fromBalance - value;  // Safe: checked above
        }
    }

    if (to == address(0)) {
        unchecked {
            _totalSupply -= value;  // Burning (safe: totalSupply >= value by invariant)
        }
    } else {
        unchecked {
            _balances[to] += value;  // Safe: totalSupply tracks all tokens
        }
    }

    emit Transfer(from, to, value);
}
```

**5 Hows - How do balance updates work?**
1. **How is insufficient balance detected?** → `if (fromBalance < value)` check at line 5-7
2. **How are underflows prevented?** → Explicit check + unchecked block for safe math
3. **How are overflows prevented?** → Solidity 0.8 checked arithmetic (totalSupply tracks all tokens)
4. **How is totalSupply maintained?** → Incremented on mint, decremented on burn
5. **How are events emitted?** → After all balance updates, Transfer(from, to, value)

**Gas Analysis - super._update():**
```
Gas costs:
- SLOAD _balances[from]: 2,100 gas (cold) or 100 gas (warm)
- Balance check: ~10 gas
- SSTORE _balances[from]: 5,000 gas (update)
- SSTORE _balances[to]: 22,100 gas (new) or 5,000 gas (update)
- Emit Transfer: ~1,500 gas
- Total: ~30,000-35,000 gas for typical transfer

With compliance hook:
- Hook call overhead: ~2,100 gas
- Hook execution: varies (10,000-100,000+ gas depending on logic)
- Total with hook: ~42,000-135,000+ gas

Impact: Compliance hooks add 40-300% gas overhead to transfers
```

### Function 4 Complete: Cross-Function Dependencies

**Called By (EVERY token operation):**
- `transfer(to, value)` - User-initiated transfer
- `transferFrom(from, to, value)` - Delegated transfer
- `mint(to, amount)` - Admin minting (if mintable)
- `burn(amount)` - User burning own tokens
- `burnFrom(account, amount)` - Burning with allowance
- Constructor - Initial supply minting

**Calls:**
- `complianceHook.onMint()` - External call (if minting)
- `complianceHook.onTransfer()` - External call (if transferring)
- `complianceHook.onBurn()` - External call (if burning)
- `super._update()` - Parent implementation (ERC20Pausable → ERC20)

**Related Functions:**
- `setComplianceHook(address)` - Can change hook (callable during reentrancy!)
- `approve(spender, value)` - Also calls compliance hook (separate function)

### Function 4 Summary Risk Assessment

**Critical Risks:**
1. ❌ **Reentrancy vulnerability** - Hook can call back and execute admin functions
2. ❌ **Hook takeover** - Malicious hook can call setComplianceHook() and replace itself
3. ❌ **Privilege escalation** - Hook can grant itself roles via grantRole()
4. ❌ **DoS attack** - Hook can pause token or revert indefinitely

**High Risks:**
5. ⚠️ **Gas griefing** - Malicious hook can consume excessive gas
6. ⚠️ **Censorship** - Hook can selectively block users
7. ⚠️ **Front-running** - Hook can observe transfers and front-run them

**Medium Risks:**
8. ⚠️ **CEI violation** - External call before state changes (intentional but risky)

**Recommendations Priority:**
1. **CRITICAL**: Add ReentrancyGuard to _update() function
2. **CRITICAL**: Add ReentrancyGuard to setComplianceHook()
3. **CRITICAL**: Add ReentrancyGuard to grantRole() and other admin functions
4. **HIGH**: Consider gas limit on compliance hook calls
5. **MEDIUM**: Add circuit breaker for emergency hook removal
6. **LOW**: Document reentrancy risks in NatSpec

**Recommended Fix:**
```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DewizERC20 is ERC20, ERC20Burnable, ERC20Pausable, AccessControl, ReentrancyGuard {
    // ... existing code

    function _update(address from, address to, uint256 value)
        internal
        virtual
        override(ERC20, ERC20Pausable)
        nonReentrant  // ADD THIS
    {
        if (address(complianceHook) != address(0)) {
            if (from == address(0)) {
                complianceHook.onMint(msg.sender, to, 0, value);
            } else if (to == address(0)) {
                complianceHook.onBurn(msg.sender, from, 0, value);
            } else {
                complianceHook.onTransfer(msg.sender, from, to, 0, value);
            }
        }
        super._update(from, to, value);
    }

    function setComplianceHook(address newHook)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant  // ADD THIS
    {
        emit ComplianceHookUpdated(address(complianceHook), newHook);
        complianceHook = IComplianceHook(newHook);
    }
}
```

---

## Phase 2 Analysis Summary - Functions Analyzed

### Completed Analyses:

1. ✅ **TokenFactoryRegistry.registerERC20Factory()** - Factory registration with 7 findings
2. ✅ **ERC20Factory.createToken()** - Token creation with 6 findings
3. ✅ **DewizERC20 Constructor** - Initialization with 6 critical findings including constructor reentrancy
4. ✅ **DewizERC20._update()** - THE CRITICAL FUNCTION with 8 critical reentrancy vulnerabilities

### Total Findings: 27 Security Issues

**Critical (Must Fix):**
- No contract code validation in factory registration
- No interface validation for factories
- No input validation in token creation
- No admin validation in constructor (address(0) accepted)
- Constructor reentrancy via compliance hook
- _update() reentrancy - hook can take over token
- Hook can escalate privileges via grantRole()
- Hook can DoS via pause()

**High (Should Fix):**
- Silent factory overwrites
- Centralized registry owner
- Empty name/symbol accepted
- No compliance hook code validation

**Medium (Consider Fixing):**
- CEI violations in multiple locations
- Unbounded gas costs
- Front-running risks
- Token squatting

**Next Functions to Analyze:**
5. DewizERC20.approve() - Approval with compliance check
6. DewizERC1155._update() - Batch operations with external calls in loops
7. ERC1155Factory._registerToken() - Token tracking
8. TemplateComplianceHook functions - Reference implementation

---

**Document Status:** Phase 2 In Progress - 4/30+ functions analyzed
**Lines Analyzed:** ~500 lines of ultra-granular analysis
**Next Update:** Continue with remaining high-impact functions
