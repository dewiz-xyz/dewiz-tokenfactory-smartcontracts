# Dewiz Token Factory

## Overview

Dewiz's mission is to help “de-wizardrying” DeFi, making it more accessible to the more Financial Institutions and People. Dewiz Token Factory provides the leading tokenization platform in the Web3 ecosystem, empowering financial institutions to create stablecoins for payments, international remittances, credit facilities, and international trade. Additionally, the platform enables tokenization of Real World Assets (RWA), government bonds, corporate debentures, and implements solvers for currency and token swaps. This project serves as the abstract token factory for all tokenization initiatives aimed at Dewiz clients.

The Dewiz Token Factory creates tokens compliant with industry-standard Ethereum token specifications including ERC-20, ERC-721, and ERC-1155. Beyond basic token standards, Dewiz incorporates regulatory compliance rules directly into smart contracts to ensure adherence to requirements from major regulatory agencies worldwide, including OFAC, SEC, European Central Bank (ECB), and others.

In a market where smart contract hacks are common, our MOAT is the reduction of legal and technical risk for enterprise clients based on our years of experience in Corporate, and MakerDAO/Sky ecosystem.

## Tech Architecture

### Stack Overview

**Smart Contract Framework:**
- **Solidity**: Primary smart contract language (^0.8.24)
- **Foundry/Forge**: Modern development framework for building, testing, and deploying smart contracts
- **OpenZeppelin Contracts v5.5**: Industry-standard secure contract implementations
- **forge-std**: Standard library providing testing utilities and helper functions

**Development Environment:**
- **Forge**: Fast, portable, and modular toolkit for Ethereum application development
- **Cast**: Swiss army knife for interacting with EVM smart contracts
- **Anvil**: Local Ethereum node for development and testing
- **Via IR**: Intermediate representation compilation enabled for complex contracts

### Architecture Patterns

**Abstract Factory Pattern Implementation:**

The project implements the Abstract Factory design pattern, providing a unified interface for creating families of related token contracts:

```
┌─────────────────────────────────────────────────────────────┐
│                   TokenFactoryRegistry                       │
│           (Abstract Factory Coordinator/Client)              │
│  ┌─────────────┬──────────────┬──────────────┐              │
│  │ ERC20Factory│ ERC721Factory│ERC1155Factory│              │
│  └─────────────┴──────────────┴──────────────┘              │
└─────────────────────────────────────────────────────────────┘
         │                │                │
         ▼                ▼                ▼
┌─────────────┐  ┌──────────────┐  ┌───────────────┐
│ DewizERC20  │  │ DewizERC721  │  │ DewizERC1155  │
│  (Product)  │  │  (Product)   │  │  (Product)    │
└─────────────┘  └──────────────┘  └───────────────┘
```

**Key Benefits:**
- **Abstraction**: Clients interact with tokens through standardized interfaces (ITokenFactory, IERC20Factory, etc.)
- **Extensibility**: New token types can be added without modifying existing code
- **Centralized Management**: Token creation logic is consolidated in factory contracts
- **Token Tracking**: All created tokens are tracked per factory and per creator address
- **Cost Efficiency**: Shared implementation logic reduces deployment costs

**Access Control Pattern:**
Role-based permissions using OpenZeppelin's AccessControl:
- `DEFAULT_ADMIN_ROLE`: Full administrative access
- `MINTER_ROLE`: Permission to mint new tokens
- `PAUSER_ROLE`: Permission to pause/unpause transfers
- `URI_SETTER_ROLE`: Permission to update metadata URIs (ERC-1155)

**Compliance Layer Architecture:**
- **Modular Compliance Rules**: Pluggable compliance modules for different jurisdictions
- **Whitelist/Blacklist Management**: Address-based restrictions for OFAC and other sanctions
- **Transfer Restrictions**: Configurable rules for KYC/AML compliance
- **Regulatory Hooks**: Pre and post-transfer validation hooks for custom compliance logic
- **Pausable Functionality**: Emergency pause mechanism for incident response

### Token Standards Support

