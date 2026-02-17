# HAVEN Protocol Specifications

**Version**: 2.0.0
**Date**: February 13, 2026

This directory contains formal RFC-style specifications for the HAVEN Protocol.

## What is HAVEN?

HAVEN (Health Asset Value & Exchange Network) is a **value exchange protocol** for patient-controlled health data. It defines how health data is referenced, consented, audited, and valued—without prescribing storage, computation, or payment mechanisms.

## Protocol Scope

### HAVEN Specifies

- Data structures for health assets, consent, provenance, and contributions
- Consent verification semantics
- Provenance chain construction and verification
- Value calculation formulas (reference implementation)
- Exchange format for interoperability

### HAVEN Does NOT Specify (Implementation Choice)

- Data storage mechanism
- Encryption scheme
- Key management / recovery
- Identity verification
- Computation model
- Payment / compensation mechanism

## Specification Documents

### Core Specifications

| Document | Primitive | Status | Description |
|----------|-----------|--------|-------------|
| [001-health-asset.md](./001-health-asset.md) | Health Asset | Draft | Governed data reference with quality scoring |
| [002-consent-protocol.md](./002-consent-protocol.md) | Consent Protocol | Draft | Programmable authorization |
| [003-provenance-record.md](./003-provenance-record.md) | Provenance Record | Draft | Append-only audit trail |
| [004-contribution-model.md](./004-contribution-model.md) | Contribution Model | Draft | Value quantification |
| [006-exchange-bundle.md](./006-exchange-bundle.md) | Exchange Bundle | Draft | Interoperability format |

### Optional Extensions

| Document | Extension | Status | Description |
|----------|-----------|--------|-------------|
| [005-psdl-integration.md](./005-psdl-integration.md) | PSDL Integration | Draft | Declarative policy language (optional) |

## Document Structure

Each specification follows this structure:

1. **Overview** - Purpose and scope
2. **Data Model** - Type definitions, field constraints, invariants
3. **Operations** - API contracts, pre/post conditions
4. **Cryptographic Requirements** - Hashing, signing, verification
5. **Serialization** - Canonical form, wire format
6. **Conformance** - MUST/SHOULD/MAY requirements (RFC 2119)
7. **Security Considerations** - Threat model and mitigations
8. **Examples** - Concrete usage examples
9. **Test Vectors** - Reference inputs/outputs for conformance testing

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in these documents are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Design Principles

1. **Protocol, not platform** - HAVEN specifies data structures and semantics only
2. **Built on standards** - FHIR R4, OMOP CDM for data; Ed25519/SHA-256 for crypto
3. **Value exchange focus** - How to quantify and track value, not how to distribute it
4. **Economics are open** - Formula specified, payment mechanisms left to community
5. **Minimal and deterministic** - Clear semantics, predictable behavior

## Related Resources

- [Whitepaper](../docs/WHITEPAPER.md) - Protocol overview and design rationale
- [Implementation Guide](../docs/implementation-guide.md) - How to implement HAVEN
- [TypeSpec Definitions](../typespec/) - Machine-readable type definitions (source of truth)
- [Test Vectors](../test-vectors/) - Conformance test data
- [PSDL Repository](https://github.com/Chesterguan/PSDL) - Patient Scenario Definition Language (optional)

## Versioning

Specifications use semantic versioning:
- **Major**: Breaking changes to data models or semantics
- **Minor**: Backwards-compatible additions
- **Patch**: Clarifications, typo fixes, examples

Current version: **2.0.0**

## License

These specifications are released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
