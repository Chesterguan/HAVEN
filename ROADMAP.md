# HAVEN Protocol Roadmap

**Last Updated**: February 18, 2026

This document describes what is done, what is actively being worked on, and what is planned. It also describes what is deliberately out of scope so contributors know where to focus.

---

## What is done (v2.0)

- Whitepaper v2.0 — full protocol narrative with citations (EN, ZH, FR)
- Formal RFC-style specifications for all four primitives
  - [001 Health Asset](spec/001-health-asset.md)
  - [002 Consent Protocol](spec/002-consent-protocol.md)
  - [003 Provenance Record](spec/003-provenance-record.md)
  - [004 Contribution Model](spec/004-contribution-model.md)
  - [005 PSDL Integration](spec/005-psdl-integration.md) (optional extension)
  - [006 Exchange Bundle](spec/006-exchange-bundle.md)
- TypeSpec definitions (source of truth for all schemas)
- Implementation guide with TypeScript reference code
- Test vectors for all primitives (valid + invalid cases)

---

## Active work (help welcome)

### Spec hardening

The specifications are in Draft status. The priority is adversarial review — finding ambiguities, edge cases, and design decisions that break under scrutiny.

Specifically:

| Area | Open questions |
|------|---------------|
| Consent semantics | Does closed-world assumption cause problems for partial re-consent flows? |
| Provenance chain | How should forks or replayed events be handled? |
| Quality gates | Are the default thresholds (0.90 / 0.75 / 0.50) correct? What is the evidence base? |
| Contribution tiers | Is the COMPLEX tier definition precise enough to be implemented consistently? |
| Exchange Bundle | What is the minimal required payload for interoperability? |

File a [Spec Feedback issue](https://github.com/Chesterguan/HAVEN/issues/new?template=spec-feedback.md) if you have input on any of these.

### Test vector expansion

Current test vectors cover basic valid/invalid cases. Needed:
- Edge cases at boundary conditions (e.g. consent expiring exactly at request time)
- Multi-primitive interaction scenarios (asset + consent + provenance together)
- Error code coverage — every specified error code should have a corresponding invalid vector

### More examples

`examples/` currently has one basic workflow. Needed:
- Per-primitive standalone examples
- A complete end-to-end research consent scenario
- PSDL policy examples

---

## Planned (not yet started)

### Conformance test harness

A runnable script (language-agnostic or multi-language) that:
1. Takes a HAVEN implementation's endpoint or library
2. Runs all test vectors against it
3. Reports pass/fail per requirement

This is the most important missing piece for enabling independent implementations to verify compliance.

**Contribution opportunity**: If you want to lead this, open an issue and let's design it together.

### Compliance mappings (non-normative)

Non-normative guidance on how HAVEN primitives relate to:
- HIPAA Privacy Rule requirements
- GDPR Article 17 (right to erasure) and Article 20 (data portability)
- 21st Century Cures Act / ONC information blocking rules

This requires legal review and is deliberately deferred. Contributors with regulatory expertise are welcome.

### Reference SDK

A minimal, reference-quality implementation in at least one language (TypeScript likely first) that:
- Implements all four primitives
- Passes all test vectors
- Is explicitly not production software — a reference for implementers

### Formal governance model

As the contributor base grows, a more structured governance process will be needed. See [GOVERNANCE.md](GOVERNANCE.md) for current state and plans.

---

## What is intentionally out of scope for this repo

HAVEN specifies the protocol. The following are implementation choices left to adopters:

- **Data storage** — the spec doesn't care if you use PostgreSQL, a FHIR server, or a blockchain
- **Encryption and key management** — implementation choice
- **Payment rails** — HAVEN measures contribution; it does not distribute value
- **Identity proofing** — how you verify that a patient is who they say they are
- **User interfaces** — patient-facing apps, researcher portals, etc.
- **Marketplace design** — any economic layer built on top of HAVEN

If you want to build these things, great — but they belong in downstream projects, not in this spec repo. Proposals to add them here will be closed.

---

## How to influence the roadmap

Open an issue. Make the case. The roadmap is not fixed — it reflects current priorities and will change based on community input and real-world implementation experience.

What carries the most weight: concrete implementation experience, specific ambiguities found in the spec, and well-reasoned design arguments. Abstract suggestions are harder to act on.
