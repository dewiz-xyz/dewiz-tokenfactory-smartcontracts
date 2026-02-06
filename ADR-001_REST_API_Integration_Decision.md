# ARCHITECTURE DECISION RECORD

## ADR-001: REST API as Integration Interface

### TokenFactory ↔ Tokengentic Integration**

| Field | Value |
|-------|-------|
| **Document ID** | ADR-001 |
| **Status** | ACCEPTED |
| **Date** | 2025-02-06 |
| **Decision Maker** | Amusing |
| **Author** | 0xCentur1on (Senior Blockchain Engineer, Dewiz) |
| **Reviewers** | Oddaf, Ephy, Tlay Team |
| **Stakeholders** | Dewiz Blockchain, Tlay Team (Tokengentic) |
| **Supersedes** | N/A (Initial Decision) |

**Classification:** Internal – Dewiz Blockchain & Tokengentic Tlay Team

---

## Table of Contents

- [1. Context](#1-context)
- [2. Decision](#2-decision)
- [3. Options Considered](#3-options-considered)
- [4. Comparison Matrix](#4-comparison-matrix)
- [5. Rationale](#5-rationale)
- [6. Detailed Rejection: Web3.py Direct Integration](#6-detailed-rejection-web3py-direct-integration)
- [7. Detailed Rejection: MCP Server](#7-detailed-rejection-mcp-server)
- [8. Architectural Alignment](#8-architectural-alignment)
- [9. Responsibilities](#9-responsibilities)
- [10. Consequences](#10-consequences)
- [11. Future Considerations](#11-future-considerations)
- [12. Related Documents](#12-related-documents)
- [Approval](#approval)

---

## 1. Context

Dewiz Blockchain is building the Token Factory platform: an institutional-grade smart contract system for creating compliant ERC-20, ERC-721, and ERC-1155 tokens with built-in regulatory hooks (OFAC, KYC/AML). The smart contracts are deployed across multiple EVM-compatible chains (Ethereum L1, Polygon, Arbitrum, Optimism, private networks).

Tlay Team is building Tokengentic: an AI Agent platform (Python/Supabase) that enables automated token deployment through conversational interfaces. Tokengentic agents need to create tokens on behalf of institutional clients without direct blockchain interaction.

The two teams operate as independent organizations with different technology stacks, release cycles, and operational responsibilities. An integration mechanism must be selected to connect Tokengentic AI Agents to TokenFactory smart contracts.

---

## 2. Decision

We will use a **REST API** as the single integration interface between TokenFactory smart contracts and Tokengentic AI Agents.

**Dewiz Blockchain** owns, develops, documents, and operates this REST API. Dewiz provides an OpenAPI 3.1 specification and integration guide so that the Tlay team and Tokengentic AI Agents can consume the API without blockchain domain knowledge.

The REST API handles token creation only. Post-creation operations (mint, burn, transfer) remain direct on-chain interactions and are out of scope.

---

## 3. Options Considered

### 3.1 Option A: Direct Web3.py Integration (Rejected)

Tokengentic AI Agents use Web3.py to interact directly with TokenFactory smart contracts via ABI + RPC.

### 3.2 Option B: MCP Server (Rejected)

Dewiz exposes TokenFactory operations via a Model Context Protocol (MCP) server. AI Agents connect as MCP clients.

### 3.3 Option C: REST API (Accepted)

Dewiz builds a REST API server (Rust/JS) that abstracts all blockchain interactions behind standard HTTP+JSON endpoints. Tokengentic consumes the API as any Web2 client would.

---

## 4. Comparison Matrix

| Criterion | Web3.py (A) | MCP Server (B) | REST API (C) |
|-----------|-------------|-----------------|--------------|
| **Team Coupling** | High – Tlay must learn Solidity ABI, gas, nonces, RPC providers | Medium – Tlay depends on MCP protocol specifics and tooling | Low – Tlay consumes standard HTTP+JSON |
| **Blockchain Expertise Required by Consumer** | Full EVM knowledge: ABI encoding, gas estimation, tx signing, nonce management, reorg handling | Partial – MCP abstracts some complexity but tool schemas still expose chain concepts | None – API abstracts all blockchain complexity behind domain endpoints |
| **Protocol Maturity** | Mature (Web3.py 6.x) | Early stage – MCP spec is evolving, limited production track record in financial systems | Industry standard – decades of production usage in financial institutions |
| **Multi-Chain Abstraction** | Tlay manages per-chain RPC URLs, ABIs, and gas strategies | Possible but requires custom MCP tool definitions per chain | Single API with chainId parameter; Dewiz handles all chain routing internally |
| **Security Boundary** | No boundary – Tlay holds RPC access and private key proximity | MCP transport security is still maturing; no established auth patterns for financial use | Well-defined – OAuth 2.0, JWT, API keys, RBAC, tenant isolation, OWASP-aligned |
| **Nonce Management** | Tlay must implement centralized nonce tracking (Redis or equivalent) | Delegated to MCP server but error propagation model unclear | Dewiz owns nonce management end-to-end via Redis |
| **Error Handling** | Raw EVM reverts; Tlay must parse revert reasons, handle gas failures, chain reorgs | MCP error model not standardized for blockchain-specific failures | Structured RFC 7807 errors with domain-specific codes (NONCE_CONFLICT, CHAIN_UNAVAILABLE) |
| **Async Tx Lifecycle** | Tlay must implement polling/event listeners for tx confirmation | Streaming possible but no standard pattern for tx lifecycle tracking | Built-in: 202 Accepted → poll GET /transactions/{txId} → webhooks |
| **Observability** | Tlay must instrument blockchain calls independently | Limited – MCP observability tooling is nascent | Centralized: structured logging, distributed tracing, Prometheus metrics |
| **AI Agent Compatibility** | Requires custom blockchain tooling wrappers per agent framework | Native fit for LLM tool-calling but tightly couples agent to MCP client SDK | Universal – any HTTP client works; OpenAPI spec enables auto-generated SDKs |
| **Documentation Standard** | Solidity NatSpec + ABI JSON; no standard integration guide format | MCP tool schema; limited documentation tooling | OpenAPI 3.1 + Swagger UI + integration guide; industry-standard for cross-team APIs |
| **Multi-Tenancy** | Not applicable – each caller manages own identity | No built-in tenant model | Native: JWT tenant claims, per-tenant API keys, data isolation |
| **Regulatory Auditability** | Tlay must build own audit trail for compliance reporting | Audit logging depends on MCP server implementation | Centralized audit log with tenant context; immutable storage; compliance-ready |
| **Idempotency** | Tlay must implement idempotency keys and tx deduplication | No standard idempotency model in MCP | Built-in: unique transactionId per creation; idempotent submission endpoint |
| **Independent Deployability** | Coupled – ABI changes require Tlay redeployment | Semi-coupled – MCP tool schema changes require client updates | Decoupled – versioned API (v1/v2); backward-compatible changes; sunset headers |

---

## 5. Rationale

### 5.1 Separation of Concerns

Blockchain is Dewiz's domain. AI Agents are Tlay's domain. The REST API creates a clean boundary where each team operates within its area of expertise. Dewiz encapsulates all EVM complexity (ABI encoding, gas estimation, nonce management, multi-chain routing, reorg handling) behind HTTP endpoints. Tlay's AI Agents make standard HTTP calls without ever importing Web3.py, ethers.js, or any blockchain SDK.

### 5.2 Protocol Maturity in Financial Context

TokenFactory serves institutional clients (banks, asset managers, fintechs). REST APIs over HTTPS are the established integration standard in financial infrastructure. Security auditors, compliance teams, and enterprise architects understand REST, OAuth 2.0, and RBAC. MCP, while promising for AI-native tooling, lacks production track record in regulated financial environments and has no established security audit framework.

### 5.3 Operational Independence

With REST, each team deploys, scales, and monitors independently. Dewiz can upgrade smart contracts, change RPC providers, add new chains, or optimize gas strategies without any change on Tlay's side as long as the API contract holds. With Web3.py, every ABI change would cascade to Tlay. With MCP, tool schema changes would require synchronized releases.

### 5.4 Security Enforcement

The REST API centralizes security: tenant isolation, RBAC, rate limiting, API key management, audit logging, and OWASP compliance. With Web3.py, security boundaries blur because Tlay holds direct RPC access and must implement its own authorization layer. The REST API ensures that no Tokengentic agent can bypass tenant isolation, exceed rate limits, or operate without proper authentication.

### 5.5 Nonce and Transaction Lifecycle Ownership

Centralized nonce management is the single hardest operational problem in multi-tenant blockchain APIs. Nonce gaps, concurrent submissions, and stuck transactions require specialized handling (Redis-backed nonce locks, gap-filling, speedup/cancel). Pushing this to Tlay via Web3.py would create a second nonce management implementation that Dewiz cannot control or debug. The REST API keeps this critical state machine under Dewiz's operational umbrella.

### 5.6 AI Agent Universality

REST APIs are framework-agnostic. Whether Tlay uses LangChain, CrewAI, AutoGen, or a custom agent framework, the integration is the same: HTTP requests. An OpenAPI 3.1 spec enables auto-generation of Python clients. MCP would lock Tlay into MCP-compatible agent frameworks and SDK versions, creating unnecessary coupling.

---

## 6. Detailed Rejection: Web3.py Direct Integration

| Concern | Impact |
|---------|--------|
| **ABI Version Coupling** | Every smart contract upgrade requires Tlay to update ABI artifacts and redeploy. In a multi-contract system (Registry + 3 Factories + N token implementations), this creates a fragile dependency chain. |
| **Multi-Chain Complexity Leak** | Tlay would need to manage RPC endpoints, chain-specific gas strategies (EIP-1559 vs legacy), and different confirmation requirements per chain. This is Dewiz's domain, not Tlay's. |
| **Nonce Management Duplication** | Two independent nonce management systems (Dewiz for its own operations, Tlay for agent-initiated transactions) create coordination problems and increase the risk of nonce collisions. |
| **No Tenant Isolation** | Web3.py calls are anonymous at the contract level. There is no native mechanism to enforce per-tenant quotas, rate limits, or audit trails. Tlay would need to build this infrastructure from scratch. |
| **Security Surface Expansion** | Direct RPC access from Tlay's infrastructure means RPC credentials, private key proximity, and blockchain error handling all become Tlay's security responsibility. Any vulnerability in Tlay's Web3.py integration directly exposes on-chain assets. |
| **Compliance Audit Gap** | Regulatory reporting requires a centralized, immutable audit trail of all token creation operations. Distributed Web3.py calls from multiple AI Agent instances make audit aggregation significantly harder. |

---

## 7. Detailed Rejection: MCP Server

| Concern | Impact |
|---------|--------|
| **Protocol Maturity** | MCP is an emerging protocol without established production usage in regulated financial systems. No security audit frameworks, no compliance certifications, no enterprise reference architectures exist yet. |
| **Transport Security** | MCP's transport layer security model is still evolving. Financial-grade authentication (OAuth 2.0, mTLS, API key rotation) and multi-tenant authorization are not first-class MCP concerns. |
| **Error Model Limitations** | MCP's error propagation model is not designed for blockchain-specific failure modes: revert reasons, gas exhaustion, nonce conflicts, chain reorganizations, mempool congestion. These require structured, domain-specific error taxonomy. |
| **Tooling and Observability** | Production-grade observability (distributed tracing, structured logging, Prometheus metrics) for MCP servers is nascent. Financial compliance requires detailed request/response logging with tenant context. |
| **Framework Lock-In** | MCP adoption requires Tlay's AI Agent framework to support MCP client SDKs. If Tlay changes agent frameworks, the MCP integration must be rewritten. REST is universally supported. |
| **Async Transaction Lifecycle** | Token creation on blockchain is inherently asynchronous (submit → mempool → confirmation). MCP's request/response model does not natively support long-running transaction tracking with status polling, webhooks, and speedup/cancel operations. |
| **Future Optionality** | MCP is not permanently rejected. Once the protocol matures and gains financial-sector adoption, an MCP adapter can be layered on top of the REST API as an additional driving adapter in the hexagonal architecture, without replacing the REST interface. |

---

## 8. Architectural Alignment

The REST API decision aligns with the hexagonal (ports & adapters) architecture defined in the TokenFactory technical requirements:

| Architecture Layer | REST API Role |
|--------------------|---------------|
| **Driving Adapter (Primary)** | Axum HTTP handlers receive requests from Tokengentic AI Agents and any future Web2 consumer (web apps, mobile, backend services). |
| **Application Layer (Ports)** | TokenCreatorPort, RegistryQueryPort, TransactionPort traits define the contract. The REST API is one of potentially many driving adapters. |
| **Domain Layer** | Pure business logic, untouched by integration choice. Token creation rules, validation, and domain events remain isolated. |
| **Driven Adapters (Secondary)** | EthereumAdapter, PostgresRepository, RedisCache handle blockchain and persistence. The REST API never leaks these implementation details. |
| **Future MCP Adapter** | If MCP matures, it becomes another driving adapter calling the same application ports. Zero changes to domain or infrastructure layers. |

---

## 9. Responsibilities

| Dewiz Blockchain (Token Factory) | Tlay Team / Supabase (Tokengentic) |
|----------------------------------|------------------------------------|
| Design and develop the REST API | Consume the REST API from AI Agent workflows |
| Produce OpenAPI 3.1 specification | Use Supabase to consume the APIs or Auto-generate Python client from OpenAPI spec |
| Implement OAuth 2.0 / JWT / API Key authentication | Authenticate using provided credentials and API keys |
| Manage nonce lifecycle, gas estimation, and tx broadcasting | Submit token creation requests; poll or receive webhooks for status |
| Enforce tenant isolation and RBAC | Operate within assigned tenant scope and permissions |
| Handle multi-chain routing and RPC failover | Specify chainId in requests; no chain-specific logic needed |
| Provide staging environment for integration testing | Execute integration tests against staging API |
| Publish API changelog and deprecation notices | Monitor deprecation headers and migrate within sunset window |

---

## 10. Consequences

### 10.1 Positive

- Clear team boundary: Dewiz owns blockchain, Tlay owns AI agents. No cross-domain skill requirements.
- Tlay can start integration development immediately using the OpenAPI spec, before the API is fully implemented (contract-first development).
- Centralized security, observability, and audit logging under Dewiz's operational control.
- Multi-consumer ready: the same API serves Tokengentic, future web dashboards, mobile apps, and third-party integrations.
- Independent scaling: API tier scales horizontally without affecting smart contract deployment or AI agent infrastructure.

### 10.2 Negative (Accepted Trade-offs)

- Additional latency: HTTP round-trip adds ~10-50ms compared to direct RPC calls. Acceptable for token creation (which takes 12-15 seconds for on-chain confirmation anyway).
- API becomes a single point of failure for Tokengentic. Mitigated by 99.9% SLA, horizontal scaling, and multi-AZ deployment.
- Schema evolution requires API versioning discipline. Mitigated by OpenAPI spec as source of truth, sunset headers, and deprecation policy.

---

## 11. Future Considerations

- **MCP Adapter:** When the MCP protocol reaches production maturity in financial contexts, an MCP driving adapter can be added to the hexagonal architecture alongside REST. This requires zero changes to domain or infrastructure layers.
- **GraphQL:** If Tokengentic or future consumers need flexible query patterns (e.g., fetching tokens with specific field subsets), a GraphQL adapter can be added as another driving adapter.
- **Webhook Event Catalog:** A formal webhook specification (event types, payload schemas, retry policy, HMAC signature verification) should be defined before production launch.
- **SDK Generation:** Automated Python, TypeScript, Rust and Go client SDK generation from the OpenAPI spec should be part of the CI/CD pipeline.

---

## 12. Related Documents

| Document | Description |
|----------|-------------|
| **Dewiz Token Factory – Technical Requirements** | Full technical specification including smart contract architecture, REST API design, OWASP compliance matrix, and deployment strategy. |
| **TokenFactory – OpenAPI 3.1 Specification** | Machine-readable API contract (to be delivered by Dewiz before development starts). |
| **TokenFactory – Integration Guide** | Step-by-step guide for Tlay team covering authentication, token creation flow, error handling, and webhook setup. |

---

## Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| **Decision Maker** | Amusing | | |
| **Technical Lead (Dewiz)** | 0xCentur1on | | |
| **Technical Lead (Tokengentic)** | Tlay | | |
| **Security Reviewer** | Oddaf | | |
