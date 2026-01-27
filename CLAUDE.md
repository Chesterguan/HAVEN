# HAVEN Protocol - Project Memory

**Last Updated**: January 27, 2026

## What This Is

HAVEN (Health Asset Value & Exchange Network) is a **protocol specification** for patient-sovereign biomedical data. This is NOT a product—it's infrastructure that enables platforms to interoperate while preserving patient sovereignty.

## Core Protocol (4 Primitives)

| Primitive | Purpose | Key Properties |
|-----------|---------|----------------|
| **Health Asset** | Governed data reference | Content-addressed (SHA-256), governance-embedded, quality-scored |
| **Consent Protocol** | Programmable authorization | Deterministic evaluation, immediate revocation, closed-world scope |
| **Provenance Record** | Append-only audit trail | Hash-chained, cryptographically signed (Ed25519/ECDSA), O(log n) verification |
| **Contribution Model** | Value quantification | 4 tiers (Profile→Complex), 3-gate quality protocol (A/B/C/D classes) |

## Key Design Decisions

1. **Protocol, not platform** - HAVEN specifies what, implementations decide how
2. **Built on standards** - FHIR R4, OMOP CDM, SMART on FHIR, OAuth 2.0
3. **Compute-to-data** - Data stays in place, queries travel
4. **PSDL recommended** - Declarative policy language for consent/scenarios

## Related Projects

- **PSDL**: https://github.com/Chesterguan/PSDL - Patient Scenario Definition Language
- **Prometheno**: Reference implementation (paused) - Patient Data Operating System

## Repository Structure

```
HAVEN/
├── README.md           # Project overview
├── LICENSE             # CC BY 4.0
├── CONTRIBUTING.md     # How to contribute
├── CLAUDE.md           # This file
├── docs/
│   ├── WHITEPAPER.md   # English specification
│   └── WHITEPAPER_ZH.md # Chinese specification
└── spec/               # Future detailed specs
```

## Whitepaper Structure (v2.0)

1. Introduction
2. Why Now (Infrastructure maturity, AI urgency, Regulatory momentum)
3. Related Work (vs Apple Health, PicnicHealth, Ocean, Solid, TEFCA)
4. Problem Statement (4 structural failures)
5. Design Principles (6 principles)
6. HAVEN Core Protocol (4 primitives + PSDL)
7. Reference Architecture (4-layer, compute-to-data)
8. Foundations (FHIR, OMOP, SMART on FHIR)
9. Implementation Scope (what HAVEN specifies vs implementation choice)
10. Conclusion

**Appendices**: Glossary, Security Considerations, PSDL Reference

## Verified Data Points (Citations)

| Claim | Source |
|-------|--------|
| OMOP: 974M patient records, 544 databases, 54 countries | OHDSI 2024 |
| Clinical trials market: $84.54B (2024) → $158.41B (2033) | Grand View Research |
| 80% trials fail enrollment timelines | Fogel 2018 |
| $6,533 avg recruitment cost per patient | Sertkaya 2016 |
| Med-PaLM 2: 86.5% on MedQA | Singhal 2023 |
| HHS OCR: 22 HIPAA enforcement actions (2024), 50+ Right of Access penalties since 2019 | HHS OCR |

## Differentiation

| vs. | HAVEN Advantage |
|-----|-----------------|
| Apple Health Records | Adds consent protocol, research marketplace, contribution tracking |
| PicnicHealth | Patient controls governance, not centralized platform |
| Ocean Protocol | Health-specific (FHIR/OMOP), clinical consent semantics |
| Solid | Health data model, quality assessment, research workflow |
| TEFCA/Carequality | Patient is data controller, not institution-centric |

## Technical Stack (for implementations)

**Standards:**
- FHIR R4 (data exchange)
- OMOP CDM 6.0 (research data model)
- SMART on FHIR (authorization)
- OAuth 2.0 / OIDC (authentication)

**Cryptography:**
- SHA-256 (content addressing)
- Ed25519 or ECDSA (signatures)
- Merkle tree (provenance verification)

## Contact

- **Email**: chesterguan@prometheno.org
- **Author**: Chester Guan

---

## Development Notes

### What's Done
- Whitepaper v2.0 complete (EN + ZH)
- PSDL specification with examples
- Related Work comparison added
- All citations verified

### What's NOT in Scope (Protocol vs Implementation)
- Storage backend choice
- Compute model (centralized/federated/enclave)
- User interface
- Payment rails
- Data ingestion method
- Economic model specifics

### Future Work
- Yellow Paper (implementation guide)
- Formal verification of consent semantics
- Reference implementation
- Compliance mapping (HIPAA, GDPR)
