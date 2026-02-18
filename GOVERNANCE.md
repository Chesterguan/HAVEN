# HAVEN Protocol Governance

**Last Updated**: February 18, 2026

This document describes how HAVEN is governed today and how that is expected to evolve.

---

## Current state

HAVEN is an independent, open protocol maintained by Chester Guan. There is no organization, foundation, or company behind it.

**What this means in practice:**

- All PRs are reviewed and merged by the maintainer
- Significant design decisions are made by the maintainer, informed by community input
- The goal is to make this process as transparent as possible — design rationale is written into the specs, decisions are documented in issues

This is appropriate for a protocol at Draft stage with a small contributor base. It will not scale indefinitely.

---

## Decision-making process

### For editorial and non-breaking changes

Typos, clarifications, examples, documentation improvements — open a PR. If it's clearly correct, it will be merged without extended discussion.

### For spec changes (non-breaking)

1. Open a Spec Feedback issue describing the problem and proposed change
2. Discussion happens in the issue
3. If there is rough consensus and no strong objection, a PR is accepted
4. The maintainer has final say

### For breaking spec changes

Breaking changes (anything that invalidates previously valid data structures or changes semantics) require:

1. An issue documenting the problem, proposed change, and rationale
2. A discussion period of at least 14 days
3. Explicit acknowledgment of the breaking nature in the PR and spec changelog
4. Major version increment (e.g. 2.x → 3.0)

### For scope changes

Proposals to add new primitives, significantly extend the protocol, or change the fundamental positioning of HAVEN (e.g. specifying payment mechanisms) require the same process as breaking changes, plus explicit alignment on whether the change belongs in this repo or a downstream project.

---

## What "consensus" means here

HAVEN does not use formal voting. "Rough consensus" means:

- No strong, well-reasoned objection has been raised
- The change has had adequate review time
- The maintainer agrees the change improves the protocol

This is intentionally informal at the current scale. If you raise a strong objection, it will be taken seriously — but you need to argue against the specific design, not just express a preference.

---

## Planned evolution

As the contributor base grows, governance will evolve toward a more distributed model. Likely milestones:

**~5 active contributors**: Add a CODEOWNERS file. PRs require review from at least one contributor other than the author.

**~3 independent implementations**: Form a small technical steering group from implementers. Breaking changes require agreement from the group.

**Protocol stabilization (Candidate status)**: Formalize the governance model before declaring any spec Candidate. A spec that is not governed well cannot be trusted.

This is not a fixed timeline. It depends on how the community grows.

---

## Conflict resolution

If a contributor disagrees with a decision:

1. Make your case in the issue or PR thread — be specific and technical
2. If the maintainer's decision still seems wrong, say so explicitly and explain why
3. The maintainer will reconsider or explain the reasoning more fully
4. If you still disagree after that, you are free to fork the spec under CC BY 4.0

A fork is not a failure — it is a legitimate outcome for a genuinely contested design decision. The community will determine which direction has merit.

---

## What HAVEN will not do

- Be acquired by or transferred to a company
- Add IP encumbrances to the spec
- Change the CC BY 4.0 license
- Require contributors to sign a CLA that transfers rights

These are not just current policy — they are commitments intended to hold regardless of how the project evolves. If you see any of these happening, it is appropriate to raise it loudly.

---

## Contact

Chester Guan — chesterfield199512@gmail.com
