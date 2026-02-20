# HAVEN: A Value Exchange Protocol for Patient-Controlled Health Data

**Ziyuan Guan**¹, **Moni Qiande**¹

¹Independent Researcher

chesterfield199512@gmail.com, mqiande@ufl.edu

---

**Abstract**

Health data interoperability has advanced rapidly — FHIR R4 is now federally mandated in the United States, and the OMOP Common Data Model spans nearly a billion patient records worldwide — yet no corresponding governance layer has kept pace. Data moves between institutions; consent, audit trails, and value attribution do not move with it. Foundation models trained on clinical records are reaching specialist-level performance on medical benchmarks, often without any patient consent mechanism in place.

This paper presents HAVEN, an open protocol comprising four primitives: a content-addressed Health Asset that structurally requires a consent reference before creation; a Consent Protocol with closed-world semantics, deterministic verification, and immediate revocation; a hash-chained Provenance Record supporting O(log n) Merkle inclusion proofs; and a quality-gated Contribution Model that quantifies patient data value through a tier-weighted formula. The protocol layers over FHIR R4, OMOP CDM 6.0, and SMART on FHIR without introducing new data formats. Storage, encryption, and payment mechanisms are left to implementers. We prove soundness and completeness of the consent verification algorithm, establish the tamper-evidence property of the provenance chain under standard cryptographic assumptions, and characterize the computational complexity of all core operations.

---

## 1. Introduction

GPT-4 was trained on medical corpora that remain undisclosed [5]. Med-PaLM 2 scored 86.5% on the MedQA benchmark using clinical datasets [6]. The patients whose records contributed to these training sets had no mechanism to authorize, limit, or even discover that particular use. This is not an isolated failure of one company's data practices. It is a gap in the infrastructure itself.

The technical foundations for moving health data are now mature. CMS mandates have made FHIR R4 the standard API for patient-facing health data access in the United States since 2021 [11, 25]. The OHDSI network, built on the OMOP Common Data Model, has grown to encompass 974 million patient records across 544 databases in 54 countries [2, 12]. SMART on FHIR provides OAuth 2.0 authorization that all major EHR vendors support [1]. HIPAA grants patients the right to access their own records [13]; GDPR enshrines data portability as a fundamental right [14]. The 21st Century Cures Act further prohibits information blocking by health care providers and health IT developers [27]. Interoperability, in other words, is largely solved.

Governance is not. When a FHIR API serves a lab result to an authorized client, nothing in the protocol specifies what that client may do with the data afterward — for how long, under what conditions, for what purpose. Consent is a signed form, not an executable policy. There is no audit trail the patient can inspect. And the $84 billion clinical trials industry [7], which depends heavily on patient data, offers patients no accounting for the value their records generate.

The philosophical case for patient data rights is well established. Locke argued that people hold a natural property interest in the products of their labor [17] — and patients do labor, often considerably, in generating clinical data. Zuboff identifies the silent extraction of human experience as the defining economic logic of surveillance capitalism [15]. Lanier argues more bluntly that failing to compensate people for data that generates commercial value is a form of economic injustice [16]. These arguments have practical consequences: if patients do not trust the systems that use their data, those systems will struggle to recruit participants, acquire data, and maintain the social license on which clinical research depends.

HAVEN is a protocol specification — not a platform or a product — that addresses the governance gap. It defines the minimum data structures and operational semantics needed to make patient control over health data technically enforceable. It says nothing about how to store data, encrypt it, manage keys, or distribute payments. Those decisions belong to implementers. The protocol itself specifies four composable primitives and the rules for how they interact.

### 1.1 Contributions

This paper makes the following contributions:

- We provide a formal specification of four composable protocol primitives — Health Asset, Consent Protocol, Provenance Record, and Contribution Model — with precise data structures, invariants, and operational semantics.
- We specify a closed-world consent verification algorithm with deterministic guarantees: the same inputs always produce the same authorization decision, revocation takes effect on the next verification call, and resources not explicitly granted are denied by default.
- We specify a hash-chained provenance construction with O(log n) Merkle proof verification, and prove the tamper-evidence property: any modification to entry i in the chain invalidates all subsequent entries j > i with high probability under standard cryptographic assumptions.
- We define a quality-gated, tier-weighted contribution model that quantifies patient data value relative to a usage context, supporting multiple fair-attribution methods including quality-weighted allocation and Data Shapley values [41].
- We describe an integration architecture that layers HAVEN governance over existing mandated health standards without requiring adoption of new data formats or storage technologies.

### 1.2 Paper Organization

Section 2 reviews related work. Section 3 formally characterizes the problem. Section 4 presents the design principles underlying HAVEN. Section 5 specifies the four protocol primitives. Section 6 analyzes protocol properties including correctness, tamper evidence, complexity, and security considerations. Section 7 discusses limitations and open problems. Section 8 concludes.

---

## 2. Background and Related Work

### 2.1 Health Data Interoperability Standards

FHIR (Fast Healthcare Interoperability Resources) Release 4 is an HL7 standard for the exchange of clinical data via RESTful APIs [11]. It defines resource types for patients, conditions, observations, medications, procedures, and other clinical concepts. CMS Interoperability Rules [25], effective 2021, require that Medicare and Medicaid insurers and most hospital systems expose FHIR-compliant patient access APIs, making FHIR the de facto standard for patient-facing health data access in the United States.

SMART on FHIR extends FHIR with a standardized OAuth 2.0 [26] authorization framework, enabling third-party applications to request patient-authorized access to specific scopes of health data [1]. It provides the authentication plumbing that HAVEN's Consent Protocol operates above.

The OMOP Common Data Model (CDM) is a person-centric relational schema developed by OHDSI (Observational Health Data Sciences and Informatics) for standardizing observational health data to support large-scale research [12]. As of 2024, the OHDSI network encompasses 974 million patient records across 544 databases in 54 countries [2], representing the largest federated health research infrastructure in operation.

### 2.2 Prior Systems

The history of patient-facing health data systems is instructive mostly for what went wrong. Microsoft HealthVault (2007–2019) and Google Health (2008–2012) both attempted to provide patients with a centralized repository for their records [3, 4]. Both were discontinued due to low adoption. The root cause, in retrospect, was timing: without CMS mandates requiring health systems to expose FHIR APIs, patients had to manually upload records — a workflow too burdensome to sustain at scale. The regulatory environment has since shifted dramatically, but the assumption that aggregation alone solves the governance problem has not been revisited as carefully as it should be.

Apple Health Records [28] demonstrates what aggregation looks like with better plumbing. It uses SMART on FHIR to pull records from multiple institutions into a device-local store. The result is useful for patients who want to see their data in one place, but it stops there. There is no consent protocol governing downstream use, no audit log of third-party access, and no research workflow. CommonHealth [29] fills a similar niche on Android. Both are consumption interfaces, not governance infrastructure.

The research side of the landscape has its own limitations. PicnicHealth collects patient records and makes them available to research sponsors. The consent model is binary — patients opt in at enrollment or they don't — and the platform is centralized. A patient who consents to one study cannot restrict specific data types, set expiration dates, or revoke access to individual records after the fact. The patient is a data source, not a data controller.

