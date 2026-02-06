# Dewiz Token Factory - Technical Requirements

A smart contract platform for creating compliant ERC-20, ERC-721, and ERC-1155 tokens with built-in regulatory hooks for institutional tokenization use cases, accessible via a secure REST API for Web2 integration.

## Context

Dewiz Token Factory addresses the critical need for institutional-grade tokenization infrastructure. Financial institutions entering the blockchain space require:

- **Regulatory Compliance**: Built-in mechanisms for OFAC sanctions screening, KYC/AML enforcement, and jurisdiction-specific rules
- **Standardized Token Creation**: Consistent, auditable token deployment across multiple standards
- **Enterprise-Grade Security**: Role-based access control, pausability, and audit trails
- **Multi-Asset Support**: Stablecoins (ERC-20), unique assets like real estate (ERC-721), and batch-efficient securities (ERC-1155)

The platform reduces legal and technical risk by embedding compliance directly into smart contract logic rather than relying on off-chain enforcement.

## Stakeholders

- **Decision Maker**: Mr. Sandbox
- **Input Givers**: Amusing, Ephy, Centurion, Tlay, Oddaf
- **Technical Reviewers**: Oddaf, Riccardo, Amusing, and external Security Auditors
- **End Users**: Financial Institutions, Asset Managers, Token Issuers

## Business Requirements

### Core Requirements

1. **Multi-Standard Token Support**
   - ERC-20: Fungible tokens for stablecoins, utility tokens, and tokenized securities
   - ERC-721: Non-fungible tokens for unique assets (real estate, art, credentials)
   - ERC-1155: Multi-tokens for batch operations and mixed fungible/non-fungible assets

2. **Regulatory Compliance Framework**
   - Pluggable compliance hooks for OFAC sanctions screening
   - KYC/AML integration points via transfer validation
   - Transfer restrictions (time-locks, amount limits, accredited investor checks)
   - On-chain audit trails for regulatory reporting

3. **Enterprise Access Control**
   - Role-based permissions (Admin, Minter, Pauser)
   - Delegatable authority for multi-signature workflows
   - Emergency pause mechanism for incident response

4. **Token Lifecycle Management**
   - Configurable minting (capped or unlimited supply)
   - Optional burning capability
   - Supply tracking and token enumeration

5. **REST API Integration Layer** (Token Creation Only)
   - Secure Web2-to-Web3 bridge for enterprise token creation
   - Token creation transaction building, signing, and broadcasting services
   - Asynchronous transaction tracking and confirmation status monitoring
   - Multi-tenant support for institutional clients
   - AI Agent integration capability for automated token deployment
   - **Note:** Post-creation token operations (mint, burn, transfer) are out of scope; clients interact directly with deployed tokens on-chain

### Non-Functional Requirements

**Smart Contract Layer:**

- **Gas Efficiency**: Optimized for batch operations and minimal deployment costs
- **Upgradeability**: Compliance hooks can be updated without token redeployment
- **Multi-Chain**: Deployable to Ethereum L1, L2s (Polygon, Arbitrum, Optimism), and private networks
- **Auditability**: All state changes emit indexed events for off-chain monitoring

**REST API Layer:**

- **Security**: OWASP API Security Top 10 (2023) compliance
- **Availability**: 99.9% uptime SLA with horizontal scalability
- **Observability**: Structured logging, distributed tracing, and metrics collection
- **Documentation**: OpenAPI 3.1 specification with interactive documentation

### Reference Documentation

**Smart Contract Standards:**

