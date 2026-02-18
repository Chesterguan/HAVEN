# Contributing to HAVEN Protocol

**Last Updated**: February 18, 2026

HAVEN is an independent, open protocol for patient-controlled health data. There is no company behind it. Contributions from engineers, researchers, clinicians, and ethicists are what make it credible and complete.

---

## What kind of contributions are most valuable right now

### 1. Spec feedback and adversarial review

The specifications are in Draft status. The most valuable thing you can do is try to break them — find ambiguities, edge cases, contradictions, or design decisions that don't hold up under scrutiny.

Use the **Spec Feedback** issue template. Quote the relevant text. Be specific.

Good questions to ask as you read:
- Can this be interpreted two different ways?
- What happens in the edge case where...?
- Does the closed-world assumption in the Consent Protocol cause problems for...?
- Is the quality gate formula the right tradeoff between...?

### 2. Implementation reports

If you are building a HAVEN-compliant system (or attempting to), your experience is invaluable. Where did the spec fail you? What was underspecified? What did you have to invent yourself?

Use the **Implementation Report** issue template. You do not need a finished implementation to file one.

### 3. Test vectors

Each primitive has a `test-vectors/<primitive>/` directory with `valid/` and `invalid/` cases. Adding more test vectors — especially for edge cases and boundary conditions — directly improves interoperability across implementations.

See [test-vectors/README.md](test-vectors/README.md) for the file format.

### 4. Documentation and examples

- Fix typos or improve clarity in any `.md` file
- Add a working example in `examples/`
- Translate the whitepaper into another language (ZH and FR exist; others welcome)
- Improve the implementation guide with language-specific guidance

### 5. TypeSpec / schema updates

If you find a mismatch between the TypeSpec definitions in `typespec/` and the formal specs in `spec/`, please file an issue or submit a PR. TypeSpec is the source of truth — it generates JSON Schema and OpenAPI.

---

## How specs evolve

Understanding this helps you contribute effectively.

**Draft** → specs are open for significant change. Design feedback is actively sought. Nothing is locked.

**Candidate** → the spec has had real-world review and is stabilizing. Changes require strong justification.

**Final** → breaking changes require a new version number and are rare.

All specs are currently **Draft**.

### What "breaking change" means

A breaking change is anything that would cause a previously valid Health Asset, Consent Attestation, Provenance Entry, or Contribution to fail validation, or vice versa. Breaking changes require incrementing the major version (e.g. 2.0 → 3.0).

Non-breaking changes (clarifications, new optional fields, editorial improvements) increment the minor or patch version.

---

## How decisions get made

HAVEN is currently maintained by Chester Guan ([@Chesterguan](https://github.com/Chesterguan)). For now:

- All PRs require review and merge by the maintainer
- Significant spec changes should be discussed in an issue before a PR is submitted
- Design decisions are documented in the spec rationale sections — if you disagree with a decision, argue against the rationale specifically

As the contributor community grows, governance will evolve. See [GOVERNANCE.md](GOVERNANCE.md).

---

## Process for contributing

### For feedback, questions, and discussion

1. Search existing issues first
2. Open an issue using the appropriate template
3. Be specific — vague issues are hard to act on

### For PRs

1. **Open an issue first** for anything non-trivial. Discuss before writing.
2. Fork the repo and create a feature branch from `main`
3. Make your changes
4. Submit a PR using the PR template
5. Link the related issue in your PR

### Good first contributions

These are well-scoped and don't require deep protocol knowledge:

- Fix a typo or unclear sentence in any spec or doc file (just submit a PR, no issue needed)
- Add a test vector for an edge case you noticed
- Add an example in a language not yet covered in `examples/`
- Improve the implementation guide for a specific language (TypeScript, Python, Go)

---

## Spec contribution standards

When proposing a spec change, your PR should:

- Reference the specific section and requirement being changed
- Use RFC 2119 keywords correctly (MUST, SHOULD, MAY, MUST NOT, SHOULD NOT)
- Include or update test vectors if the change affects validation behavior
- Explain the *why*, not just the *what* — what problem does this solve?

---

## Setting up for TypeSpec work

```bash
cd typespec
npm install
npm run build   # Generates to ../generated/
```

Requires Node.js 18+. TypeSpec definitions in `typespec/models/` are the source of truth for all type schemas.

---

## Code of conduct

Be direct, be rigorous, be respectful. We are building infrastructure for patient data sovereignty — the stakes are real and the work deserves serious treatment. Critique ideas hard; treat people well.

---

## License

By contributing, you agree that your contributions will be licensed under [CC BY 4.0](LICENSE). This applies to all content in this repository.

---

## Contact

Questions that don't fit an issue template: **chesterfield199512@gmail.com**