Ocean Protocol [30] took a different approach: a decentralized marketplace with compute-to-data capabilities and token-based value exchange. Its architecture is sophisticated, but it was designed for generic data. Health data has specific requirements — FHIR resource types, OMOP concept mappings, consent semantics that distinguish between treatment and research purposes, re-identification constraints — that a general-purpose marketplace does not address. The Solid project [31], originating with Tim Berners-Lee, operates at a still more abstract level: personal data pods that individuals control. The ownership model is right, but Solid has no health data model, no quality assessment framework, and no mechanism for the kind of granular, purpose-restricted consent that clinical research demands.

At the institutional level, TEFCA [32] and Carequality govern health data exchange between covered entities. They are effective at what they do — network-to-network routing — but their design places the patient as a subject of exchange, not a participant in it. A patient whose records flow through TEFCA cannot set conditions on downstream use, inspect an access log, or receive attribution when their data appears in a research dataset.

### 2.3 Positioning

The gap visible across all of these systems is the same: governance does not travel with the data. HAVEN's design borrows Solid's premise that the patient should be the data controller, then specializes it for healthcare — which means speaking FHIR and OMOP, supporting the unusual consent semantics that clinical research requires (purpose restriction, cohort minimums, re-identification prohibition, immediate revocation), maintaining a cryptographically verifiable audit trail, and accounting for the value of patient contributions. The result is a protocol rather than a service, domain-specific rather than generic, and patient-centric rather than institution-centric.

| System | Patient Control | Consent Granularity | Tamper-Evident Audit | Value Attribution | Health Standards |
|--------|:-:|:-:|:-:|:-:|:-:|
| HAVEN | Yes | High | Yes | Yes | FHIR, OMOP |
| Apple Health Records | Partial | Binary | No | No | FHIR |
| PicnicHealth | No | Binary | Partial | No | Partial |
| Ocean Protocol | Yes | Medium | Partial | Yes | No |
| Solid | Yes | General | Partial | No | No |
| TEFCA/Carequality | No | Low | Partial | No | Yes |

[Figure: Positioning chart — two-dimensional plot with Patient Control on the x-axis (Low to High) and Healthcare Specificity on the y-axis (Generic to Healthcare-Specific). HAVEN occupies the upper-right quadrant (high patient control, high healthcare specificity). TEFCA/Carequality occupies upper-left. Ocean Protocol occupies lower-right. Solid occupies lower-right adjacent. Apple Health Records occupies middle-center.]

---

## 3. Problem Statement

The governance gap in health data infrastructure can be decomposed into four problems. They are related but distinct, and a complete solution must address each independently.

**Problem 1 (Governance Absence).** Interoperability standards like FHIR govern format and transmission. They say nothing about what happens to data after it leaves a source system. OAuth 2.0 scopes [26] authorize retrieval; they do not restrict downstream use, impose purpose limitations, or expire. The result is that governance exists at the point of access but does not propagate with the data.

More precisely: let D be a health data object and A an actor who retrieves it. Existing frameworks define whether A can access D at a source endpoint, but impose no constraints on what A does with D afterward — for how long, under what restrictions, or for what purpose. Once data crosses a system boundary, governance evaporates.

**Problem 2 (Static Consent).** A HIPAA authorization form grants broad, indefinite access. An OAuth 2.0 [26] consent screen offers scope selection at the granularity of FHIR resource categories, with no mechanism for time-bounding, purpose restriction, conditional access, or immediate revocation. These tools treat consent as a binary state. Real consent is richer than that.

Let C denote a consent record. Current systems model C as a function from (accessor, scope) to {authorized, denied}, where scope is coarse and the function, once it returns authorized, remains so until the record is manually updated. HAVEN requires C to encode fine-grained scope S, purpose P, conditions {c_1, ..., c_k}, and expiration E, with deterministic verification: verify(C, A, S, P) must produce identical results for identical inputs whenever consent status has not changed between calls.

**Problem 3 (Audit Opacity).** Ask a patient who accessed their medical record last Tuesday. In most health systems, they cannot find out. Access logs exist within institutional EHR systems, but patients have no API to query them, no standard format to interpret them, and no cryptographic guarantee that they have not been modified.

Let X denote the set of access events against a patient's data. In current systems, X is opaque to the patient: stored within institutional databases, formatted inconsistently across vendors, and modifiable by system administrators. HAVEN requires X to be patient-accessible and tamper-evident — any unauthorized modification must be detectable with probability at least 1 - 2^{-256}.

**Problem 4 (Value Extraction Without Attribution).** The clinical trials market — valued at $84 billion in 2024 — is projected to reach $158 billion by 2033 [7]. Recruitment costs average $6,533 per patient [9]. Data acquisition for retrospective studies takes 6 to 18 months [10]. Meanwhile, 80% of trials fail to meet enrollment timelines [8], in large part because patient recruitment remains inefficient. The patients whose data could alleviate these bottlenecks have no accounting system that records their contribution.

Let V(D, c) denote the value generated by using patient data D in context c. No existing system computes V, attributes it to specific patients, or records the attribution in an auditable structure. HAVEN does not dictate how value should be distributed — that is a market and policy question — but it requires a principled formula for computing relative contribution weights and a structure for recording them.

---

## 4. Protocol Design Principles

Six principles guided the design of HAVEN. We describe each, along with the reasoning — including the ethical commitments — that led to it.

**Principle 1: Patient sovereignty as architectural constraint.** Many systems treat patient control as an application-layer feature: something layered on after the data model is defined. HAVEN takes the opposite approach. A Health Asset that lacks a consent reference is structurally invalid and rejected at creation time. This makes governance bypass a violation of the data model, not merely a policy infraction. The design reflects Beauchamp and Childress's principle of autonomy [18]: respect for self-determination is most durable when it is embedded in infrastructure, not in policy documents that can be overridden.

**Principle 2: Consent as executable code.** The Nuremberg Code [20] and the Belmont Report [21] established voluntary, informed consent as the ethical foundation of human subjects research. Seventy-five years later, consent in practice remains a PDF or a checkbox — a legal artifact, not a computational one. HAVEN encodes consent as a cryptographically signed data structure with a deterministic verification algorithm. The goal is what Nissenbaum calls contextual integrity [22]: data shared for one purpose should not silently flow to another. Purpose restriction and condition mechanisms in the Consent Protocol are a direct implementation of that idea.

**Principle 3: Mandatory auditability.** Lessig observed that technical architectures encode values whether their designers acknowledge this or not [19]. A system with no audit trail is, in Lessig's framing, a system designed for opacity — the architecture has made a normative choice by omission. HAVEN requires that every access event produce a provenance entry. Patients can inspect the log. Auditors can verify its integrity.

**Principle 4: Measurable contribution.** When patient data was used only for treatment, the question of fair compensation was largely moot. Now that health records are commercial inputs to AI systems and clinical trials — an $84 billion industry [7] — the distributive justice question that Rawls posed is harder to avoid [23]: the people who bear the privacy risks of data sharing have a claim on the benefits. HAVEN does not mandate how value should be distributed; that depends on context, and reasonable people disagree. What it does provide is the accounting: a principled formula for measuring who contributed what, and an auditable record of those measurements. Ostrom's work on commons governance [24] is relevant here. Patient data is not a private good (locking it away helps no one) or a public good (extracting it freely helps everyone except patients). It is a commons, and commons require governance structures built by the people who participate in them.

**Principle 5: No new standards.** New data formats face a coordination problem: no one adopts until everyone else does. HAVEN avoids this by building on FHIR R4 and OMOP CDM — standards that are already mandated or widely deployed. The protocol adds a governance layer to existing infrastructure. It does not ask anyone to rip out what they have.