**DewizERC20 (Fungible Tokens):**
- Stablecoins for payments and remittances
- Utility tokens for platform economics
- Tokenized securities and debentures
- **Features**: Configurable decimals, optional minting, burning, and pausability

**DewizERC721 (Non-Fungible Tokens):**
- Unique asset tokenization (real estate, art, collectibles)
- Digital certificates and credentials
- Fractional ownership representations
- **Features**: ERC-2981 royalty support, URI storage per token, auto-incrementing token IDs

**DewizERC1155 (Multi-Token Standard):**
- Batch operations for efficiency
- Mixed fungible and non-fungible token management
- Reduced gas costs for multi-asset platforms
- **Features**: Supply tracking, per-token URIs, ERC-2981 royalties, token type creation

### Security Considerations

**Best Practices Implemented:**
- **Access Control**: OpenZeppelin's role-based access control patterns
- **Reentrancy Protection**: Guards against reentrancy attacks
- **Integer Overflow Protection**: Built-in Solidity 0.8+ overflow checks
- **Pausable Functionality**: Emergency pause mechanism for incident response
- **Auditable Code**: Clean, well-documented code following Solidity style guide

**Testing Strategy:**
- **Unit Tests**: Comprehensive coverage of individual contract functions
- **Fuzz Testing**: Property-based testing for edge cases and unexpected inputs
- **Integration Tests**: End-to-end testing of token lifecycle and interactions
- **Gas Optimization Tests**: Ensuring efficient contract execution

### Deployment Architecture

**Multi-Chain Support:**
- Ethereum Mainnet (Layer 1)
- Polygon, Arbitrum, Optimism (Layer 2 scaling solutions)
- BNB Chain, Avalanche (Alternative L1s)
- Private/Permissioned networks for enterprise clients

**Deployment Workflow:**
1. **Development**: Local testing with Anvil
2. **Staging**: Testnet deployment (Sepolia, Mumbai, etc.)
3. **Audit**: Third-party security audits
4. **Production**: Mainnet deployment with monitoring
5. **Maintenance**: Continuous monitoring and potential upgrades

### Compliance Integration

**Regulatory Compliance Modules:**
- **OFAC Sanctions Screening**: Real-time address validation against sanctions lists
- **KYC/AML Integration**: Identity verification hooks for regulated tokens
- **Transfer Restrictions**: Time-locks, amount limits, and accredited investor checks
- **Reporting Features**: On-chain audit trails for regulatory reporting

**Jurisdiction-Specific Rules:**
- **US Securities**: SEC compliance for security tokens
- **European Markets**: MiCA (Markets in Crypto-Assets) regulation support
- **Asian Markets**: Region-specific compliance frameworks

### Integration Points

**Off-Chain Components:**
- **Oracle Integration**: Chainlink or custom oracles for price feeds and data
- **Identity Verification**: Integration with KYC/AML providers
- **Monitoring Services**: Block explorers and transaction monitoring
- **Backend APIs**: RESTful APIs for token management and reporting

**Frontend Interaction:**
- **Web3 Libraries**: ethers.js, web3.js, or viem for dApp integration
- **Wallet Support**: MetaMask, WalletConnect, Ledger hardware wallets
- **User Dashboard**: Token management interface for administrators and users

## Project Structure

```
├── src/
│   ├── TokenFactoryRegistry.sol    # Central registry and factory coordinator
│   ├── interfaces/
│   │   ├── ITokenFactory.sol       # Base factory interface
│   │   ├── IERC20Factory.sol       # ERC-20 factory interface
│   │   ├── IERC721Factory.sol      # ERC-721 factory interface
│   │   └── IERC1155Factory.sol     # ERC-1155 factory interface
│   ├── factories/
│   │   ├── ERC20Factory.sol        # Concrete ERC-20 factory
│   │   ├── ERC721Factory.sol       # Concrete ERC-721 factory
│   │   └── ERC1155Factory.sol      # Concrete ERC-1155 factory
│   └── tokens/
│       ├── DewizERC20.sol          # Feature-rich ERC-20 implementation
│       ├── DewizERC721.sol         # Feature-rich ERC-721 implementation
│       └── DewizERC1155.sol        # Feature-rich ERC-1155 implementation
├── test/                            # Test files using Forge testing framework
├── script/
│   └── DeployTokenFactory.s.sol    # Deployment scripts
├── lib/
│   ├── forge-std/                  # Foundry standard library
│   └── openzeppelin-contracts/     # OpenZeppelin v5.5
├── foundry.toml                    # Foundry configuration
└── remappings.txt                  # Import remapping for dependencies
```

