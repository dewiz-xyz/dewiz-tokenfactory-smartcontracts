# Dewiz Token Factory

## Overview

This project serves as the abstract token factory for all tokenization initiatives aimed at Dewiz clients. Dewiz provides the leading tokenization platform in the Web3 ecosystem, empowering financial institutions to create stablecoins for payments, international remittances, credit facilities, and international trade. Additionally, the platform enables tokenization of Real World Assets (RWA), government bonds, corporate debentures, and implements solvers for currency and token swaps.

The Dewiz Token Factory creates tokens compliant with industry-standard Ethereum token specifications including ERC-20, ERC-721, and ERC-1155. Beyond basic token standards, Dewiz incorporates regulatory compliance rules directly into smart contracts to ensure adherence to requirements from major regulatory agencies worldwide, including OFAC, SEC, European Central Bank (ECB), and others.

## Tech Architecture

### Stack Overview

**Smart Contract Framework:**
- **Solidity**: Primary smart contract language (^0.8.13+)
- **Foundry/Forge**: Modern development framework for building, testing, and deploying smart contracts
- **forge-std**: Standard library providing testing utilities and helper functions

**Development Environment:**
- **Forge**: Fast, portable, and modular toolkit for Ethereum application development
- **Cast**: Swiss army knife for interacting with EVM smart contracts
- **Anvil**: Local Ethereum node for development and testing

### Architecture Patterns

**Factory Pattern Implementation:**
The project utilizes the Factory design pattern, a creational pattern that provides an interface for creating token contracts without specifying their concrete classes. This approach offers:
- **Abstraction**: Clients interact with tokens through standardized interfaces (ERC-20, ERC-721, ERC-1155)
- **Extensibility**: New token types can be added without modifying existing code
- **Centralized Management**: Token creation logic is consolidated in factory contracts
- **Cost Efficiency**: Shared implementation logic reduces deployment costs

**Proxy Pattern (Upgradeable Contracts):**
To support regulatory updates and feature enhancements post-deployment:
- **Transparent Proxy Pattern**: Separates logic and storage, enabling contract upgrades
- **Access Control**: Role-based permissions for administrative functions
- **State Preservation**: Contract upgrades maintain token holder balances and state

**Compliance Layer Architecture:**
- **Modular Compliance Rules**: Pluggable compliance modules for different jurisdictions
- **Whitelist/Blacklist Management**: Address-based restrictions for OFAC and other sanctions
- **Transfer Restrictions**: Configurable rules for KYC/AML compliance
- **Regulatory Hooks**: Pre and post-transfer validation hooks for custom compliance logic

### Token Standards Support

**ERC-20 (Fungible Tokens):**
- Stablecoins for payments and remittances
- Utility tokens for platform economics
- Tokenized securities and debentures

**ERC-721 (Non-Fungible Tokens):**
- Unique asset tokenization (real estate, art, collectibles)
- Digital certificates and credentials
- Fractional ownership representations

**ERC-1155 (Multi-Token Standard):**
- Batch operations for efficiency
- Mixed fungible and non-fungible token management
- Reduced gas costs for multi-asset platforms

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
├── src/                    # Smart contract source files
├── test/                   # Test files using Forge testing framework
├── script/                 # Deployment and interaction scripts
├── lib/                    # External dependencies (forge-std)
├── foundry.toml           # Foundry configuration
└── remappings.txt         # Import remapping for dependencies
```

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
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify

# Verify contract on Etherscan
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --chain <CHAIN_ID>
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