**Principle 6: Minimal scope.** A protocol that tries to specify everything — storage, encryption, payments, identity, UI — will either never ship or never be adopted. HAVEN specifies data structures, operational semantics, and verification algorithms. Everything else is the implementer's problem. This is a deliberate choice, not a gap. The right encryption scheme for a pediatric hospital in Ohio is probably not the right scheme for a genomics startup in Singapore.

---

## 5. Protocol Specification

### 5.1 Health Asset

A Health Asset is a governed reference to clinical data. It is not the data itself — it is a pointer, annotated with the governance metadata necessary to enforce consent and audit access before any underlying data is touched.

#### 5.1.1 Data Structure

```
HealthAsset := {
    asset_id        : ContentHash      // SHA-256 of canonical form of all other fields
    data_ref        : SecureReference  // URI pointing to clinical data
    substrate       : SubstrateType    // FHIR-R4 | OMOP-CDM-5.4 | OMOP-CDM-6.0 | ...
    consent_ref     : ConsentID        // REQUIRED; references active ConsentAttestation
    quality_class   : QualityClass     // A | B | C | D
    provenance_ref  : ProvenanceID     // Reference to provenance chain entry
    patient_ref     : PatientID        // Patient identifier (indirect; no PII)
    created_at      : Timestamp        // ISO 8601 UTC, millisecond precision
    metadata        : AssetMetadata    // OPTIONAL
}
```

#### 5.1.2 Content Addressing

The `asset_id` is computed as follows:

1. Serialize the HealthAsset to JSON, excluding the `asset_id` field.
2. Sort all object keys alphabetically (recursively for nested objects).
3. Remove whitespace (canonical minified form).
4. Encode to UTF-8.
5. Compute SHA-256 of the resulting byte string.
6. Format as `sha256:<64-character lowercase hex digest>`.

```
computeAssetId(asset: HealthAsset) → ContentHash:
    canonical := deepCopy(asset)
    delete canonical.asset_id
    bytes    := encodeUTF8(serializeJSON(canonical, {sortKeys: true, minify: true}))
    digest   := SHA256(bytes)
    return "sha256:" + toLowerCase(encodeHex(digest))
```

This is the same content-addressing scheme used by Git [33]. Any modification to any field changes the `asset_id`, making tampering detectable at the structure level without requiring a separate integrity-checking mechanism.

#### 5.1.3 Structural Invariants

The following invariants must hold for all valid Health Assets:

- **I1** (Content integrity): `asset_id = computeAssetId(asset)`.
- **I2** (Governance completeness): `consent_ref` must reference an `ACTIVE` ConsentAttestation.
- **I3** (Quality correctness): `quality_class` must equal the result of the three-gate protocol applied to the referenced data.
- **I4** (Temporal validity): `created_at <= now()`.

**I2** is the critical structural enforcement: a Health Asset cannot be created without an active consent reference. The protocol rejects asset creation if `consent_ref` is absent, references a non-existent consent, or references a revoked or expired consent.

#### 5.1.4 Quality Classification

Each Health Asset carries a quality class determined by a three-gate validation protocol applied at ingestion time (before encryption of the underlying data). The gates are evaluated sequentially; failure at any gate halts the process.

**Gate 0 (Provenance Validation)** is binary: the data source must present a valid signature from a known and trusted origin, the content hash must match the declared hash, and timestamps must be internally consistent (no future dates, logical temporal ordering). Failure at Gate 0 results in rejection; no Health Asset is created.

**Gate 1 (Structural Completeness)** produces a completeness ratio in [0, 1]: the fraction of required fields that are present, correctly typed, and carry valid codes within their respective code systems (ICD-10 [34], SNOMED CT [35], LOINC [36], RxNorm [37]). A threshold of 0.95 is required to proceed to Gate 2.

**Gate 2 (Semantic Mapping)** produces a mapping ratio in [0, 1]: the fraction of coded clinical concepts that map to standard vocabularies (SNOMED CT [35], LOINC [36], RxNorm [37]) with an exact or narrower relationship. Exact mappings count as 1.0; narrower mappings count as 0.5.

The quality score and class are derived as:

```
QualityScore = G0 x (0.4 * G1 + 0.6 * G2)

where:
  G0 in {0, 1}     (Gate 0: binary)
  G1 in [0.0, 1.0] (Gate 1: structural completeness ratio)
  G2 in [0.0, 1.0] (Gate 2: semantic mapping ratio)
```

| Class | Quality Score Range | Description |
|-------|---------------------|-------------|
| A | >= 0.90 | Research-ready, fully mapped |
| B | 0.75 – 0.89 | Research-usable, minor gaps |
| C | 0.50 – 0.74 | Usable with caveats |
| D | < 0.50 | Limited research utility |
| REJECT | G0 = 0 | Asset cannot be created |

Note that two distinct sets of thresholds are in play. The *gate pass thresholds* (0.95 for Gate 1, 0.90 and 0.70 for Gate 2 mapping ratio) determine how individual gates route data through the pipeline and influence the composite quality score. The *quality class boundaries* (0.90, 0.75, 0.50) partition the composite score into classes A–D. Both sets are reference values. Empirical validation against specific research use cases is needed and is noted as future work in Section 7.

[Figure: Three-gate quality assessment flowchart. Raw data enters Gate 0 (Provenance Validation). Failure exits to REJECT. Success passes to Gate 1 (Structural Completeness). If completeness ratio < 0.95, assign Class C or D based on sub-threshold. Success passes to Gate 2 (Semantic Mapping). Mapping ratio >= 0.90 assigns Class A; 0.70-0.89 assigns Class B; below 0.70 assigns Class C. All gates produce a provenance record.]

### 5.2 Consent Protocol

#### 5.2.1 Data Structure

```
ConsentAttestation := {
    consent_id  : UUID
    grantor     : PatientIdentity
    grantee     : AccessorIdentity
    scope       : DataScope {
        resource_types : ResourceType[]  // Explicit grant list
        exclusions     : ResourceType[]  // Explicit denial list
        time_range     : TimeRange | null
    }
    purpose     : PurposeType[]          // TREATMENT | RESEARCH | AI_TRAINING | ...
    conditions  : Condition[]            // AGGREGATION_ONLY | MIN_COHORT_SIZE | ...
    granted_at  : Timestamp
    expires_at  : Timestamp | null
    status      : ConsentStatus          // ACTIVE | REVOKED | EXPIRED | PENDING | REJECTED
    signature   : CryptoSignature        // Ed25519 or ECDSA over canonical form
    revoked_at  : Timestamp | null       // Non-null iff status = REVOKED
}
```

#### 5.2.2 Operations

**grant(grantor, grantee, scope, purpose, conditions?, expires_at?) → ConsentAttestation | Error**

Creates a new ConsentAttestation with status ACTIVE. Requires authenticated grantor. Creates a provenance entry of type CONSENT_GRANTED. Returns an error if the grantor is not authenticated, the scope is empty, or the expiration time is in the past.

**verify(consent_id, accessor, requested_scope, requested_purpose) → VerificationResult**

Evaluates whether the requested access is authorized. The algorithm is:

