<p align="center">
  <img src="assets/logo.jpeg" alt="HAVEN Logo" width="200"/>
</p>

# HAVEN Protocol

**Health Asset Value & Exchange Network**

An independent, open protocol for patient-controlled health data. HAVEN specifies how health data is referenced, consented to, audited, and valued — without prescribing storage, computation, or payment mechanisms.

**License**: [CC BY 4.0](LICENSE) &nbsp;·&nbsp; **Status**: v2.0 Draft &nbsp;·&nbsp; **Not a company. Not a product.**

---

## The problem

Every blood test and clinical note you generate becomes training data for AI systems you'll never see. You can't audit who accessed your records. You can't set conditions on how your data is used. You don't share in the value your data creates.

This isn't a policy failure — it's an infrastructure failure. No standard protocol exists that ties governance to data. HAVEN is that protocol.

---

## Four primitives

| Primitive | What it does |
|-----------|-------------|
| **[Health Asset](spec/001-health-asset.md)** | Content-addressed (SHA-256) reference to governed clinical data. Consent reference is structurally required — no ungoverned assets. |
| **[Consent Protocol](spec/002-consent-protocol.md)** | Machine-executable, granular, immediately revocable authorization. Closed-world: silence = denial. |
| **[Provenance Record](spec/003-provenance-record.md)** | Append-only, hash-chained, Ed25519-signed audit trail. Every access logged. Tamper-evident. |
| **[Contribution Model](spec/004-contribution-model.md)** | 3-gate quality protocol + tier-weighted value score. Measures what patient data contributes to a study. |

HAVEN builds on FHIR R4 and OMOP CDM — standards already mandated or widely adopted. It does **not** specify storage, encryption, key management, identity, or payment rails.

---

## Documentation

| Document | Description |
|----------|-------------|
| [Whitepaper (English)](docs/WHITEPAPER.md) | Protocol overview, design rationale, full references |
| [Whitepaper (中文)](docs/WHITEPAPER_ZH.md) | 协议规范中文版 |
| [Whitepaper (Français)](docs/WHITEPAPER_FR.md) | Spécification du protocole |
| [Implementation Guide](docs/implementation-guide.md) | How to build HAVEN-compliant systems (with code) |
| [Formal Specifications](spec/) | RFC-style specs — MUST/SHOULD/MAY requirements |
| [Examples](examples/) | Annotated examples for each primitive |
| [Test Vectors](test-vectors/) | Conformance test data (valid + invalid cases) |

---

## Contributing

HAVEN is an independent open protocol. There is no company. The spec improves through use, critique, and real-world implementation experience.

**Most valuable right now:**
- Adversarial spec review — find ambiguities, edge cases, contradictions
- Implementation reports — try to build something; tell us where the spec failed you
- Test vector additions — especially boundary conditions and multi-primitive scenarios

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute effectively, and [ROADMAP.md](ROADMAP.md) for what's open and what's planned.

---

## Related projects

- **[PSDL](https://github.com/Chesterguan/PSDL)** — Patient Scenario Definition Language. Declarative policy language for HAVEN consent and clinical scenarios. Recommended but not required.

---

## Contact

- **Author**: Chester Guan
- **Email**: chesterfield199512@gmail.com
- **GitHub**: [github.com/Chesterguan](https://github.com/Chesterguan)

---

*HAVEN Protocol v2.0 | February 2026 | CC BY 4.0*