### Contract Descriptions

| Contract | Description |
|----------|-------------|
| `TokenFactoryRegistry` | Central entry point coordinating all factories. Provides unified interface for token creation. |
| `ERC20Factory` | Creates DewizERC20 tokens with configurable features (mint/burn/pause). |
| `ERC721Factory` | Creates DewizERC721 NFTs with royalties and metadata support. |
| `ERC1155Factory` | Creates DewizERC1155 multi-tokens with supply tracking. |
| `DewizERC20` | Full-featured ERC-20 with AccessControl, optional minting, burning, and pausability. |
| `DewizERC721` | ERC-721 with royalties (ERC-2981), URI storage, and role-based access. |
| `DewizERC1155` | Multi-token with supply tracking, royalties, and batch operations. |

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Git for version control
- Node.js (optional, for additional tooling)

### Installation

```bash
# Clone the repository
git clone https://github.com/dewiz-xyz/dewiz-tokenfactory-smartcontracts.git
cd dewiz-tokenfactory-smartcontracts

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Run tests with verbosity
forge test -vvv
```

### Development Workflow

```bash
# Create a new contract
# Add your contract to src/

# Write tests
# Add tests to test/

# Run specific test
forge test --match-test testFunctionName

# Check coverage
forge coverage

# Format code
forge fmt

# Generate gas snapshots
forge snapshot
```

## Deployment

```bash
# Deploy to local Anvil network
anvil # In separate terminal
forge script script/DeployTokenFactory.s.sol:DeployTokenFactoryLocal --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet/mainnet (requires PRIVATE_KEY env variable)
export PRIVATE_KEY=<your-private-key>
forge script script/DeployTokenFactory.s.sol:DeployTokenFactory --rpc-url $RPC_URL --broadcast --verify

# Verify contract on Etherscan
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --chain <CHAIN_ID>
```

### Deployment Order

The deployment script automatically:
1. Deploys `TokenFactoryRegistry` (central coordinator)
2. Deploys `ERC20Factory`, `ERC721Factory`, `ERC1155Factory`
3. Registers all factories with the registry

### Creating Tokens

After deployment, create tokens via the registry:

```solidity
// Create a simple ERC-20 token
address token = registry.createSimpleERC20Token(
    "My Token",
    "MTK",
    1000000 * 10**18  // Initial supply
);

// Create an ERC-721 NFT collection
address nft = registry.createSimpleERC721Token(
    "My NFT",
    "MNFT",
    "https://api.example.com/metadata/"
);

// Create an ERC-1155 multi-token
address multiToken = registry.createSimpleERC1155Token(
    "My Collection",
    "MCOL",
    "https://api.example.com/token/{id}.json"
);
```

## Testing Strategy

- **Unit Tests**: Test individual contract functions in isolation
- **Integration Tests**: Test contract interactions and workflows
- **Fuzz Tests**: Automated testing with randomized inputs
- **Invariant Tests**: Ensure contract invariants hold under all conditions
- **Gas Benchmarking**: Track and optimize gas consumption

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Security

This is production-grade financial infrastructure. Security is paramount:
- All code should be thoroughly tested
- Critical changes require security audits
- Follow the principle of least privilege
- Implement comprehensive access controls
- Enable contract pause functionality for emergencies

## License

See [LICENSE](LICENSE) file for details.

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Ethereum EIPs](https://eips.ethereum.org/)

## Contact

For questions, issues, or collaboration opportunities, please reach out to the Dewiz team.