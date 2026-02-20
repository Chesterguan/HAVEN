# HAVEN Protocol - Project Memory

**Last Updated**: February 20, 2026

## What This Is

HAVEN (Health Asset Value & Exchange Network) is a **value exchange protocol** for patient-controlled health data. It defines how health data is referenced, consented, audited, and valued—without prescribing storage, computation, or payment mechanisms.

**DOI**: [10.5281/zenodo.18701303](https://doi.org/10.5281/zenodo.18701303)

**Core positioning**: Value Exchange Protocol for Health Data (not a platform, not a complete system)

## Core Protocol (4 Primitives)

| Primitive | Purpose | Key Properties |
|-----------|---------|----------------|
| **Health Asset** | Governed data reference | Content-addressed (SHA-256), governance-embedded, quality-scored |
| **Consent Protocol** | Programmable authorization | Deterministic evaluation, immediate revocation, closed-world scope |
| **Provenance Record** | Append-only audit trail | Hash-chained, cryptographically signed (Ed25519/ECDSA), O(log n) verification |
| **Contribution Model** | Value quantification | 4 tiers, 3-gate quality protocol, reference formula |

## Key Design Decisions

1. **Protocol, not platform** - HAVEN specifies data structures and semantics only
2. **Built on standards** - FHIR R4, OMOP CDM, SMART on FHIR, OAuth 2.0
3. **Value exchange focus** - How to quantify and track value, not how to distribute it
4. **Economics are open** - Formula specified, payment mechanisms left to community/market
5. **PSDL is separate and optional** - Complementary spec, not required
6. **TypeSpec as source of truth** - Single source generates JSON Schema, OpenAPI

## What HAVEN Specifies vs. Does NOT Specify

### HAVEN Specifies
- Health Asset structure and content addressing
- Consent Attestation structure and verification algorithm
- Provenance Entry structure and hash chain
- Contribution structure and value formula (reference)
- Quality gate criteria (reference thresholds)
- Exchange Bundle format (for interoperability)

### HAVEN Does NOT Specify (Implementation Choice)
- Data storage mechanism
- Encryption scheme
- Key management / recovery
- Identity verification / proofing
- Computation model (federated, enclave, etc.)
- Payment / compensation mechanism
- Dispute resolution
- Governance

### Optional Extensions
- **PSDL**: Declarative policy language (separate repo, recommended but not required)
- Future: compliance mappings, reference SDKs

## Data Model

```
┌─────────────────────────────────────────────────────────────────┐
│ Metadata Layer (readable)                                        │
│   HealthAsset | Consent | Provenance | Contribution              │
└─────────────────────────────────────────────────────────────────┘
                              │ references
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Data Layer (encrypted, patient-controlled)                       │
│   Actual clinical data - patient holds keys                      │
│   Platform cannot read without patient authorization             │
└─────────────────────────────────────────────────────────────────┘
```

**QC and value calculation happen at ingestion time** (before encryption).

## Related Projects

- **PSDL**: https://github.com/Chesterguan/PSDL - Patient Scenario Definition Language (optional)
- **Prometheno**: Reference implementation (planned) - Patient Data Operating System

## Repository Structure

```
HAVEN/
├── README.md                   # Project overview
├── LICENSE                     # CC BY 4.0
├── CONTRIBUTING.md             # How to contribute
├── CLAUDE.md                   # This file
├── assets/
│   └── logo.jpeg               # HAVEN logo
├── docs/
│   ├── WHITEPAPER.md           # Protocol specification (narrative)
│   ├── WHITEPAPER_ZH.md        # Chinese version
│   ├── WHITEPAPER_FR.md        # French version
│   └── implementation-guide.md # How to implement HAVEN
├── spec/                       # RFC-style formal specifications
│   ├── README.md               # Spec overview
│   ├── 001-health-asset.md     # Health Asset spec
│   ├── 002-consent-protocol.md # Consent Protocol spec
│   ├── 003-provenance-record.md# Provenance Record spec
│   ├── 004-contribution-model.md# Contribution Model spec
│   ├── 005-psdl-integration.md # PSDL integration (optional extension)
│   └── 006-exchange-bundle.md  # Interoperability format
├── typespec/                   # SOURCE OF TRUTH (TypeSpec definitions)
│   ├── main.tsp                # Entry point
│   ├── package.json            # TypeSpec dependencies
│   ├── tspconfig.yaml          # Emitter configuration
│   ├── models/                 # Type definitions
│   └── operations/             # API operations
├── generated/                  # Auto-generated from TypeSpec
├── test-vectors/               # Conformance test data
└── examples/                   # Usage examples
```

## Specifications Status

| Spec | File | Status |
|------|------|--------|
| Health Asset | spec/001-health-asset.md | Draft |
| Consent Protocol | spec/002-consent-protocol.md | Draft |
| Provenance Record | spec/003-provenance-record.md | Draft |
| Contribution Model | spec/004-contribution-model.md | Draft |
| PSDL Integration | spec/005-psdl-integration.md | Draft (Optional) |
| Exchange Bundle | spec/006-exchange-bundle.md | Draft |

## Technical Stack (for implementations)

**Standards:**
- FHIR R4 (data exchange format)
- OMOP CDM 6.0 (research data model)
- SMART on FHIR (authorization pattern)
- OAuth 2.0 / OIDC (authentication)

**Cryptography:**
- SHA-256 (content addressing)
- Ed25519 or ECDSA (signatures)
- Merkle tree (provenance verification)

## Building TypeSpec

```bash
cd typespec
npm install
npm run build   # Generates to ../generated/
```

## Contact

- **Email**: chesterfield199512@gmail.com
- **Author**: Chester Guan

---

## Development Notes

### What's Done
- Whitepaper v2.0 complete (EN + ZH + FR)
- Formal specifications for all 4 primitives
- TypeSpec type definitions
- Implementation guide
- Test vectors for conformance testing
- Critical review and scope clarification
- Economics/ethics/philosophy citations added (Zuboff, Lanier, Locke, Rawls, Ostrom, Nissenbaum, etc.)

### Critical Decisions Made
1. **HAVEN = Value Exchange Protocol** (not platform, not complete system)
2. **Compute-to-data**: Compatible with, but not specified by HAVEN
3. **Economics**: Formula specified, distribution left to community
4. **PSDL**: Separate and optional
5. **Key management**: Implementation choice (acknowledged gap)

### Known Gaps (Intentional - Future Work)
- Compliance mapping (HIPAA, GDPR) - needs legal review
- Reference SDK implementation
- Formal verification of consent semantics
- Governance model for protocol evolution

### Known Gaps (Implementation Choice)
- Data storage mechanism
- Encryption scheme
- Key management / recovery
- Identity verification
- Payment rails