```
verify(consent_id, accessor, requested_scope, requested_purpose):
    consent := getConsent(consent_id)

    // Step 1: Status
    if consent.status != ACTIVE:
        return {authorized: false, reason: "Consent not active"}

    // Step 2: Expiration
    if consent.expires_at != null AND now() > consent.expires_at:
        setStatus(consent_id, EXPIRED)
        return {authorized: false, reason: "Consent expired"}

    // Step 3: Grantee identity
    if not identityMatches(consent.grantee, accessor):
        return {authorized: false, reason: "Accessor not authorized"}

    // Step 4: Purpose
    if requested_purpose not in consent.purpose:
        return {authorized: false, reason: "Purpose not authorized"}

    // Step 5: Scope (closed-world semantics)
    for each t in requested_scope.resource_types:
        if t in consent.scope.exclusions:
            return {authorized: false, reason: "Resource type explicitly excluded"}
        if t not in consent.scope.resource_types:
            return {authorized: false, reason: "Resource type not in scope"}

    // Step 6: Conditions
    for each c in consent.conditions:
        if not evaluateCondition(c, requested_scope, accessor):
            return {authorized: false, reason: "Condition not satisfied"}

    // Step 7: Record
    appendProvenance(CONSENT_VERIFIED, consent_id, accessor)
    return {authorized: true}
```

**revoke(consent_id, grantor, reason?) → RevokeResult | Error**

Sets consent status to REVOKED and records `revoked_at`. After `revoke()` returns successfully, all subsequent calls to `verify()` for that consent_id must return `{authorized: false}`. The protocol requires that revocation take effect before the next `verify()` call — that is, `revoke()` must complete synchronously with respect to the consent store. Implementations that use eventually consistent storage must ensure that revocation propagation completes before `revoke()` returns to the caller. A provenance entry of type CONSENT_REVOKED is created.

**list(patient_id, filters?) → ConsentAttestation[]**

Returns all consents for a patient, defaulting to ACTIVE status.

#### 5.2.3 Semantic Properties

Three semantic properties are normative requirements of the Consent Protocol:

**Determinism.** The same inputs to `verify()` must produce the same authorization decision. The authorization logic (Steps 1–6) is purely functional over the consent record state; there is no randomization, no probabilistic element, and no implementation-defined behavior at any step. Step 7 (`appendProvenance`) is a side effect that records the verification event but does not influence the authorization outcome — the decision is already determined before the provenance entry is written. This property is required for auditability: if verification decisions are not reproducible, audit logs cannot be reliably interpreted.

**Immediate revocation.** Revocation takes effect on the next `verify()` call after `revoke()` returns. There is no grace period. This is a stronger guarantee than is typically provided by OAuth 2.0 token revocation, which may allow short-lived tokens to remain valid after revocation.

**Closed-world semantics.** Following the closed-world assumption from database theory [38], if a resource type is not explicitly listed in `scope.resource_types`, access is denied regardless of whether it appears in `scope.exclusions`. Silence equals denial. This inverts the default assumption of many existing systems, in which access is granted unless explicitly prohibited, and reflects Nissenbaum's contextual integrity principle: information does not flow appropriately simply because its flow has not been forbidden [22].

#### 5.2.4 Cryptographic Attestation

The `signature` field contains a cryptographic signature over the canonical JSON form of the ConsentAttestation (excluding the `signature` field itself), using either Ed25519 [39] or ECDSA (P-256 or P-384). Implementations must support Ed25519. The signature binds the consent to the grantor's key material, making forgery detectable and providing non-repudiation.

### 5.3 Provenance Record

#### 5.3.1 Data Structure

```
ProvenanceEntry := {
    entry_id      : EntryID         // "prov:<chain_id>:entry:<sequence>"
    chain_id      : UUID            // Per-patient chain identifier
    sequence      : Integer         // Zero-indexed; no gaps permitted
    timestamp     : Timestamp       // ISO 8601 UTC, millisecond precision
    event_type    : EventType
    actor         : ActorIdentity
    subject       : SubjectRef      // AssetRef | ConsentRef | QueryRef | ...
    details       : EventDetails    // Event-type-specific structured data
    previous_hash : Hash | null     // null for genesis entry (sequence = 0)
    entry_hash    : Hash            // SHA-256 of canonical form of all other fields
    signature     : CryptoSignature // Actor's signature over entry_hash
    merkle_proof  : MerkleProof     // OPTIONAL; inclusion proof
}
```

The `EventType` enumeration includes: `ASSET_CREATED`, `ASSET_ACCESSED`, `ASSET_EXPORTED`, `CONSENT_GRANTED`, `CONSENT_VERIFIED`, `CONSENT_REVOKED`, `CONSENT_EXPIRED`, `QUERY_EXECUTED`, `QUERY_RESULT_RELEASED`, `COMPUTATION_STARTED`, `COMPUTATION_COMPLETED`, `MODEL_TRAINED`, `MODEL_INFERENCE`, `CONTRIBUTION_RECORDED`, and `SYSTEM_AUDIT`.

#### 5.3.2 Hash Chain Construction

The genesis entry (sequence = 0) has `previous_hash = null`. All subsequent entries satisfy the chain invariant:

```
Chain Invariant:
  entries[n].previous_hash == entries[n-1].entry_hash
  entries[n].sequence      == entries[n-1].sequence + 1
  entries[n].timestamp     >= entries[n-1].timestamp
```

The `entry_hash` is computed using the same canonicalization algorithm as the Health Asset: serialize all fields except `entry_hash` and `merkle_proof` to canonical JSON (sorted keys, minified), encode to UTF-8, and apply SHA-256.

#### 5.3.3 Merkle Tree Structure

HAVEN specifies a Merkle tree [40] over provenance entries to support O(log n) inclusion proofs. The tree is constructed as follows:

- Leaf nodes are `entry_hash` values.
- Parent nodes are `SHA-256(left_child || right_child)`.
- If the number of leaves is odd, the last leaf is duplicated.
- Construction continues until a single root node is obtained.

A Merkle proof for entry at leaf index i consists of the root hash, the leaf index, and the sequence of sibling hashes (with position indicators LEFT or RIGHT) along the path from the leaf to the root. Proof size is O(log n) hashes. Verification recomputes the root from the leaf hash and sibling sequence and checks equality with the provided root.

```
verifyMerkleProof(entry_hash, proof: MerkleProof) → boolean:
    current := entry_hash
    for node in proof.path:
        if node.position == LEFT:
            current := SHA256(node.hash || current)
        else:
            current := SHA256(current || node.hash)
    return current == proof.root_hash
```

[Figure: Merkle tree diagram over four provenance entries. Leaf nodes at bottom: H(Entry 0), H(Entry 1), H(Entry 2), H(Entry 3). Second level: H(H(Entry 0) || H(Entry 1)) and H(H(Entry 2) || H(Entry 3)). Root: H(level-2-left || level-2-right). Proof for Entry 1 requires H(Entry 0) and H(H(Entry 2) || H(Entry 3)).]

#### 5.3.4 Operations

**append(chain_id, event_type, actor, subject, details) → ProvenanceEntry | Error**

Adds a new entry to the chain. Must be atomic: either the entry is fully persisted with correct hash linkage, or no change occurs. The operation fails if the actor is not authenticated.

**verify(chain_id, from?, to?, full_chain?) → VerificationResult**

Verifies chain integrity over a specified range or the entire chain. Full verification is O(n); Merkle proof verification is O(log n).

**getMerkleProof(entry_id) → MerkleProof | Error**

Returns an O(log n) inclusion proof for the specified entry.

### 5.4 Contribution Model

#### 5.4.1 Data Structure