- [OpenZeppelin Contracts v5.5](https://docs.openzeppelin.com/contracts/5.x/)
- [EIP-20: Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [EIP-721: Non-Fungible Token Standard](https://eips.ethereum.org/EIPS/eip-721)
- [EIP-1155: Multi Token Standard](https://eips.ethereum.org/EIPS/eip-1155)
- [EIP-2981: NFT Royalty Standard](https://eips.ethereum.org/EIPS/eip-2981)

**API Security Standards:**

- [OWASP API Security Top 10 (2023)](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)
- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [JSON Web Token RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519)
- [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0)

## Solution Design

### Architecture Diagram

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TokenFactoryRegistry                                 │
│                    (Central Entry Point - Ownable)                           │
│  ┌─────────────────┬─────────────────┬─────────────────┐                    │
│  │ createERC20Token│ createERC721Token│createERC1155Token│                   │
│  │ createSimple*   │ createSimple*    │ createSimple*    │                   │
│  └────────┬────────┴────────┬─────────┴────────┬────────┘                   │
│           │                 │                  │                             │
│  ┌────────▼────────┬────────▼─────────┬────────▼────────┐                   │
│  │  ERC20Factory   │   ERC721Factory  │  ERC1155Factory │                   │
│  │   (Ownable)     │    (Ownable)     │    (Ownable)    │                   │
│  └────────┬────────┴────────┬─────────┴────────┬────────┘                   │
└───────────┼─────────────────┼──────────────────┼────────────────────────────┘
            │                 │                  │
            ▼                 ▼                  ▼
    ┌───────────────┐ ┌───────────────┐ ┌────────────────┐
    │  DewizERC20   │ │  DewizERC721  │ │  DewizERC1155  │
    │ ┌───────────┐ │ │ ┌───────────┐ │ │ ┌────────────┐ │
    │ │AccessCtrl │ │ │ │AccessCtrl │ │ │ │ AccessCtrl │ │
    │ │Pausable   │ │ │ │Pausable   │ │ │ │ Pausable   │ │
    │ │Burnable   │ │ │ │Burnable   │ │ │ │ Burnable   │ │
    │ │Compliance │ │ │ │Royalty    │ │ │ │ Royalty    │ │
    │ │  Hook ────┼─┼─┼─┤Compliance │ │ │ │ Supply     │ │
    │ └───────────┘ │ │ │  Hook ────┼─┼─┼─┤ Compliance │ │
    └───────────────┘ │ └───────────┘ │ │ │  Hook ─────┼─┤
                      └───────────────┘ │ └────────────┘ │
                                        └────────────────┘
                                                │
                              ┌─────────────────▼─────────────────┐
                              │        IComplianceHook            │
                              │  ┌─────────────────────────────┐  │
                              │  │ onMint(op, to, id, amount)  │  │
                              │  │ onTransfer(op,from,to,id,amt│  │
                              │  │ onBurn(op, from, id, amount)│  │
                              │  │ onApproval(op,own,spnd,id,a)│  │
                              │  │ isRestricted(account)       │  │
                              │  └─────────────────────────────┘  │
                              └───────────────────────────────────┘
```

### Contract Inheritance Hierarchy

```text
TokenFactoryRegistry
└── Ownable

ERC20Factory
├── IERC20Factory → ITokenFactory
└── Ownable

ERC721Factory
├── IERC721Factory → ITokenFactory
└── Ownable

ERC1155Factory
├── IERC1155Factory → ITokenFactory
└── Ownable

DewizERC20
├── ERC20
├── ERC20Burnable
├── ERC20Pausable
└── AccessControl

DewizERC721
├── ERC721
├── ERC721Burnable
├── ERC721Pausable
├── ERC721URIStorage
├── ERC721Royalty (ERC2981)
└── AccessControl

DewizERC1155
├── ERC1155
├── ERC1155Burnable
├── ERC1155Pausable
├── ERC1155Supply
├── ERC2981
└── AccessControl
```

### Key Invariants

1. **Immutable Feature Flags**: Once a token is created, `mintable`, `burnable`, and `pausable` flags cannot be changed
2. **Role-Based Access**: Sensitive operations always require specific roles; no backdoor admin functions
3. **Compliance Hook Fail-Secure**: If compliance hook reverts, the entire transaction reverts
4. **Factory Token Tracking**: Every created token is registered and verifiable via `isTokenFromFactory()`
5. **Initial Supply Constraint**: ERC20 only mints initial supply if `initialSupply > 0 AND initialHolder != address(0)`

---

## REST API Solution Design

### High-Level Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Web2 Clients                                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │  Web App    │  │  Mobile App │  │  AI Agents  │  │  Backend    │                 │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                 │
└─────────┼────────────────┼────────────────┼────────────────┼────────────────────────┘
          │                │                │                │
          └────────────────┴────────────────┴────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           API Gateway / Load Balancer                                │
│  ┌─────────────────────────────────────────────────────────────────────────────┐    │
│  │  • TLS Termination    • Rate Limiting    • Request Validation               │    │
│  │  • API Key Validation • CORS             • Request/Response Logging         │    │
│  └─────────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         TokenFactory REST API Service                                │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         Authentication & Authorization                         │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │  │
│  │  │ JWT Validator│  │ RBAC Engine  │  │ Tenant Mgmt  │  │ Audit Logger │       │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘       │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                            API Controllers (SOLID)                             │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │  │
│  │  │FactoryCtrl   │  │RegistryCtrl │  │QueryController│ │TxController  │       │  │
│  │  │ (Create)     │  │  (Config)   │  │  (Read)      │  │  (Status)    │       │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │  │
│  └─────────┼─────────────────┼─────────────────┼─────────────────┼───────────────┘  │
│            │                 │                 │                 │                   │
│  ┌─────────▼─────────────────▼─────────────────▼─────────────────▼───────────────┐  │
│  │                          Service Layer (Business Logic)                        │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐                   │  │
│  │  │ FactoryService │  │ RegistryService│  │ TransactionSvc │                   │  │
│  │  │ (ISingleResp)  │  │ (ISingleResp)  │  │ (ISingleResp)  │                   │  │
│  │  └────────┬───────┘  └────────┬───────┘  └────────┬───────┘                   │  │
│  └───────────┼───────────────────┼───────────────────┼───────────────────────────┘  │
│              │                   │                   │                               │
│  ┌───────────▼───────────────────▼───────────────────▼───────────────────────────┐  │
│  │                       Infrastructure Layer                                     │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐                   │  │
│  │  │ BlockchainRepo │  │ CacheRepo      │  │ DatabaseRepo   │                   │  │
│  │  │ (IRepository)  │  │ (IRepository)  │  │ (IRepository)  │                   │  │
│  │  └────────┬───────┘  └────────┬───────┘  └────────┬───────┘                   │  │
│  └───────────┼───────────────────┼───────────────────┼───────────────────────────┘  │
└──────────────┼───────────────────┼───────────────────┼───────────────────────────────┘
               │                   │                   │
               ▼                   ▼                   ▼
┌──────────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   Blockchain Nodes   │  │   Redis Cache    │  │   PostgreSQL     │
│  (Multi-chain RPC)   │  │  (Sessions/Nonce)│  │  (Users/Tokens)  │
└──────────────────────┘  └──────────────────┘  └──────────────────┘
```

### Multi-Tenancy Architecture

#### What is a Tenant?

In the TokenFactory API context, a **tenant** represents a **customer organization** that uses the platform. Each tenant is a separate entity with its own users, tokens, and data.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TokenFactory Platform                                │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │   Tenant A:     │  │   Tenant B:     │  │   Tenant C:     │              │
│  │   Bank ABC      │  │   Fintech XYZ   │  │   Asset Fund Y  │              │
│  │                 │  │                 │  │                 │              │
│  │ • Users         │  │ • Users         │  │ • Users         │              │
│  │ • Tokens        │  │ • Tokens        │  │ • Tokens        │              │
│  │ • API Keys      │  │ • API Keys      │  │ • API Keys      │              │
│  │ • Audit Logs    │  │ • Audit Logs    │  │ • Audit Logs    │              │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘              │
│                                                                              │
│                    ┌─────────────────────────┐                               │
│                    │   Shared Infrastructure │                               │
│                    │   • API Servers         │                               │
│                    │   • Database            │                               │
│                    │   • Blockchain Nodes    │                               │
│                    └─────────────────────────┘                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Practical Examples:**

| Tenant | Organization Type | Use Case |
| ------ | ----------------- | -------- |
| Bank ABC | Traditional Bank | Stablecoin issuance for payments |
| Fintech XYZ | Payment Provider | Tokenized remittance certificates |
| Asset Fund Y | Investment Fund | Tokenized government bonds |
| Startup Z | Tech Company | Utility tokens for platform economics |

#### Why Multi-Tenancy?

The multi-tenant architecture was chosen for the following strategic and technical reasons:

| Benefit | Description |
| ------- | ----------- |
| **Cost Efficiency** | A single deployment serves multiple customers, reducing infrastructure costs (servers, databases, monitoring), operational overhead (maintenance, updates, security patches), and development effort (one codebase, consistent features). |
| **Simplified Operations** | Single deployment to maintain and monitor with centralized logging and alerting, unified security updates, and consistent API versioning across all customers. |
| **Scalability** | Horizontal scaling serves all tenants simultaneously. Resource sharing enables efficient capacity utilization. New customers onboard without infrastructure provisioning. |
| **Feature Parity** | All customers receive the same features and updates. Bug fixes automatically benefit everyone. New compliance hooks available to all tenants. |
| **Enterprise Suitability** | Multi-tenancy is the industry standard for SaaS platforms serving financial institutions, enabling rapid customer onboarding, predictable pricing models, and centralized compliance management. |

#### Tenant Isolation Mechanism

Despite sharing infrastructure, tenant data is strictly isolated:

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                           Request Flow with Tenant Isolation                  │
└──────────────────────────────────────────────────────────────────────────────┘

  Client Request                                     Database Query
       │                                                   │
       ▼                                                   ▼
┌──────────────┐     ┌──────────────┐     ┌───────────────────────────────────┐
│ HTTP Request │     │ JWT Token    │     │ SELECT * FROM tokens              │
│ + Bearer JWT │ ──▶ │ Contains:    │ ──▶ │ WHERE tenant_id = 'tenant-uuid'   │
└──────────────┘     │ tenant_id    │     │ AND ...                           │
                     │ user_id      │     └───────────────────────────────────┘
                     │ roles        │
                     │ permissions  │              ▲
                     └──────────────┘              │
                                                   │
                                         Automatic tenant filter
                                         injected by middleware
```

**Isolation Guarantees:**

1. **Authentication**: JWT tokens contain `tenant_id` claim; tokens are scoped to a single tenant
2. **Authorization**: RBAC permissions are evaluated within tenant context
3. **Data Access**: All database queries automatically filter by `tenant_id`
4. **API Keys**: Each API key is bound to a specific tenant
5. **Audit Logs**: All actions logged with tenant context for compliance reporting

**Security Boundaries:**

- Tenant A **cannot** see or access Tenant B's tokens, users, or transaction history
- Cross-tenant access is explicitly denied at the middleware layer
- Database-level row security policies provide defense-in-depth

### SOLID Principles Implementation

| Principle | Implementation |
| --------- | -------------- |
| **S**ingle Responsibility | Each controller handles one domain (Factory, Registry, Query, Transactions). Services are focused: `FactoryService` creates tokens, `RegistryService` manages factory configuration. |
| **O**pen/Closed | New token types (e.g., ERC-3525) can be added via new factory services without modifying existing ones. Plugin architecture for compliance hooks. |
| **L**iskov Substitution | All factory services implement `IFactoryService` interface. ERC20Factory, ERC721Factory, ERC1155Factory services are interchangeable where base operations apply. |
| **I**nterface Segregation | Separate interfaces: `ITokenCreator`, `ITokenQuerier`, `IRegistryAdmin`. Clients depend only on interfaces they use. |
| **D**ependency Inversion | Controllers depend on service interfaces, not implementations. `IBlockchainRepository` abstracts chain interactions; easily swap between providers. |

### Recommended Technology Stack

| Component | Recommended | Alternative | Rationale |
| --------- | ----------- | ----------- | --------- |
| **Language** | Rust 1.75+ (2024 Edition) | Go 1.22+ | Memory safety without GC, zero-cost abstractions, excellent performance. Strong type system catches errors at compile time. |
| **Framework** | Axum 0.7+ | Actix-web 4.x | Built on Tokio, tower middleware ecosystem, type-safe extractors, excellent ergonomics. |
| **Async Runtime** | Tokio | async-std | Industry standard, mature ecosystem, work-stealing scheduler. |
| **Blockchain SDK** | ethers-rs / alloy | web3-rs | Comprehensive Ethereum support, contract bindings generation, typed transactions. |
| **Database ORM** | SQLx | SeaORM / Diesel | Compile-time checked queries, async-first, type-safe without sacrificing SQL control. |
| **Database** | PostgreSQL 16 | CockroachDB | ACID compliance, JSON support, mature ecosystem. |
| **Cache** | Redis (redis-rs) | Dragonfly | Nonce management, session storage, rate limiting. |
| **Queue** | NATS JetStream (async-nats) | RabbitMQ (lapin) | Async transaction processing, event streaming. |
| **Serialization** | serde + serde_json | - | De facto standard, derive macros, excellent performance. |
| **Error Handling** | thiserror + anyhow | eyre | Structured errors for libraries, ergonomic errors for applications. |
| **Config** | config-rs + dotenvy | figment | Layered configuration, environment variable support. |
| **Auth** | Keycloak / Auth0 | Custom JWT (jsonwebtoken) | Enterprise SSO, OIDC, multi-tenant support. |
| **OpenAPI** | utoipa + utoipa-swagger-ui | paperclip | Derive macros for OpenAPI 3.1, automatic Swagger UI. |
| **Observability** | tracing + tracing-opentelemetry | - | Structured logging, spans, OpenTelemetry export. |
| **Testing** | tokio-test + wiremock | mockall | Async test utilities, HTTP mocking for integration tests. |

> **Note on Language Choice:** The Rust stack above is provided as a **reference implementation** due to its strong type safety, performance characteristics, and growing adoption in blockchain tooling. However, this API can equally be implemented using **JavaScript/TypeScript** (Node.js with Express, Fastify, or NestJS) or **Go** — both are excellent choices with mature ecosystems for building production-grade REST APIs. The architectural patterns (Hexagonal Architecture, SOLID principles, RBAC) described in this document are language-agnostic and apply regardless of the implementation language chosen.

### Backend Architecture (Hexagonal/Clean Architecture)

The API follows **Hexagonal Architecture** (Ports & Adapters) combined with **Domain-Driven Design** principles. The examples below use Rust syntax, but the architecture applies equally to TypeScript/Node.js or Go implementations.

```text
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Rust Backend Architecture                               │
│                         (Hexagonal / Clean Architecture)                             │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            Driving Adapters (Primary)                                │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐       │
│  │   Axum HTTP Handler  │  │   gRPC Service       │  │   CLI Commands       │       │
│  │   (REST API)         │  │   (Internal RPC)     │  │   (Admin Tools)      │       │
│  └──────────┬───────────┘  └──────────┬───────────┘  └──────────┬───────────┘       │
└─────────────┼──────────────────────────┼──────────────────────────┼──────────────────┘
              │                          │                          │
              ▼                          ▼                          ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Application Layer                                       │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │                         Ports (Trait Definitions)                             │   │
│  │  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐      │   │
│  │  │ TokenCreatorPort   │  │ RegistryQueryPort  │  │ TransactionPort    │      │   │
│  │  │ (trait)            │  │ (trait)            │  │ (trait)            │      │   │
│  │  └────────────────────┘  └────────────────────┘  └────────────────────┘      │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │                         Use Cases / Services                                  │   │
│  │  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐      │   │
│  │  │CreateTokenUseCase  │  │QueryTokensUseCase  │  │SubmitTxUseCase    │      │   │
│  │  │ impl TokenCreator  │  │ impl RegistryQuery │  │ impl Transaction   │      │   │
│  │  └────────────────────┘  └────────────────────┘  └────────────────────┘      │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
              │                          │                          │
              ▼                          ▼                          ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                Domain Layer                                          │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │                         Domain Entities & Value Objects                       │   │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐  ┌────────────┐  │   │
│  │  │ Token (Entity) │  │ TokenParams    │  │ ChainId        │  │ TxHash     │  │   │
│  │  │ - address      │  │ (Value Object) │  │ (newtype)      │  │ (newtype)  │  │   │
│  │  │ - token_type   │  │ - name         │  └────────────────┘  └────────────┘  │   │
│  │  │ - features     │  │ - symbol       │                                       │   │
│  │  │ - created_at   │  │ - decimals     │  ┌────────────────┐  ┌────────────┐  │   │
│  │  └────────────────┘  │ - compliance   │  │ Address        │  │ TenantId   │  │   │
│  │                      └────────────────┘  │ (newtype)      │  │ (newtype)  │  │   │
│  │  ┌────────────────────────────────────┐  └────────────────┘  └────────────┘  │   │
│  │  │ Domain Errors (thiserror)          │                                       │   │
│  │  │ - InvalidTokenParams               │                                       │   │
│  │  │ - ComplianceHookNotFound           │                                       │   │
│  │  │ - TransactionFailed                │                                       │   │
│  │  └────────────────────────────────────┘                                       │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
              │                          │                          │
              ▼                          ▼                          ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            Driven Adapters (Secondary)                               │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐       │
│  │  PostgresRepository  │  │  EthereumAdapter     │  │  RedisCache          │       │
│  │  (SQLx)              │  │  (ethers-rs/alloy)   │  │  (redis-rs)          │       │
│  │  impl TokenRepo      │  │  impl BlockchainPort │  │  impl CachePort      │       │
│  └──────────┬───────────┘  └──────────┬───────────┘  └──────────┬───────────┘       │
└─────────────┼──────────────────────────┼──────────────────────────┼──────────────────┘
              │                          │                          │
              ▼                          ▼                          ▼
        ┌───────────┐            ┌───────────┐              ┌───────────┐
        │PostgreSQL │            │ RPC Nodes │              │   Redis   │
        └───────────┘            └───────────┘              └───────────┘
```

### Project Structure (Rust Reference)

The following structure illustrates the recommended organization using Rust. For TypeScript/Node.js implementations, a similar structure can be achieved using `src/` directories with `domain/`, `application/`, `infrastructure/`, and `adapters/` folders. For Go, a standard project layout with `internal/`, `pkg/`, and `cmd/` directories works well.

```text
tokenfactory-api/
├── Cargo.toml                    # Workspace manifest
├── Cargo.lock
├── .cargo/
│   └── config.toml               # Build settings (e.g., linker)
│
├── crates/
│   ├── api/                      # HTTP API (Axum handlers)
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── handlers/         # Route handlers
│   │       │   ├── mod.rs
│   │       │   ├── tokens.rs     # POST /tokens/erc20, GET /tokens
│   │       │   ├── registry.rs   # GET /registry/*
│   │       │   └── transactions.rs
│   │       ├── extractors/       # Custom Axum extractors
│   │       │   ├── mod.rs
│   │       │   ├── auth.rs       # JWT claims extractor
│   │       │   └── tenant.rs     # Tenant context extractor
│   │       ├── middleware/       # Tower middleware
│   │       │   ├── mod.rs
│   │       │   ├── auth.rs
│   │       │   ├── rate_limit.rs
│   │       │   └── tracing.rs
│   │       ├── dto/              # Request/Response DTOs
│   │       │   ├── mod.rs
│   │       │   ├── requests.rs
│   │       │   └── responses.rs
│   │       ├── error.rs          # API error types → HTTP responses
│   │       └── openapi.rs        # utoipa OpenAPI spec
│   │
│   ├── domain/                   # Domain layer (pure Rust, no external deps)
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── entities/         # Domain entities
│   │       │   ├── mod.rs
│   │       │   ├── token.rs
│   │       │   └── transaction.rs
│   │       ├── value_objects/    # Newtypes with validation
│   │       │   ├── mod.rs
│   │       │   ├── address.rs    # Ethereum address (validated)
│   │       │   ├── chain_id.rs
│   │       │   ├── token_params.rs
│   │       │   └── tenant_id.rs
│   │       ├── ports/            # Trait definitions (interfaces)
│   │       │   ├── mod.rs
│   │       │   ├── token_repository.rs
│   │       │   ├── blockchain.rs
│   │       │   └── cache.rs
│   │       └── errors.rs         # Domain errors (thiserror)
│   │
│   ├── application/              # Use cases / Application services
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── use_cases/
│   │       │   ├── mod.rs
│   │       │   ├── create_token.rs
│   │       │   ├── query_tokens.rs
│   │       │   └── submit_transaction.rs
│   │       └── services/
│   │           ├── mod.rs
│   │           ├── factory_service.rs
│   │           └── transaction_service.rs
│   │
│   ├── infrastructure/           # Adapters (external systems)
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── database/         # PostgreSQL adapter
│   │       │   ├── mod.rs
│   │       │   ├── postgres_token_repo.rs
│   │       │   └── migrations/
│   │       ├── blockchain/       # Ethereum adapter
│   │       │   ├── mod.rs
│   │       │   ├── ethereum_client.rs
│   │       │   └── contract_bindings/  # Generated from ABI
│   │       ├── cache/            # Redis adapter
│   │       │   ├── mod.rs
│   │       │   └── redis_nonce_manager.rs
│   │       └── queue/            # NATS adapter
│   │           ├── mod.rs
│   │           └── nats_publisher.rs
│   │
│   └── shared/                   # Shared utilities
│       ├── Cargo.toml
│       └── src/
│           ├── lib.rs
│           ├── config.rs         # Configuration loading
│           └── telemetry.rs      # Tracing setup
│
├── bins/
│   └── server/                   # Main binary
│       ├── Cargo.toml
│       └── src/
│           └── main.rs           # Entrypoint, DI, server startup
│
├── tests/                        # Integration tests
│   ├── api_tests.rs
│   └── common/
│       └── mod.rs
│
└── migrations/                   # SQLx migrations
    ├── 20240101_create_tokens.sql
    └── 20240102_create_transactions.sql
```

### Design Patterns (Rust Examples)

The following patterns demonstrate best practices using Rust. Equivalent patterns exist in TypeScript (branded types, class-based validation) and Go (custom types, interfaces).

**1. Newtype Pattern for Type Safety:**

```rust
// domain/src/value_objects/address.rs
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(try_from = "String", into = "String")]
pub struct EthAddress([u8; 20]);

#[derive(Debug, Error)]
pub enum AddressError {
    #[error("Invalid address format: {0}")]
    InvalidFormat(String),
    #[error("Invalid checksum")]
    InvalidChecksum,
}

impl EthAddress {
    pub fn new(s: &str) -> Result<Self, AddressError> {
        // Validation logic with checksum verification
        let bytes = hex::decode(s.strip_prefix("0x").unwrap_or(s))
            .map_err(|_| AddressError::InvalidFormat(s.to_string()))?;
        if bytes.len() != 20 {
            return Err(AddressError::InvalidFormat(s.to_string()));
        }
        Ok(Self(bytes.try_into().unwrap()))
    }
}
```

**2. Repository Trait (Port):**

```rust
// domain/src/ports/token_repository.rs
use async_trait::async_trait;
use crate::entities::Token;
use crate::value_objects::{EthAddress, TenantId, ChainId};
use crate::errors::DomainError;

#[async_trait]
pub trait TokenRepository: Send + Sync {
    async fn save(&self, token: &Token) -> Result<(), DomainError>;
    async fn find_by_address(&self, address: &EthAddress, chain: ChainId)
        -> Result<Option<Token>, DomainError>;
    async fn find_by_tenant(&self, tenant: &TenantId, page: u32, limit: u32)
        -> Result<Vec<Token>, DomainError>;
}
```

**3. Use Case with Dependency Injection:**

```rust
// application/src/use_cases/create_token.rs
use std::sync::Arc;
use crate::domain::ports::{TokenRepository, BlockchainClient, NonceManager};
use crate::domain::value_objects::TokenParams;
use crate::domain::errors::DomainError;

pub struct CreateTokenUseCase {
    token_repo: Arc<dyn TokenRepository>,
    blockchain: Arc<dyn BlockchainClient>,
    nonce_manager: Arc<dyn NonceManager>,
}

impl CreateTokenUseCase {
    pub fn new(
        token_repo: Arc<dyn TokenRepository>,
        blockchain: Arc<dyn BlockchainClient>,
        nonce_manager: Arc<dyn NonceManager>,
    ) -> Self {
        Self { token_repo, blockchain, nonce_manager }
    }

    pub async fn execute(&self, params: TokenParams) -> Result<UnsignedTx, DomainError> {
        // 1. Validate params (already done by TokenParams::new())
        // 2. Get nonce
        let nonce = self.nonce_manager.next_nonce(&params.creator).await?;
        // 3. Build unsigned transaction
        let unsigned_tx = self.blockchain.build_create_token_tx(&params, nonce).await?;
        // 4. Store pending transaction
        self.token_repo.save_pending(&params, &unsigned_tx).await?;
        Ok(unsigned_tx)
    }
}
```

**4. Axum Handler with Extractors:**

```rust
// api/src/handlers/tokens.rs
use axum::{extract::State, Json};
use crate::dto::{CreateTokenRequest, CreateTokenResponse};
use crate::extractors::{AuthClaims, TenantContext};
use crate::error::ApiError;
use crate::AppState;

#[utoipa::path(
    post,
    path = "/v1/tokens/erc20",
    request_body = CreateTokenRequest,
    responses(
        (status = 202, description = "Token creation initiated", body = CreateTokenResponse),
        (status = 400, description = "Invalid parameters"),
        (status = 401, description = "Unauthorized"),
    ),
    security(("bearer" = []))
)]
pub async fn create_erc20_token(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,       // JWT extraction + validation
    TenantContext(tenant): TenantContext, // Tenant isolation
    Json(request): Json<CreateTokenRequest>,
) -> Result<Json<CreateTokenResponse>, ApiError> {
    // Permission check
    claims.require_permission("factory:create-token")?;

    // Convert DTO to domain value object (validates at boundary)
    let params = request.try_into_domain(tenant.id)?;

    // Execute use case
    let unsigned_tx = state.create_token_use_case.execute(params).await?;

    Ok(Json(CreateTokenResponse::from(unsigned_tx)))
}
```

**5. Error Handling Chain:**

```rust
// Domain errors (thiserror)
#[derive(Debug, Error)]
pub enum DomainError {
    #[error("Invalid token parameters: {0}")]
    InvalidParams(String),
    #[error("Compliance hook not found: {0}")]
    ComplianceHookNotFound(EthAddress),
    #[error("Transaction failed: {0}")]
    TransactionFailed(String),
}

// API errors (converts domain → HTTP)
#[derive(Debug)]
pub struct ApiError {
    status: StatusCode,
    code: String,
    message: String,
}

impl From<DomainError> for ApiError {
    fn from(err: DomainError) -> Self {
        match err {
            DomainError::InvalidParams(msg) => ApiError {
                status: StatusCode::BAD_REQUEST,
                code: "INVALID_PARAMS".into(),
                message: msg,
            },
            DomainError::ComplianceHookNotFound(_) => ApiError {
                status: StatusCode::UNPROCESSABLE_ENTITY,
                code: "COMPLIANCE_HOOK_NOT_FOUND".into(),
                message: err.to_string(),
            },
            // ...
        }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let body = Json(ProblemDetails { /* RFC 7807 */ });
        (self.status, body).into_response()
    }
}
```

### Token Creation Transaction Flow

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                  Token Creation Transaction Lifecycle                        │
└─────────────────────────────────────────────────────────────────────────────┘

  Client                API Service              Queue              Blockchain
    │                        │                     │                     │
    │  1. POST /tokens/erc20 │                     │                     │
    │ ──────────────────────>│                     │                     │
    │                        │                     │                     │
    │                        │ 2. Validate request │                     │
    │                        │    Build transaction│                     │
    │                        │    Estimate gas     │                     │
    │                        │                     │                     │
    │  3. Return unsigned tx │                     │                     │
    │    + txId (pending)    │                     │                     │
    │ <──────────────────────│                     │                     │
    │                        │                     │                     │
    │  4. Sign tx (client    │                     │                     │
    │     wallet/HSM)        │                     │                     │
    │                        │                     │                     │
    │  5. POST /transactions │                     │                     │
    │     /{txId}/submit     │                     │                     │
    │ ──────────────────────>│                     │                     │
    │                        │                     │                     │
    │                        │ 6. Enqueue tx       │                     │
    │                        │ ──────────────────> │                     │
    │                        │                     │                     │
    │  7. Return txId        │                     │                     │
    │    (status: submitted) │                     │                     │
    │ <──────────────────────│                     │                     │
    │                        │                     │                     │
    │                        │                     │ 8. Broadcast tx     │
    │                        │                     │ ───────────────────>│
    │                        │                     │                     │
    │                        │                     │ 9. tx hash returned │
    │                        │                     │ <───────────────────│
    │                        │                     │                     │
    │                        │ 10. Update status   │                     │
    │                        │ <────────────────── │                     │
    │                        │                     │                     │
    │  11. GET /transactions │                     │                     │
    │      /{txId}           │                     │                     │
    │ ──────────────────────>│                     │                     │
    │                        │                     │                     │
    │  12. Return status     │                     │                     │
    │      (confirmed/failed)│                     │                     │
    │ <──────────────────────│                     │                     │
```

**Key Design Decisions:**

1. **Server-side transaction building, client-side signing**: API never holds private keys
2. **Async transaction processing**: Queue-based broadcast for reliability and retry
3. **Idempotent submissions**: Unique txId prevents duplicate broadcasts
4. **Nonce management**: Centralized nonce tracking per address in Redis

---

## OWASP API Security Top 10 (2023) Mitigations

### Security Controls Matrix

| OWASP ID | Vulnerability | Risk | Mitigation Strategy |
| -------- | ------------- | ---- | ------------------- |
| **API1:2023** | Broken Object Level Authorization (BOLA) | Critical | Token ownership verified before operations. `GET /tokens/{tokenAddress}` validates caller owns or has role on token. Object-level ACLs in database. |
| **API2:2023** | Broken Authentication | Critical | OAuth 2.0 + OIDC via Keycloak. JWT with short expiry (15 min). Refresh tokens with rotation. Hardware key support (WebAuthn). |
| **API3:2023** | Broken Object Property Level Authorization | High | DTO projection per role. Admins see `complianceHook`; users don't. Field-level access control in serializers. |
| **API4:2023** | Unrestricted Resource Consumption | High | Rate limiting per API key (Redis). Request size limits (1MB). Pagination enforced (max 100 items). Gas estimation capped. |
| **API5:2023** | Broken Function Level Authorization | Critical | RBAC middleware on all endpoints. Separate admin/user API paths. Role hierarchy: `SUPER_ADMIN > TENANT_ADMIN > OPERATOR > VIEWER`. |
| **API6:2023** | Unrestricted Access to Sensitive Business Flows | Medium | Token creation requires KYC verification. Compliance hook configuration requires approval workflow. Factory registration restricted to super admins. |
| **API7:2023** | Server Side Request Forgery (SSRF) | High | RPC URLs from allowlist only. No user-controlled URLs. Webhook destinations validated. Metadata URIs sanitized. |
| **API8:2023** | Security Misconfiguration | Medium | Hardened containers. No debug endpoints in production. CORS restricted. Security headers enforced. Secrets in Vault. |
| **API9:2023** | Improper Inventory Management | Medium | OpenAPI spec as source of truth. API versioning (v1, v2). Deprecated endpoints return warnings. Shadow/zombie API detection. |
| **API10:2023** | Unsafe Consumption of APIs | Medium | RPC responses validated. External API calls timeout-protected. Circuit breakers for blockchain nodes. Response schemas enforced. |

### Authentication & Authorization Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          Authentication Flow                                         │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐       ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    Client    │       │  API Gateway │       │   Keycloak   │       │  API Service │
└──────┬───────┘       └──────┬───────┘       └──────┬───────┘       └──────┬───────┘
       │                      │                      │                      │
       │ 1. Login (OAuth2)    │                      │                      │
       │ ────────────────────>│                      │                      │
       │                      │ 2. Redirect to IdP   │                      │
       │                      │ ────────────────────>│                      │
       │                      │                      │                      │
       │ 3. Authenticate      │                      │                      │
       │ ─────────────────────────────────────────── │                      │
       │                      │                      │                      │
       │ 4. JWT (access + refresh)                   │                      │
       │ <────────────────────────────────────────── │                      │
       │                      │                      │                      │
       │ 5. API Request + Bearer Token               │                      │
       │ ────────────────────>│                      │                      │
       │                      │ 6. Validate JWT      │                      │
       │                      │ (signature, expiry,  │                      │
       │                      │  issuer, audience)   │                      │
       │                      │                      │                      │
       │                      │ 7. Forward + claims  │                      │
       │                      │ ─────────────────────────────────────────── │
       │                      │                      │                      │
       │                      │                      │  8. Check RBAC       │
       │                      │                      │     (tenant, role)   │
       │                      │                      │                      │
       │ 9. Response          │                      │                      │
       │ <────────────────────────────────────────────────────────────────  │
```

**JWT Claims Structure:**

```json
{
  "sub": "user-uuid",
  "iss": "https://auth.dewiz.xyz",
  "aud": "tokenfactory-api",
  "exp": 1707123456,
  "iat": 1707122556,
  "tenant_id": "tenant-uuid",
  "roles": ["OPERATOR"],
  "permissions": ["factory:create-token", "factory:read", "registry:read"],
  "kyc_verified": true
}
```

### Role-Based Access Control (RBAC)

| Role | Permissions | Scope |
| ---- | ----------- | ----- |
| `SUPER_ADMIN` | All operations, manage tenants, register factories | Global |
| `TENANT_ADMIN` | Manage users, all factory operations within tenant | Tenant |
| `OPERATOR` | Create tokens via factory, query token info | Tenant |
| `COMPLIANCE_OFFICER` | Configure compliance hooks during token creation | Tenant |
| `VIEWER` | Read-only access to token and factory info | Tenant |
| `AI_AGENT` | Automated token creation with strict rate limits | Per-agent |

---

## Implementation Details

### Smart Contract Access Control Roles

| Role                 | Constant                       | Purpose                                                      | Granted To                 |
| -------------------- | ------------------------------ | ------------------------------------------------------------ | -------------------------- |
| `DEFAULT_ADMIN_ROLE` | `0x00`                         | Full control, can grant/revoke roles, update compliance hook | Token creator              |
| `MINTER_ROLE`        | `keccak256("MINTER_ROLE")`     | Mint new tokens                                              | Token creator (if mintable)|
| `PAUSER_ROLE`        | `keccak256("PAUSER_ROLE")`     | Pause/unpause transfers                                      | Token creator (if pausable)|
| `URI_SETTER_ROLE`    | `keccak256("URI_SETTER_ROLE")` | Update metadata URIs (ERC1155 only)                          | Token creator              |

### Token Configuration Parameters

**ERC20TokenParams:**

```solidity
struct ERC20TokenParams {
    string name;              // Token name
    string symbol;            // Token symbol
    uint8 decimals;           // Decimal places (typically 18)
    uint256 initialSupply;    // Initial tokens to mint
    address initialHolder;    // Recipient of initial supply
    bool isMintable;          // Enable minting capability
    bool isBurnable;          // Enable burning capability
    bool isPausable;          // Enable pause functionality
    address complianceHook;   // Optional compliance contract
}
```

**ERC721TokenParams:**

```solidity
struct ERC721TokenParams {
    string name;              // Collection name
    string symbol;            // Collection symbol
    string baseURI;           // Base URI for metadata
    address admin;            // Admin address
    bool isMintable;          // Enable minting
    bool isBurnable;          // Enable burning
    bool isPausable;          // Enable pause
    bool hasRoyalty;          // Enable ERC2981 royalties
    address royaltyReceiver;  // Royalty recipient
    uint96 royaltyFeeNumerator; // Fee in basis points (250 = 2.5%)
    address complianceHook;   // Optional compliance contract
}
```

**ERC1155TokenParams:**

```solidity
struct ERC1155TokenParams {
    string name;              // Collection name
    string symbol;            // Collection symbol
    string uri;               // Base URI with {id} placeholder
    address admin;            // Admin address
    bool isMintable;          // Enable minting
    bool isBurnable;          // Enable burning
    bool isPausable;          // Enable pause
    bool hasRoyalty;          // Enable ERC2981 royalties
    address royaltyReceiver;  // Royalty recipient
    uint96 royaltyFeeNumerator; // Fee in basis points
    address complianceHook;   // Optional compliance contract
}
```

### Compliance Hook Interface

```solidity
interface IComplianceHook {
    // Called before/after minting
    function onMint(address operator, address to, uint256 id, uint256 amount) external;

    // Called before/after transfers
    function onTransfer(address operator, address from, address to, uint256 id, uint256 amount) external;

    // Called before/after burning
    function onBurn(address operator, address from, uint256 id, uint256 amount) external;

    // Called before approvals
    function onApproval(address operator, address owner, address spender, uint256 id, uint256 amount) external;

    // Check if address is restricted (OFAC, etc.)
    function isRestricted(address account) external view returns (bool);
}
```

**Hook Integration Timing:**

- **ERC20**: Hooks called in `_update()` override BEFORE state change (pre-validation)
- **ERC721/ERC1155**: Hooks called in `_update()` override AFTER state change (atomic with state)
- **Approvals**: All hooks called BEFORE approval is set

### Key Functions

**TokenFactoryRegistry:**

- `registerAllFactories(address erc20, address erc721, address erc1155)` - Register all factories
- `createERC20Token(ERC20TokenParams)` / `createSimpleERC20Token(name, symbol, supply)` - Create ERC20
- `createERC721Token(ERC721TokenParams)` / `createSimpleERC721Token(name, symbol, uri)` - Create ERC721
- `createERC1155Token(ERC1155TokenParams)` / `createSimpleERC1155Token(name, symbol, uri)` - Create ERC1155
- `getTotalTokenCount()` - Count all tokens across factories
- `isTokenFromAnyFactory(address)` - Verify token was created by this system

**Token Contracts (shared patterns):**

- `mint(...)` - Create new tokens (MINTER_ROLE required, reverts if `!isMintable`)
- `burn(...)` / `burnFrom(...)` - Destroy tokens (reverts if `!isBurnable`)
- `pause()` / `unpause()` - Emergency stop (PAUSER_ROLE required, reverts if `!isPausable`)
- `setComplianceHook(address)` - Update compliance contract (DEFAULT_ADMIN_ROLE)

### Events

```solidity
// TokenFactoryRegistry
event FactoryRegistered(TokenType indexed tokenType, address indexed factoryAddress);

// All Factories
event TokenCreated(address indexed tokenAddress, address indexed creator, string name, string symbol);

// All Tokens
event ComplianceHookUpdated(address oldHook, address newHook);

// IComplianceHook
event ComplianceValidation(bytes4 indexed functionSig, address indexed operator, address from, address to, uint256 value);
```

### Error Definitions

```solidity
// Token Errors
error MintingDisabled();
error BurningDisabled();
error PausingDisabled();

// ERC1155 Errors
error ArrayLengthMismatch();
error TokenTypeDoesNotExist(uint256 tokenId);

// Registry Errors (inherited from factory interfaces)
// Standard OpenZeppelin errors for AccessControl, Pausable, etc.
```

---

## REST API Endpoints Specification

### Base URL

```text
Production:  https://api.dewiz.xyz/v1
Staging:     https://api-staging.dewiz.xyz/v1
Development: http://localhost:8080/v1
```

### Token Management Endpoints

#### Create Tokens

| Method | Endpoint | Description | Required Role |
| ------ | -------- | ----------- | ------------- |
| `POST` | `/tokens/erc20` | Create ERC-20 token | `OPERATOR` |
| `POST` | `/tokens/erc721` | Create ERC-721 collection | `OPERATOR` |
| `POST` | `/tokens/erc1155` | Create ERC-1155 multi-token | `OPERATOR` |

**Request Body (ERC-20 Example):**

```json
{
  "name": "USD Stablecoin",
  "symbol": "USDD",
  "decimals": 6,
  "initialSupply": "1000000000000",
  "initialHolder": "0x1234567890abcdef1234567890abcdef12345678",
  "isMintable": true,
  "isBurnable": true,
  "isPausable": true,
  "complianceHook": "0xabcdef1234567890abcdef1234567890abcdef12",
  "chainId": 1
}
```

**Response (202 Accepted):**

```json
{
  "transactionId": "tx_01HQXYZ123456789",
  "status": "pending_signature",
  "unsignedTransaction": {
    "to": "0xRegistryAddress...",
    "data": "0x...",
    "value": "0",
    "gasLimit": "500000",
    "maxFeePerGas": "50000000000",
    "maxPriorityFeePerGas": "2000000000",
    "nonce": 42,
    "chainId": 1
  },
  "expiresAt": "2024-02-05T12:30:00Z"
}
```

#### Query Tokens

| Method | Endpoint | Description | Required Role |
| ------ | -------- | ----------- | ------------- |
| `GET` | `/tokens` | List all tokens created by factory (paginated) | `VIEWER` |
| `GET` | `/tokens/{address}` | Get token details | `VIEWER` |
| `GET` | `/tokens/{address}/features` | Get token feature flags (mintable, burnable, pausable) | `VIEWER` |
| `GET` | `/tokens/by-creator/{creator}` | List tokens created by specific address | `VIEWER` |

**Query Parameters:**

```text
?page=1&limit=20&type=erc20&chainId=1&creator=0x...&sortBy=createdAt&order=desc
```

**Response (Token Details):**

```json
{
  "address": "0x1234567890abcdef1234567890abcdef12345678",
  "type": "ERC20",
  "name": "USD Stablecoin",
  "symbol": "USDD",
  "decimals": 6,
  "initialSupply": "1000000000000",
  "chainId": 1,
  "features": {
    "mintable": true,
    "burnable": true,
    "pausable": true
  },
  "complianceHook": "0xabcdef1234567890abcdef1234567890abcdef12",
  "initialHolder": "0xholder...",
  "creator": "0xcreator...",
  "createdAt": "2024-02-05T10:00:00Z",
  "transactionHash": "0xtxhash..."
}
```

**Note:** The API returns token configuration as set during creation. For real-time token state (total supply, paused status, balances), query the blockchain directly or use a dedicated token management service.

### Factory Registry Endpoints

| Method | Endpoint | Description | Required Role |
| ------ | -------- | ----------- | ------------- |
| `GET` | `/registry` | Get registry contract info | `VIEWER` |
| `GET` | `/registry/factories` | List all registered factories | `VIEWER` |
| `GET` | `/registry/factories/{type}` | Get factory for token type (erc20/erc721/erc1155) | `VIEWER` |
| `GET` | `/registry/stats` | Get total token count across all factories | `VIEWER` |
| `GET` | `/registry/verify/{address}` | Verify if token was created by this factory | `VIEWER` |

**Registry Info Response:**

```json
{
  "registryAddress": "0xregistry...",
  "chainId": 1,
  "factories": {
    "erc20": "0xerc20factory...",
    "erc721": "0xerc721factory...",
    "erc1155": "0xerc1155factory..."
  },
  "totalTokensCreated": 1250,
  "deployedAt": "2024-01-15T00:00:00Z"
}
```

### Transaction Management Endpoints

| Method | Endpoint | Description | Required Role |
| ------ | -------- | ----------- | ------------- |
| `POST` | `/transactions/{txId}/submit` | Submit signed transaction | `OPERATOR` |
| `GET` | `/transactions/{txId}` | Get transaction status | `VIEWER` |
| `GET` | `/transactions` | List transactions (paginated) | `VIEWER` |
| `POST` | `/transactions/{txId}/cancel` | Cancel pending transaction | `OPERATOR` |
| `POST` | `/transactions/{txId}/speedup` | Speedup with higher gas | `OPERATOR` |

**Submit Signed Transaction:**

```json
{
  "signedTransaction": "0xf86c...signed_tx_hex..."
}
```

**Transaction Status Response:**

```json
{
  "transactionId": "tx_01HQXYZ123456789",
  "status": "confirmed",
  "chainId": 1,
  "transactionHash": "0xabcdef...",
  "blockNumber": 19000000,
  "blockTimestamp": "2024-02-05T10:05:00Z",
  "gasUsed": "250000",
  "effectiveGasPrice": "45000000000",
  "contractAddress": "0xnewtoken...",
  "events": [
    {
      "name": "TokenCreated",
      "args": {
        "tokenAddress": "0xnewtoken...",
        "creator": "0xcreator...",
        "name": "USD Stablecoin",
        "symbol": "USDD"
      }
    }
  ]
}
```

### Compliance Hook Endpoints

| Method | Endpoint | Description | Required Role |
| ------ | -------- | ----------- | ------------- |
| `GET` | `/compliance/hooks` | List available compliance hook templates | `COMPLIANCE_OFFICER` |
| `GET` | `/compliance/hooks/{address}` | Get compliance hook details | `COMPLIANCE_OFFICER` |
| `POST` | `/compliance/hooks/validate` | Validate compliance hook address before token creation | `OPERATOR` |

**Note:** Compliance hooks are specified during token creation. Post-creation hook management is done directly on-chain via the token's `setComplianceHook()` function.

### Tenant Management Endpoints

#### Tenant CRUD Operations

| Method | Endpoint | Description | Required Role |
| ------ | -------- | ----------- | ------------- |
| `GET` | `/tenants` | List all tenants (paginated) | `SUPER_ADMIN` |
| `GET` | `/tenants/{tenantId}` | Get tenant details | `TENANT_ADMIN` |
| `POST` | `/tenants` | Create new tenant | `SUPER_ADMIN` |
| `PATCH` | `/tenants/{tenantId}` | Update tenant settings | `TENANT_ADMIN` |
| `DELETE` | `/tenants/{tenantId}` | Deactivate tenant (soft delete) | `SUPER_ADMIN` |

**Create Tenant Request:**

```json
{
  "name": "Acme Financial Services",
  "slug": "acme-financial",
  "contactEmail": "admin@acme-financial.com",
  "settings": {
    "allowedChains": [1, 137, 42161],
    "maxTokensPerMonth": 100,
    "kycRequired": true,
    "webhookUrl": "https://acme-financial.com/webhooks/tokenfactory"
  },
  "billing": {
    "plan": "enterprise",
    "billingEmail": "billing@acme-financial.com"
  }
}
```

**Create Tenant Response (201 Created):**

```json
{
  "tenantId": "tenant_01HQXYZ789012345",
  "name": "Acme Financial Services",
  "slug": "acme-financial",
  "status": "active",
  "contactEmail": "admin@acme-financial.com",
  "settings": {
    "allowedChains": [1, 137, 42161],
    "maxTokensPerMonth": 100,
    "kycRequired": true,
    "webhookUrl": "https://acme-financial.com/webhooks/tokenfactory"
  },
  "billing": {
    "plan": "enterprise",
    "billingEmail": "billing@acme-financial.com"
  },
  "createdAt": "2024-02-05T10:00:00Z",
  "updatedAt": "2024-02-05T10:00:00Z"
}
```

**Get Tenant Response:**

```json
{
  "tenantId": "tenant_01HQXYZ789012345",
  "name": "Acme Financial Services",
  "slug": "acme-financial",
  "status": "active",
  "contactEmail": "admin@acme-financial.com",
  "settings": {
    "allowedChains": [1, 137, 42161],
    "maxTokensPerMonth": 100,
    "kycRequired": true,
    "webhookUrl": "https://acme-financial.com/webhooks/tokenfactory"
  },
  "stats": {
    "totalTokensCreated": 42,
    "tokensThisMonth": 7,
    "activeUsers": 5,
    "activeApiKeys": 3
  },
  "createdAt": "2024-02-05T10:00:00Z",
  "updatedAt": "2024-02-10T14:30:00Z"
}
```

#### Tenant User Management

| Method | Endpoint | Description | Required Role |
| ------ | -------- | ----------- | ------------- |
| `GET` | `/tenants/{tenantId}/users` | List tenant users | `TENANT_ADMIN` |
| `GET` | `/tenants/{tenantId}/users/{userId}` | Get user details | `TENANT_ADMIN` |
| `POST` | `/tenants/{tenantId}/users` | Invite user to tenant | `TENANT_ADMIN` |
| `PATCH` | `/tenants/{tenantId}/users/{userId}` | Update user role | `TENANT_ADMIN` |
| `DELETE` | `/tenants/{tenantId}/users/{userId}` | Remove user from tenant | `TENANT_ADMIN` |

**Invite User Request:**

```json
{
  "email": "operator@acme-financial.com",
  "role": "OPERATOR",
  "permissions": ["factory:create-token", "factory:read", "registry:read"],
  "expiresAt": "2025-02-05T00:00:00Z"
}
```

**Invite User Response (201 Created):**

```json
{
  "userId": "user_01HQABC123456789",
  "email": "operator@acme-financial.com",
  "status": "pending_invitation",
  "role": "OPERATOR",
  "permissions": ["factory:create-token", "factory:read", "registry:read"],
  "invitedAt": "2024-02-05T10:00:00Z",
  "expiresAt": "2025-02-05T00:00:00Z"
}
```

**List Users Response:**

```json
{
  "users": [
    {
      "userId": "user_01HQABC123456789",
      "email": "admin@acme-financial.com",
      "name": "John Admin",
      "status": "active",
      "role": "TENANT_ADMIN",
      "lastLoginAt": "2024-02-05T09:00:00Z",
      "createdAt": "2024-01-15T10:00:00Z"
    },
    {
      "userId": "user_01HQDEF456789012",
      "email": "operator@acme-financial.com",
      "name": "Jane Operator",
      "status": "active",
      "role": "OPERATOR",
      "lastLoginAt": "2024-02-04T16:30:00Z",
      "createdAt": "2024-01-20T14:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 2,
    "hasMore": false
  }
}
```

#### Tenant API Key Management

| Method | Endpoint | Description | Required Role |
| ------ | -------- | ----------- | ------------- |
| `GET` | `/tenants/{tenantId}/api-keys` | List tenant API keys | `TENANT_ADMIN` |
| `POST` | `/tenants/{tenantId}/api-keys` | Create new API key | `TENANT_ADMIN` |
| `PATCH` | `/tenants/{tenantId}/api-keys/{keyId}` | Update API key (name, permissions) | `TENANT_ADMIN` |
| `DELETE` | `/tenants/{tenantId}/api-keys/{keyId}` | Revoke API key | `TENANT_ADMIN` |

**Create API Key Request:**

```json
{
  "name": "Production Token Creator",
  "permissions": ["factory:create-token", "factory:read", "transactions:submit"],
  "allowedIps": ["203.0.113.0/24", "198.51.100.50"],
  "rateLimit": {
    "requestsPerMinute": 60,
    "requestsPerDay": 1000
  },
  "expiresAt": "2025-02-05T00:00:00Z"
}
```

**Create API Key Response (201 Created):**

```json
{
  "keyId": "key_01HQXYZ567890123",
  "name": "Production Token Creator",
  "apiKey": "tf_live_a1b2c3d4e5f6g7h8i9j0...",
  "apiKeyPrefix": "tf_live_a1b2",
  "permissions": ["factory:create-token", "factory:read", "transactions:submit"],
  "allowedIps": ["203.0.113.0/24", "198.51.100.50"],
  "rateLimit": {
    "requestsPerMinute": 60,
    "requestsPerDay": 1000
  },
  "createdAt": "2024-02-05T10:00:00Z",
  "expiresAt": "2025-02-05T00:00:00Z"
}
```

**Note:** The full `apiKey` value is only returned once at creation time. Store it securely; it cannot be retrieved again. Only the `apiKeyPrefix` is shown in subsequent queries for identification.

**List API Keys Response:**

```json
{
  "apiKeys": [
    {
      "keyId": "key_01HQXYZ567890123",
      "name": "Production Token Creator",
      "apiKeyPrefix": "tf_live_a1b2",
      "permissions": ["factory:create-token", "factory:read", "transactions:submit"],
      "status": "active",
      "lastUsedAt": "2024-02-05T09:45:00Z",
      "createdAt": "2024-01-15T10:00:00Z",
      "expiresAt": "2025-02-05T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "hasMore": false
  }
}
```

### Health & Utility Endpoints

| Method | Endpoint | Description | Auth Required |
| ------ | -------- | ----------- | ------------- |
| `GET` | `/health` | Service health check | No |
| `GET` | `/health/ready` | Readiness probe | No |
| `GET` | `/chains` | List supported chains and registry addresses | No |
| `GET` | `/chains/{chainId}/gas-price` | Current gas price for token creation | No |

### Error Response Format

All error responses follow RFC 7807 (Problem Details):

```json
{
  "type": "https://api.dewiz.xyz/errors/invalid-token-params",
  "title": "Invalid Token Parameters",
  "status": 400,
  "detail": "Token symbol 'USDD' exceeds maximum length of 11 characters",
  "instance": "/v1/tokens/erc20",
  "traceId": "trace-abc123",
  "errors": [
    {
      "field": "symbol",
      "code": "INVALID_LENGTH",
      "message": "Symbol must be between 1 and 11 characters"
    }
  ]
}
```

### HTTP Status Codes

| Code | Usage |
| ---- | ----- |
| `200 OK` | Successful read operations |
| `201 Created` | Resource created (sync operations) |
| `202 Accepted` | Transaction submitted for processing |
| `400 Bad Request` | Validation error, malformed request |
| `401 Unauthorized` | Missing or invalid authentication |
| `403 Forbidden` | Insufficient permissions |
| `404 Not Found` | Resource not found |
| `409 Conflict` | Duplicate transaction, nonce conflict |
| `422 Unprocessable Entity` | Business logic error (e.g., invalid compliance hook address) |
| `429 Too Many Requests` | Rate limit exceeded |
| `500 Internal Server Error` | Unexpected server error |
| `502 Bad Gateway` | Blockchain node unavailable |
| `503 Service Unavailable` | Service overloaded |

---

## Deployment Approach

### Deployment Order

1. **Deploy TokenFactoryRegistry**

    ```solidity
    TokenFactoryRegistry registry = new TokenFactoryRegistry();
    ```

2. **Deploy Individual Factories**

    ```solidity
    ERC20Factory erc20Factory = new ERC20Factory();
    ERC721Factory erc721Factory = new ERC721Factory();
    ERC1155Factory erc1155Factory = new ERC1155Factory();
    ```

3. **Register Factories with Registry**

    ```solidity
    registry.registerAllFactories(
        address(erc20Factory),
        address(erc721Factory),
        address(erc1155Factory)
    );
    ```

### Deployment Script

```bash
# Local deployment (Anvil)
anvil # In separate terminal
forge script script/DeployTokenFactory.s.sol:DeployTokenFactoryLocal \
    --rpc-url http://localhost:8545 \
    --broadcast

# Testnet/Mainnet deployment
export PRIVATE_KEY=<deployer-private-key>
forge script script/DeployTokenFactory.s.sol:DeployTokenFactory \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify
```

### Multi-Chain Deployment Strategy

| Network          | Type       | Use Case                             |
| ---------------- | ---------- | ------------------------------------ |
| Ethereum Mainnet | L1         | High-value institutional tokens      |
| Polygon          | L2         | High-throughput, low-cost operations |
| Arbitrum         | L2         | DeFi integrations                    |
| Optimism         | L2         | Optimistic rollup benefits           |
| Private Networks | Enterprise | Permissioned deployments             |

### Post-Deployment Verification

1. Verify all contracts on block explorer
2. Confirm factory registration via `registry.getAllFactories()`
3. Test token creation with `createSimple*` functions
4. Validate compliance hook integration (if deployed)

## Attack Vectors & Edge Cases

### Smart Contract Attack Vectors

| Vector                       | Risk   | Mitigation                                                        |
| ---------------------------- | ------ | ----------------------------------------------------------------- |
| **Compliance Hook Bypass**   | Medium | Hooks are mandatory when set; cannot be bypassed via direct calls |
| **Role Privilege Escalation**| Low    | OpenZeppelin AccessControl with explicit role grants              |
| **Reentrancy**               | Low    | State changes before external calls; compliance hooks are trusted |
| **Factory Impersonation**    | Low    | `isTokenFromFactory()` validates origin                           |
| **Malicious Compliance Hook**| Medium | Only DEFAULT_ADMIN_ROLE can set; hook should be audited           |
| **Pause Bypass**             | Low    | Pausable modifier on all transfer functions                       |
| **Supply Manipulation**      | Low    | Immutable `isMintable` flag; MINTER_ROLE required                 |

### REST API Attack Vectors (OWASP-Aligned)

| Vector | OWASP ID | Risk | Mitigation |
| ------ | -------- | ---- | ---------- |
| **Token/Tenant Confusion** | API1 | Critical | Object-level authorization on every endpoint; tenant isolation in database |
| **JWT Token Theft** | API2 | Critical | Short-lived tokens (15 min), secure httpOnly cookies, refresh token rotation |
| **Credential Stuffing** | API2 | High | Account lockout, CAPTCHA, anomaly detection, breach password checks |
| **Mass Assignment** | API3 | High | Explicit DTO allowlists; never bind request directly to models |
| **Excessive Data Exposure** | API3 | Medium | Role-based response projection; sensitive fields stripped for non-admins |
| **API Key Leakage** | API2 | High | Keys hashed in DB, displayed once at creation, rotation capability |
| **Rate Limit Bypass** | API4 | Medium | Per-key and per-IP limits, distributed rate limiting via Redis |
| **Batch Bomb** | API4 | Medium | Maximum batch size (100 items), pagination enforced |
| **Privilege Escalation** | API5 | Critical | RBAC on all endpoints, admin paths separated, audit logging |
| **Transaction Replay** | API6 | High | Unique txId per transaction, idempotency keys, nonce verification |
| **Webhook SSRF** | API7 | High | Webhook URL allowlist, private IP blocking, DNS rebinding protection |
| **Debug Endpoint Exposure** | API8 | Medium | No debug routes in production, environment-based feature flags |
| **Deprecated API Abuse** | API9 | Low | Versioned APIs, deprecation warnings, sunset headers |
| **RPC Node Poisoning** | API10 | Medium | Multiple RPC providers, response validation, circuit breakers |

### API-Specific Edge Cases

1. **Nonce Gap**: If a token creation transaction fails, subsequent transactions may queue; automatic gap-filling required
2. **Gas Price Spike**: Token creation transaction stuck in mempool; speedup endpoint allows gas price bumping
3. **Chain Reorganization**: Confirmed token creation reverted; webhook notifications for reorg events
4. **Unsigned Transaction Expiry**: Built transactions expire after 5 minutes to prevent stale nonces
5. **Multi-Tenant Token Access**: Token creation records visible only to creating tenant unless explicitly shared
6. **Concurrent Token Creation**: Multiple token creations by same address; nonce management prevents conflicts
7. **API Key Compromise**: Immediate revocation via admin panel; all active sessions invalidated

### Smart Contract Edge Cases

1. **Zero Initial Supply**: Valid for ERC20; no tokens minted at creation
2. **Zero Address Initial Holder**: No initial supply minted even if `initialSupply > 0`
3. **Compliance Hook Revert**: Entire transaction reverts; no partial state changes
4. **Batch Operation Length Mismatch** (ERC1155): Reverts with `ArrayLengthMismatch()`
5. **Minting When Disabled**: Reverts with `MintingDisabled()` even if caller has MINTER_ROLE
6. **Royalty Above 100%**: OpenZeppelin ERC2981 enforces maximum of 10000 basis points
7. **Token Type Creation** (ERC1155): Auto-increments from 0; first `createTokenType()` creates ID 0

### Race Condition Scenarios

- **Factory Registration During Token Creation**: New factory applies immediately; in-flight creations use previously registered factory
- **API Rate Limit During Token Creation**: Creation may fail mid-transaction; idempotency keys ensure no duplicate tokens
- **Multiple Token Creations Same Block**: Nonce collision possible; sequential nonce management prevents conflicts

## Assumptions

### Business Constraints

**Smart Contract:**

1. **Single Compliance Hook**: Each token has at most one compliance hook; multiple compliance requirements must be aggregated
2. **Immutable Core Features**: `mintable`, `burnable`, `pausable` cannot be changed after deployment
3. **Creator is Initial Admin**: Token creator automatically receives DEFAULT_ADMIN_ROLE
4. **No Token Migration**: Tokens cannot be upgraded; new deployment required for contract changes

**REST API:**

1. **Multi-Tenant Architecture**: Each tenant operates in isolation; cross-tenant access explicitly denied
2. **Client-Side Signing**: API never holds private keys; all token creation transactions signed by client wallets/HSMs
3. **Asynchronous Transactions**: Token creation returns immediately; polling/webhooks for confirmation status
4. **KYC Prerequisite**: Token creation requires verified KYC status on the tenant account
5. **Factory-Only Scope**: API handles token creation only; post-creation operations (mint, burn, transfer) are out of scope

### Technical Constraints

**Smart Contract:**

1. **Solidity Version**: ^0.8.24 required for all contracts
2. **OpenZeppelin v5.5**: Specific version required for compatibility
3. **Via IR Compilation**: Required for complex contracts (foundry.toml setting)
4. **Gas Limits**: Batch operations (ERC1155) may hit block gas limits with large arrays

**REST API:**

1. **Rust 1.75+ (2024 Edition)**: Required for async traits stabilization and latest language features
2. **Tokio Runtime**: Multi-threaded async runtime with work-stealing scheduler
3. **PostgreSQL 16+**: Required for JSON functions and performance; SQLx for compile-time query checking
4. **Redis 7+**: Required for streams and improved clustering; redis-rs with connection pooling
5. **TLS 1.3**: Minimum TLS version for all API communications; rustls preferred over OpenSSL
6. **IPv4/IPv6 Dual-Stack**: API must support both protocols

### Operational Assumptions

**Smart Contract:**

1. **Trusted Compliance Hooks**: Hook contracts should be audited; malicious hooks can block all operations
2. **Key Management**: Factory deployers must secure private keys; compromised keys can register malicious factories

**REST API:**

1. **High Availability**: Minimum 3 API replicas across availability zones
2. **Database Backups**: Point-in-time recovery enabled; 30-day retention
3. **RPC Redundancy**: Multiple blockchain node providers; automatic failover
4. **Monitoring Stack**: Prometheus + Grafana + PagerDuty for alerting
5. **Log Retention**: 90-day retention for audit logs; immutable storage
6. **Disaster Recovery**: RTO < 4 hours, RPO < 1 hour for critical systems

### Security Assumptions

**Smart Contract:**

1. **OpenZeppelin Contracts**: Assumed audited and secure
2. **EVM Behavior**: Standard EVM semantics; no chain-specific exploits considered
3. **Block Timestamp**: Not used for security-critical decisions
4. **External Calls**: Only to trusted compliance hooks; no arbitrary external calls

**REST API:**

1. **Identity Provider Trust**: Keycloak/Auth0 assumed secure; regular security updates applied
2. **Network Isolation**: API servers in private subnets; load balancer in public subnet
3. **Secret Management**: All secrets in HashiCorp Vault; never in environment variables
4. **Dependency Scanning**: Automated CVE scanning in CI/CD; critical vulnerabilities block deployment
5. **Penetration Testing**: Annual third-party pentests; quarterly automated scans
6. **WAF Protection**: Web Application Firewall with OWASP CRS ruleset

---

## Changelog

- [2025-02-05] Initial technical requirements document created
- [2025-02-05] Added REST API solution design with SOLID architecture
- [2025-02-05] Added OWASP API Security Top 10 (2023) compliance matrix
- [2025-02-05] Added REST API endpoints specification (OpenAPI-ready)
- [2025-02-05] Added API-specific attack vectors and edge cases
- [2025-02-05] Updated assumptions with API operational requirements
- [2025-02-05] **Scope Clarification**: Removed wallet management and token operations (mint/burn/transfer) from API scope; API focuses on factory token creation only
- [2025-02-05] **Tech Stack Update**: Added Hexagonal Architecture with detailed project structure and design patterns (using Rust as reference)
- [2025-02-05] **Multi-Tenancy Documentation**: Added comprehensive explanation of tenant concept, rationale for multi-tenant architecture, and tenant isolation mechanisms
- [2025-02-05] **Tenant Management Endpoints**: Added REST API endpoints for tenant CRUD operations, user management, and API key management
- [2025-02-05] **Language Flexibility**: Clarified that REST API can be implemented in JavaScript/TypeScript or Go; Rust is provided as a reference implementation only