```
Contribution := {
    contribution_id : ContributionID
    patient_id      : PatientID
    asset_refs      : AssetRef[]       // At least one; all must belong to patient
    quality_score   : Float[0, 1]
    tier            : ContributionTier // PROFILE | STRUCTURED | LONGITUDINAL | COMPLEX
    context         : UsageContext
    raw_value       : Float[0, 1]      // Computed contribution value
    timestamp       : Timestamp
    provenance_ref  : ProvenanceID
    attribution     : Attribution      // OPTIONAL; multi-party allocation
}
```

#### 5.4.2 Contribution Tiers

Tier is determined by the types of assets included in the contribution and the temporal span of the data:

```
determineTier(assets: HealthAsset[]) → ContributionTier:
    has_complex    := any(asset.data_type in {GENOMIC, IMAGING, CLINICAL_NOTES} for asset in assets)
    has_structured := any(asset.data_type in {LABS, MEDICATIONS, CONDITIONS, PROCEDURES} for asset in assets)
    time_span      := max(created_at over assets) - min(created_at over assets)

    if has_complex:          return COMPLEX
    if has_structured AND time_span >= 3 years: return LONGITUDINAL
    if has_structured:       return STRUCTURED
    return PROFILE
```

Reference tier weights are:

| Tier | Reference Weight | Typical Data |
|------|:---:|---|
| PROFILE | 0.25 | Demographics, administrative |
| STRUCTURED | 0.50 | Labs, medications, diagnoses, procedures |
| LONGITUDINAL | 0.75 | Structured data over >= 3 years |
| COMPLEX | 1.00 | Clinical notes, imaging, genomics |

Implementations may adjust weights within the constraint that the ordering PROFILE <= STRUCTURED <= LONGITUDINAL <= COMPLEX is preserved and all weights are in [0.1, 1.0].

#### 5.4.3 Value Formula

```
V = TierWeight(tier) * QualityScore * VolumeNorm * ContextMultiplier

where:
  VolumeNorm = min(1.0, log_2(1 + n) / log_2(1 + N_ref))
  n     = number of records in contribution
  N_ref = context-dependent reference record count (e.g., 1000)
```

We use logarithmic volume normalization so that contribution value shows diminishing returns at high record counts — the thousandth lab result adds less than the tenth. This discourages bulk submission of low-quality records and rewards diversity. The choice of base-2 is for consistency with the Merkle tree; the base does not affect the monotonicity or concavity properties that motivate the log transform.

The `ContextMultiplier` adjusts for the intensity and type of data use. Reference values are:

| Context Type | Reference Multiplier |
|---|:---:|
| MODEL_TRAINING | 1.5 |
| RESEARCH_STUDY | 1.0 |
| COHORT_QUERY | 0.5 |
| QUALITY_MEASURE | 0.4 |
| AGGREGATE_ANALYSIS | 0.3 |
| MODEL_INFERENCE | 0.2 |
| PUBLIC_HEALTH | 0.1 |

Implementations may define alternative multipliers but must document them. The formula produces a dimensionless relative weight — not a monetary value. What that weight is worth in economic terms is a market question, not a protocol question.

#### 5.4.4 Multi-Party Attribution

When multiple patients contribute to a study, the protocol supports several attribution methods:

**QUALITY_WEIGHTED** (recommended default): Patient i receives a share proportional to their contribution value.

```
Share(i) = ContributionValue(i) / sum_j(ContributionValue(j)) * TotalValue
```

**SHAPLEY**: Game-theoretic fair attribution using Data Shapley values [41]. Patient i's Shapley value is their average marginal contribution across all possible orderings:

```
Shapley(i) = sum_S (|S|! * (n - |S| - 1)! / n!) * (v(S union {i}) - v(S))
```

where the sum is over all subsets S not containing i, and v(S) is the value function (contribution quality) of coalition S. Exact computation is O(2^n); the Monte Carlo approximation is O(n^2) for a fixed number of iterations and is recommended for large cohorts.

**EQUAL**: All participants receive equal shares. Simple and explainable; appropriate when contributions are approximately homogeneous.

#### 5.4.5 Operations

**record(patient_id, asset_refs, context) → Contribution | Error**

Computes and records a contribution. Requires active consent for the usage context. Creates a provenance entry of type CONTRIBUTION_RECORDED.

**calculate(assets, context) → ContributionPreview**

Computes a contribution preview without recording. Used for transparency and patient-facing disclosure before consent is granted.

### 5.5 Structural Relationships

The four primitives compose as follows:

- Every Health Asset requires a Consent reference at creation time (structural enforcement of Principle 1).
- Every consent verification operation creates a Provenance entry (structural enforcement of Principle 3).
- Every asset access creates a Provenance entry.
- Contribution calculation draws on Health Assets (for tier and quality information) and Provenance (for usage attribution and audit).
- The Provenance Record is therefore the universal audit substrate: all operations on Health Assets and Consents generate Provenance entries automatically.

[Figure: Primitive composition diagram. Four boxes: Health Asset, Consent Protocol, Provenance Record, Contribution Model. Arrows: Health Asset depends on Consent Protocol (structural requirement). Consent Protocol operations write to Provenance Record. Health Asset operations write to Provenance Record. Contribution Model reads from Health Asset and Provenance Record.]

### 5.6 Exchange Bundle

HAVEN defines an Exchange Bundle format for transferring governance metadata between HAVEN-compliant systems. A bundle contains Health Assets, their associated Consent Attestations, and the relevant Provenance entries, packaged for transmission. The Exchange Bundle is supporting interoperability infrastructure, not a fifth core primitive.

---

## 6. Analysis

### 6.1 Correctness of Consent Verification

**Definition 6.1 (Valid authorization).** An access request (accessor A, scope S, purpose P) is validly authorized under consent C if and only if: (1) C.status = ACTIVE; (2) now() < C.expires_at or C.expires_at = null; (3) A matches C.grantee; (4) P in C.purpose; (5) every resource type in S is in C.scope.resource_types and not in C.scope.exclusions; and (6) all conditions in C.conditions are satisfied.

**Theorem 6.2 (Soundness).** If verify(C, A, S, P) returns `{authorized: true}`, then (A, S, P) is validly authorized under C.

*Proof.* The verification algorithm performs explicit checks at each step corresponding to exactly the conditions in Definition 6.1. Steps 1–6 of the algorithm map one-to-one to conditions (1)–(6). The algorithm returns `{authorized: true}` only after all six checks pass. Therefore, if the return value is `{authorized: true}`, all six conditions hold. QED.

**Theorem 6.3 (Completeness).** If (A, S, P) is validly authorized under C, then verify(C, A, S, P) returns `{authorized: true}`.

*Proof.* If all six conditions in Definition 6.1 hold, then: Steps 1 and 2 pass (status check and expiration check), Step 3 passes (grantee match), Step 4 passes (purpose), Step 5 passes (closed-world scope check, which approves because all requested types are in scope and none are excluded), and Step 6 passes (all conditions satisfied). The algorithm therefore reaches Step 7 and returns `{authorized: true}`. QED.

**Corollary 6.4 (Determinism).** Since the algorithm is purely functional over the consent state (which is determined at the time of the call), identical inputs produce identical outputs. The only mutable element is consent status, which can change (ACTIVE to REVOKED or EXPIRED) between calls; but for a fixed status, the output is deterministic.

These proofs depend on the algorithm being implemented correctly — a nontrivial assumption that formal verification (e.g., in Coq or Lean) could strengthen. They also assume correct consent record retrieval and correct identity matching, both of which are implementation concerns outside the protocol specification.

### 6.2 Tamper Evidence of the Provenance Chain

**Theorem 6.5 (Hash chain tamper evidence).** Let entries[0..n] be a valid provenance chain. If any entry entries[i] is modified (for some 0 <= i <= n), then for all j > i, entries[j].previous_hash != SHA256(canonical(entries[j-1])), with probability 1 - 2^{-256} under SHA-256 collision resistance.

*Proof.* By definition of the chain invariant, entries[i+1].previous_hash = entries[i].entry_hash. If entries[i] is modified to entries'[i], then SHA256(canonical(entries'[i])) != entries[i].entry_hash with probability 1 - 2^{-256} (by SHA-256 collision resistance [42]; the best known collision attack requires approximately 2^{128} operations). Therefore entries[i+1].previous_hash != SHA256(canonical(entries'[i])). The chain invariant is violated at position i+1, and by induction, all entries j > i have invalid linkage. QED.

**Corollary 6.6.** Any modification to a provenance entry is detectable by the chain verification algorithm `verifyChain()`, which checks hash linkage for all consecutive pairs in the chain.

A limitation: this property covers post-hoc modification but not insertion of fabricated entries between existing ones (which would require recomputing all subsequent hashes — detectable if Merkle roots are anchored externally, but not guaranteed by the chain structure alone). Anchoring Merkle roots to external timestamping services [43] or cross-replicating them strengthens the guarantee beyond what the protocol requires by default.

### 6.3 Computational Complexity

**Consent verification.** `verify()` performs a fixed number of hash and equality checks followed by a linear scan over conditions. If the number of conditions is bounded by a constant k, `verify()` is O(1) — constant-time in the number of entries in the provenance chain and in the total number of assets in the system.

**Provenance chain verification.** Full chain verification (`verifyChain()`) is O(n) where n is the number of entries: each consecutive pair is checked once. Merkle proof verification for a single entry is O(log n): the proof path has length ceil(log_2(n)), and each step requires one SHA-256 computation.

**Quality scoring.** The three-gate protocol processes each record once. Gate 0 is O(k) where k is the number of records. Gate 1 is O(k * f) where f is the number of required fields per record. Gate 2 is O(k * c) where c is the number of coded concepts per record. Overall quality scoring is O(k) for fixed f and c.

**Contribution value computation.** Given a quality score and tier (already computed), the value formula V = TierWeight * QualityScore * VolumeNorm * ContextMultiplier requires O(1) arithmetic operations. The tier determination scan over assets is O(|assets|). Shapley value computation is O(2^n) exact or O(n^2 * iterations) approximate for a Monte Carlo method with a fixed number of iterations.

### 6.4 Security Considerations

**Adversary model.** The security analysis assumes a computationally bounded adversary (polynomial-time) who may be an authorized system participant (e.g., a data consumer or platform operator) acting outside the bounds of their consent grant. The adversary can read and write messages on the network, attempt to forge or modify provenance entries, and attempt to access data beyond their authorized scope. The adversary cannot break SHA-256 preimage or collision resistance, nor forge Ed25519/ECDSA signatures without the corresponding private key. We do not model denial-of-service attacks or side-channel attacks, which are implementation-level concerns outside the protocol's scope.

**Unauthorized access.** The primary attack vector is bypassing the Consent Protocol to access underlying data directly. HAVEN's structural enforcement — a Health Asset without a valid consent_ref is invalid — provides a protocol-level defense, but the underlying data storage mechanism is an implementation choice. Implementations must ensure that storage access is gated by consent verification and not accessible via alternative paths. The protocol cannot enforce this; it can only specify the requirement.

**Provenance tampering.** An adversary might attempt to modify or delete provenance entries to conceal unauthorized access. Theorem 6.5 establishes that modification of any entry is detectable by chain verification. Deletion of the final entry is undetectable at the chain level but is observable through external Merkle root anchoring. HAVEN recommends that implementations periodically anchor Merkle roots to external timestamping services (e.g., RFC 3161 [43]) or commit to a public append-only log.

**Re-identification.** Aggregated query results may permit re-identification of individual patients, particularly for patients with rare conditions or unusual combinations of attributes. HAVEN's MIN_COHORT_SIZE and AGGREGATION_ONLY consent conditions provide policy-level controls, but implementers must also apply algorithmic protections (k-anonymity [44], differential privacy [45], cell suppression) appropriate to the data and use case. Re-identification risk is a data sensitivity problem that the protocol can constrain but not fully prevent.

**Incentive gaming.** The Contribution Model creates incentives to inflate quality scores (to increase contribution values) or to fabricate data (to create assets that do not correspond to real patient records). Content addressing (I1) ensures that a submitted asset corresponds to the data it claims to reference, preventing post-hoc modification. But fabrication at submission time — submitting synthetic data as genuine clinical data — requires identity and data source verification, which HAVEN leaves to implementers. Gate 0 provenance validation requires a valid source signature, which constrains but does not eliminate the attack surface.

**Consent scope creep.** Broadly worded consent scope may grant access to data the patient did not intend to include. The closed-world semantics (Principle: silence = denial) limits this in one direction — scope must be explicit — but does not prevent patients from granting overly broad scope. Patient-facing interfaces that clearly communicate the implications of consent scope are an important complementary control; these are outside the protocol's scope.

**Cryptographic assumptions.** The tamper-evidence and non-repudiation properties rest on SHA-256 collision resistance [42] (~2^{128} security) and the security of Ed25519 [39] or ECDSA. Both are standard and widely deployed. Quantum computing poses a longer-term threat; if large-scale fault-tolerant quantum machines become practical, the protocol will need post-quantum signature schemes and hash functions. This is a shared vulnerability across all systems that depend on classical cryptography, not specific to HAVEN.

---

## 7. Discussion

### 7.1 Scope and Design Choices

The things HAVEN leaves unspecified are not afterthoughts. Several of them are harder problems than anything the protocol itself addresses.

**Data storage** is the most obvious omission. A Health Asset's `data_ref` field points to clinical data; the protocol says nothing about where that data lives or how it is protected at rest. Centralized databases, federated warehouses, compute-to-data architectures, patient-held encrypted storage — all are compatible, provided consent is verified before access and provenance is recorded. We expect different deployment contexts to make different choices, and the protocol should not foreclose any of them.

**Key management** is, candidly, the hardest unsolved problem in patient data sovereignty. HAVEN requires that consent be patient-authorized, but the mechanism by which patients hold, recover, delegate, and revoke cryptographic keys is entirely up to the implementation. Custodial models (a trusted party holds keys on the patient's behalf) are simpler but require trust. Self-sovereign models are more principled but expose patients to key loss. Social recovery and hardware security modules are promising but add complexity. The right answer depends on the population being served and the threat model. We chose not to specify this because specifying it badly would be worse than not specifying it at all.

**Identity proofing** faces a similar challenge. HAVEN requires that patients be authenticated when granting or revoking consent but takes no position on how. Patient identity in healthcare is hard even for systems that have been working on it for decades. The protocol's VerificationLevel field (SELF_ASSERTED, VERIFIED, AUTHENTICATED) at least makes the assurance level explicit.

**Payment mechanisms** are out of scope by design. The Contribution Model produces relative, dimensionless scores. Translating those scores into money requires a payment system, a value pool, and a governance structure for allocation — all of which depend on context. A public health surveillance program, an academic research consortium, and a commercial pharmaceutical trial will need different economic models. Mandating one would cripple adoption of the protocol in contexts where that model is wrong.

### 7.2 Ethical Considerations

Three tensions in HAVEN's design deserve candid discussion.

The first is the tension between autonomy and paternalism. HAVEN gives patients granular control over their data, including the ability to make choices that may not serve their interests — granting overly broad scope, consenting to uses by entities with conflicts of interest, or failing to revoke stale consents. A more paternalistic design might impose guardrails: maximum consent durations, mandatory cool-off periods, or blacklists of problematic grantees. We chose not to include these. The protocol provides the preconditions for informed consent — transparency, granularity, revocability — and leaves protective constraints to regulators and institutional review boards, where they arguably belong. But we recognize this as a genuine design tension, not a settled question.

The second tension concerns individual consent and collective benefit. Health data has externalities. A patient's records, when combined with thousands of others, can accelerate drug discovery or improve diagnostic AI in ways that benefit future patients. Consent regimes that make it easy for patients to withhold data may slow or block research with broad social value. HAVEN takes no position on whether individual consent should be required for all research uses; it provides the technical machinery for consent but does not dictate when that machinery must be invoked. Whether some uses should proceed under a legal authorization (GDPR legitimate interest, HIPAA de-identification safe harbor) is a policy question that sits above the protocol.

The third tension is about fairness in the absence of a market. The Contribution Model assigns relative weights, not prices. What those weights are worth depends on supply and demand for particular data types, the marginal value of a specific patient's records to a specific study, and negotiating dynamics that individual patients are poorly positioned to influence. Ostrom's analysis of commons governance [24] suggests that viable commons require clearly defined boundaries, locally adapted rules, collective choice arrangements, and conflict resolution — none of which HAVEN specifies. The protocol creates the accounting infrastructure for fair attribution. Whether fair outcomes actually result depends on the institutions and governance structures built around it.

### 7.3 Limitations

We are candid about what this paper does not do.

The correctness proofs in Section 6.1 are paper proofs, not machine-checked ones. They depend on the assumption that the verification algorithm is implemented correctly — an assumption that formal verification in Coq, Lean, or Isabelle could eliminate. We plan to pursue this but have not done it yet.

The quality gate thresholds (0.95 for Gate 1 pass, 0.90/0.70 for Gate 2, and 0.90/0.75/0.50 for quality class boundaries) are reference values. They are informed by general considerations of research data quality but have not been validated against real clinical data from specific sources. A genomics study and a population health survey almost certainly need different thresholds; we provide defaults and acknowledge that empirical calibration is necessary.

The Contribution Model computes relative weights, not prices. This is deliberate (Principle 6), but it means the formula by itself cannot power a functioning value exchange. Translating weights into compensation requires economic infrastructure — markets, payment systems, governance — that the protocol does not provide.

Most significantly, no implementation of HAVEN exists. This paper is entirely a protocol design and analysis paper. The behavior of the quality gates on real EHR data, the practical accuracy of the contribution formula relative to alternatives like Data Shapley [41], the usability of the consent model with real patients — all of these are open empirical questions. A reference implementation is planned.

Finally, the problems HAVEN leaves to implementers — key management, identity proofing, payment rails — are not peripheral. They are among the hardest problems in the space, and the feasibility of building a complete patient-sovereign system depends on solving them. The protocol design is sound, but a sound protocol is necessary and not sufficient.

### 7.4 Open Problems

1. **Formal verification of consent semantics.** Can the closed-world consent algorithm be formally verified using a proof assistant? Are there edge cases in the interaction between scope, exclusions, and conditions that the informal proofs do not capture?

2. **Quality gate threshold calibration.** What are the appropriate quality gate thresholds for different research use cases (drug safety, outcomes research, AI model training, genomics)? How do threshold choices affect the distribution of quality classes across real-world clinical data sources?

3. **Efficient Shapley approximation for large cohorts.** For clinical studies with tens of thousands of participants, what is the computational cost of Monte Carlo Shapley approximation to a given accuracy? Can kernel-based approximations (Data Shapley [41], KernelSHAP [46]) provide better accuracy-computation tradeoffs in the health data context?

4. **Consent interface design.** How can consent scope, purpose, and conditions be communicated to patients in a way that supports genuine informed consent without cognitive overload? What is the optimal level of granularity for patient-facing consent interfaces?

5. **Cross-system provenance verification.** How can provenance chains from different HAVEN-compliant systems be verified against each other? What trust anchors are needed for cross-system Merkle proof verification?

6. **Compliance mapping.** How do HAVEN's consent semantics map to specific legal frameworks (HIPAA authorization, GDPR consent, California CMIA)? Where are there gaps, and what additional implementation requirements do specific legal frameworks impose?

---

## 8. Conclusion

The health data ecosystem has a missing layer. Below it, interoperability standards (FHIR R4, OMOP CDM, SMART on FHIR) have made it technically feasible to move clinical data between systems at scale. Above it, AI systems and research platforms consume that data to generate substantial commercial and scientific value. The layer that is absent — the one that would give patients enforceable governance over their own records — is what HAVEN attempts to provide.

The protocol's contribution is narrow by design: four data structures, their operational semantics, and the formal properties that govern their interaction. A content-addressed Health Asset that cannot exist without a consent reference. A consent verification algorithm that is deterministic, immediately revocable, and defaults to denial. A hash-chained provenance log where tampering is detectable under standard cryptographic assumptions. A quality-gated contribution formula that produces auditable, attributable measures of patient data value.

Whether this protocol design leads to working systems depends on problems we have not solved here — key management, identity, payment infrastructure, consent interface design — and on empirical questions we have not yet tested. We are aware of these gaps. A reference implementation will follow.

The broader question, though, is one of timing. Foundation models are being trained on clinical data now. Once a model is trained, the provenance of its training data is permanently lost in the weights. The window for building governance infrastructure that preserves patient agency is open, but it has a finite duration. We hope this work contributes to closing the gap before it becomes permanent.

The protocol specification is released under CC BY 4.0. The formal specifications, test vectors, and TypeSpec definitions are available at https://github.com/Chesterguan/HAVEN. This paper is archived at Zenodo: [https://doi.org/10.5281/zenodo.18701303](https://doi.org/10.5281/zenodo.18701303).

---

## References

[1] Mandel, J. C., Kreda, D. A., Mandl, K. D., Kohane, I. S., and Ramoni, R. B. "SMART on FHIR: A standards-based, interoperable apps platform for electronic health records." *Journal of the American Medical Informatics Association* 23.5 (2016): 899–908.

[2] OHDSI. "OHDSI Network Statistics." Observational Health Data Sciences and Informatics, 2024. https://ohdsi.org/

[3] Microsoft Corporation. "HealthVault Service Discontinuation Notice." Microsoft Health Blog, 2019.

[4] Google Inc. "An update on Google Health and Google PowerMeter." Official Google Blog, 2011.

[5] OpenAI. "GPT-4 Technical Report." arXiv:2303.08774, 2023.

[6] Singhal, K., Azizi, S., Tu, T., Mahdavi, S. S., Wei, J., Chung, H. W., et al. "Large Language Models Encode Clinical Knowledge." *Nature* 620 (2023): 172–180. (arXiv:2212.13138.)

[7] Grand View Research. "Clinical Trials Market Size, Share & Trends Analysis Report, 2024–2033." 2024.

[8] Fogel, D. B. "Factors associated with clinical trials that fail and opportunities for improving the likelihood of success." *Contemporary Clinical Trials Communications* 11 (2018): 156–164.

[9] Sertkaya, A., Wong, H. H., Jessup, A., and Beleche, T. "Key cost drivers of pharmaceutical clinical trials in the United States." *Clinical Trials* 13.2 (2016): 117–126.

[10] TriNetX. "Real-World Data Access Benchmarks." TriNetX Network Report, 2023.

[11] HL7 International. "FHIR R4 Specification." HL7, 2019. https://hl7.org/fhir/R4/

[12] OHDSI. "OMOP Common Data Model v6.0." OHDSI, 2021. https://ohdsi.github.io/CommonDataModel/

[13] U.S. Department of Health and Human Services. "Standards for Privacy of Individually Identifiable Health Information." 45 CFR Parts 160 and 164, 2000.

[14] European Parliament and Council of the European Union. "General Data Protection Regulation." Regulation (EU) 2016/679, 2016.

[15] Zuboff, S. *The Age of Surveillance Capitalism: The Fight for a Human Future at the New Frontier of Power.* PublicAffairs, 2019.

[16] Lanier, J. *Who Owns the Future?* Simon & Schuster, 2013.

[17] Locke, J. *Two Treatises of Government.* 1689. Chapter V: "Of Property."

[18] Beauchamp, T. L., and Childress, J. F. *Principles of Biomedical Ethics.* 8th ed. Oxford University Press, 2019.

[19] Lessig, L. *Code: Version 2.0.* Basic Books, 2006.

[20] "The Nuremberg Code." In *Trials of War Criminals before the Nuremberg Military Tribunals under Control Council Law No. 10.* U.S. Government Printing Office, 1949.

[21] National Commission for the Protection of Human Subjects of Biomedical and Behavioral Research. *The Belmont Report: Ethical Principles and Guidelines for the Protection of Human Subjects of Research.* U.S. Department of Health, Education, and Welfare, 1979.

[22] Nissenbaum, H. "Privacy as Contextual Integrity." *Washington Law Review* 79.1 (2004): 119–158.

[23] Rawls, J. *A Theory of Justice.* Harvard University Press, 1971.

[24] Ostrom, E. *Governing the Commons: The Evolution of Institutions for Collective Action.* Cambridge University Press, 1990.

[25] Centers for Medicare & Medicaid Services (CMS). "Medicare and Medicaid Programs; Patient Protection and Affordable Care Act; Interoperability and Patient Access for Medicare Advantage Organizations." *Federal Register* 85 FR 25510. Final Rule, May 1, 2020.

[26] Hardt, D. (Ed.). "The OAuth 2.0 Authorization Framework." RFC 6749, Internet Engineering Task Force (IETF), October 2012. https://datatracker.ietf.org/doc/html/rfc6749

[27] 21st Century Cures Act, Pub. L. No. 114-255, 130 Stat. 1033, 2016. https://www.congress.gov/bill/114th-congress/house-bill/34

[28] Apple Inc. "Health Records on iPhone." Apple Developer Documentation, 2018. https://developer.apple.com/health-records/

[29] The Commons Project. "CommonHealth: Personal Health Data on Android." 2020. https://www.commonhealth.org/

[30] McConaghy, T. et al. *Ocean Protocol: Tools for the Web3 Data Economy.* Ocean Protocol Foundation, Technical Whitepaper, 2020. https://oceanprotocol.com/tech-whitepaper.pdf

[31] Sambra, A. V., Mansour, E., Hawke, S., Zereba, M., Greco, N., Ghanem, A., Zagidulin, D., Aboulnaga, A., and Berners-Lee, T. "Solid: A Platform for Decentralized Social Applications Based on Linked Data." MIT CSAIL & Qatar Computing Research Institute, Technical Report, 2016.

[32] Office of the National Coordinator for Health Information Technology (ONC). "Trusted Exchange Framework and Common Agreement (TEFCA)." *Federal Register* 87 FR 2800, January 19, 2022. https://www.healthit.gov/topic/interoperability/policy/trusted-exchange-framework-and-common-agreement-tefca

[33] Torvalds, L. and Hamano, J. C. *Git: Fast Version Control System* [Computer software], 2005. https://git-scm.com/

[34] World Health Organization (WHO). *International Statistical Classification of Diseases and Related Health Problems, 10th Revision (ICD-10).* Geneva: World Health Organization, 1992.

[35] SNOMED International. *SNOMED CT (Systematized Nomenclature of Medicine — Clinical Terms).* SNOMED International, London, United Kingdom. https://www.snomed.org/

[36] McDonald, C. J., Huff, S. M., Suico, J. G., Hill, G., et al. "LOINC, a Universal Standard for Identifying Laboratory Observations: A 5-Year Update." *Clinical Chemistry* 49.4 (2003): 624–633.

[37] Nelson, S. J., Zeng, K., Kilbourne, J., Powell, T., and Moore, R. "Normalized names for clinical drugs: RxNorm at 6 years." *Journal of the American Medical Informatics Association* 18.4 (2011): 441–448.

[38] Reiter, R. "On Closed World Data Bases." In H. Gallaire and J. Minker (Eds.), *Logic and Data Bases*, pp. 55–76. Plenum Press, New York, 1978.

[39] Bernstein, D. J., Duif, N., Lange, T., Schwabe, P., and Yang, B.-Y. "High-speed high-security signatures." *Journal of Cryptographic Engineering* 2.2 (2012): 77–89.

[40] Merkle, R. C. "A Digital Signature Based on a Conventional Encryption Function." In C. Pomerance (Ed.), *Advances in Cryptology — CRYPTO '87*, Lecture Notes in Computer Science, vol. 293, pp. 369–378. Springer, 1987.

[41] Ghorbani, A. and Zou, J. "Data Shapley: Equitable Valuation of Data for Machine Learning." In *Proceedings of the 36th International Conference on Machine Learning (ICML 2019)*, PMLR vol. 97, pp. 2242–2251, 2019.

[42] National Institute of Standards and Technology (NIST). *Secure Hash Standard (SHS).* Federal Information Processing Standards Publication 180-4. U.S. Department of Commerce, 2015. https://csrc.nist.gov/pubs/fips/180-4/upd1/final

[43] Adams, C., Cain, P., Pinkas, D., and Zuccherato, R. "Internet X.509 Public Key Infrastructure Time-Stamp Protocol (TSP)." RFC 3161, Internet Engineering Task Force (IETF), August 2001. https://datatracker.ietf.org/doc/html/rfc3161

[44] Sweeney, L. "k-Anonymity: A Model for Protecting Privacy." *International Journal of Uncertainty, Fuzziness and Knowledge-Based Systems* 10.5 (2002): 557–570.

[45] Dwork, C. "Differential Privacy." In *Automata, Languages and Programming: 33rd International Colloquium (ICALP 2006), Part II*, Lecture Notes in Computer Science, vol. 4052, pp. 1–12. Springer, 2006.

[46] Lundberg, S. M. and Lee, S.-I. "A Unified Approach to Interpreting Model Predictions." In *Advances in Neural Information Processing Systems 30 (NeurIPS 2017)*, pp. 4765–4774, 2017.

---

*February 2026. This work is released under Creative Commons Attribution 4.0 International (CC BY 4.0). DOI: [10.5281/zenodo.18701303](https://doi.org/10.5281/zenodo.18701303)*
