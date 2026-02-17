# HAVEN Specification 003: Provenance Record

**Status**: Draft
**Version**: 2.0.0
**Date**: January 28, 2026
**Authors**: Chester Guan

---

## 1. Overview

The **Provenance Record** is an append-only audit trail of all governance events in HAVEN. Every data access, consent change, and asset operation creates an immutable, cryptographically-linked entry that enables complete transparency and accountability.

### 1.1 Design Goals

1. **Append-only**: Entries cannot be modified or deleted
2. **Hash-chained**: Each entry links to its predecessor via cryptographic hash
3. **Cryptographically signed**: All entries carry verifiable signatures
4. **Queryable**: Patients can efficiently retrieve and verify their history
5. **Efficient verification**: O(log n) proof verification via Merkle tree

### 1.2 Scope

This specification defines:
- The ProvenanceEntry data structure
- Event types and their semantics
- Hash chain construction
- Merkle tree verification
- Query operations

---

## 2. Data Model

### 2.1 Provenance Entry Structure

```
ProvenanceEntry := {
    entry_id        : EntryID           // REQUIRED - Unique entry identifier
    chain_id        : ChainID           // REQUIRED - Provenance chain identifier
    sequence        : integer           // REQUIRED - Position in chain (0-indexed)
    timestamp       : Timestamp         // REQUIRED - When event occurred
    event_type      : EventType         // REQUIRED - Category of event
    actor           : ActorIdentity     // REQUIRED - Who performed the action
    subject         : SubjectRef        // REQUIRED - What was affected
    details         : EventDetails      // REQUIRED - Event-specific data
    previous_hash   : Hash | null       // REQUIRED - Hash of previous entry (null for genesis)
    entry_hash      : Hash              // REQUIRED - Hash of this entry
    signature       : CryptoSignature   // REQUIRED - Actor's signature
    merkle_proof    : MerkleProof       // OPTIONAL - Inclusion proof
}
```

### 2.2 Field Definitions

#### 2.2.1 entry_id (EntryID)

Unique identifier for this provenance entry.

**Format**: `prov:<chain_id>:entry:<sequence>`

**Example**: `prov:abc123:entry:42`

**Constraints**:
- MUST be derived from chain_id and sequence
- MUST be unique within the HAVEN instance

#### 2.2.2 chain_id (ChainID)

Identifier for the provenance chain (typically per-patient).

**Format**: UUID v4

**Constraints**:
- One chain per patient (recommended)
- MUST be stable for patient's lifetime in system

#### 2.2.3 sequence (integer)

Zero-indexed position in the provenance chain.

**Constraints**:
- Genesis entry has sequence = 0
- Each subsequent entry increments by 1
- No gaps allowed

#### 2.2.4 event_type (EventType)

Category of governance event.

**Enumerated Values**:

| Event Type | Category | Description |
|------------|----------|-------------|
| `ASSET_CREATED` | Asset | New Health Asset registered |
| `ASSET_ACCESSED` | Asset | Health Asset data retrieved |
| `ASSET_EXPORTED` | Asset | Health Asset exported to external system |
| `ASSET_DELETED` | Asset | Health Asset removed (soft delete) |
| `ASSET_QUALITY_UPDATED` | Asset | Quality class reassessed |
| `CONSENT_GRANTED` | Consent | New consent attestation created |
| `CONSENT_VERIFIED` | Consent | Consent checked for access decision |
| `CONSENT_REVOKED` | Consent | Patient withdrew consent |
| `CONSENT_EXPIRED` | Consent | Consent reached expiration |
| `CONSENT_REJECTED` | Consent | Patient declined consent request |
| `QUERY_EXECUTED` | Query | Research query ran against data |
| `QUERY_RESULT_RELEASED` | Query | Query results released to requester |
| `COMPUTATION_STARTED` | Compute | Computation began on patient data |
| `COMPUTATION_COMPLETED` | Compute | Computation finished |
| `MODEL_TRAINED` | AI | ML model trained using patient data |
| `MODEL_INFERENCE` | AI | ML model made prediction using patient data |
| `CONTRIBUTION_RECORDED` | Value | Patient contribution quantified |
| `COMPENSATION_DISTRIBUTED` | Value | Value distributed to patient |
| `IDENTITY_VERIFIED` | Identity | Patient identity verification event |
| `DELEGATION_GRANTED` | Identity | Access delegation created |
| `DELEGATION_REVOKED` | Identity | Access delegation removed |
| `SYSTEM_AUDIT` | System | System-level audit event |

#### 2.2.5 actor (ActorIdentity)

The entity that performed the action.

**Structure**:
```
ActorIdentity := {
    id              : string            // REQUIRED
    type            : ActorType         // REQUIRED
    name            : string            // OPTIONAL
    on_behalf_of    : ActorIdentity     // OPTIONAL - Delegation chain
}

ActorType := {
    PATIENT,        // Patient themselves
    CLINICIAN,      // Healthcare provider
    RESEARCHER,     // Research accessor
    SYSTEM,         // Automated system process
    ADMINISTRATOR,  // System administrator
    DELEGATE        // Acting on behalf of patient
}
```

#### 2.2.6 subject (SubjectRef)

What was affected by this event.

**Structure**:
```
SubjectRef := {
    type            : SubjectType       // REQUIRED
    id              : string            // REQUIRED
    additional_refs : string[]          // OPTIONAL - Related subjects
}

SubjectType := {
    HEALTH_ASSET,
    CONSENT_ATTESTATION,
    PATIENT,
    QUERY,
    COMPUTATION,
    MODEL,
    CONTRIBUTION
}
```

**Example**:
```json
{
  "type": "HEALTH_ASSET",
  "id": "sha256:a1b2c3...",
  "additional_refs": ["consent:550e8400..."]
}
```

#### 2.2.7 details (EventDetails)

Event-specific data. Structure varies by event_type.

**ASSET_CREATED**:
```json
{
  "asset_id": "sha256:...",
  "substrate": "FHIR-R4",
  "quality_class": "A",
  "consent_ref": "consent:...",
  "source_system": "epic-mychart"
}
```

**ASSET_ACCESSED**:
```json
{
  "asset_id": "sha256:...",
  "consent_ref": "consent:...",
  "access_type": "READ",
  "purpose": "RESEARCH",
  "fields_accessed": ["*"],
  "result_size_bytes": 4096
}
```

**CONSENT_GRANTED**:
```json
{
  "consent_id": "uuid:...",
  "grantee": "study:diabetes-cgm-2026",
  "scope_summary": "Labs, Conditions, Medications (2020-present)",
  "expires_at": "2027-01-28T10:30:00Z"
}
```

**CONSENT_REVOKED**:
```json
{
  "consent_id": "uuid:...",
  "reason": "Patient requested",
  "immediate_effect": true
}
```

**QUERY_EXECUTED**:
```json
{
  "query_id": "query:...",
  "query_type": "COHORT_COUNT",
  "consent_refs": ["consent:..."],
  "assets_scanned": 15,
  "records_matched": 847,
  "execution_ms": 234
}
```

**CONTRIBUTION_RECORDED**:
```json
{
  "contribution_id": "contrib:...",
  "usage_context": "study:diabetes-cgm-2026",
  "assets_contributed": 5,
  "quality_score": 0.92,
  "tier": "LONGITUDINAL",
  "calculated_value": 0.83
}
```

#### 2.2.8 previous_hash (Hash)

SHA-256 hash of the previous entry in the chain.

**Format**: `sha256:<64 hex chars>`

**Constraints**:
- MUST be null for genesis entry (sequence = 0)
- MUST equal the `entry_hash` of entry with sequence - 1

#### 2.2.9 entry_hash (Hash)

SHA-256 hash of this entry's canonical form.

**Computation**:
1. Create JSON with all fields except `entry_hash` and `merkle_proof`
2. Sort keys alphabetically (recursive)
3. Minify (remove whitespace)
4. Compute SHA-256
5. Format as `sha256:<hex>`

#### 2.2.10 signature (CryptoSignature)

Actor's cryptographic signature over the entry.

**Signed content**: `entry_hash` value

**Structure**: Same as Consent Protocol signature (see Spec 002)

---

## 3. Hash Chain Construction

### 3.1 Genesis Entry

The first entry in a provenance chain (sequence = 0) is the genesis entry.

**Requirements**:
- `previous_hash` MUST be null
- `event_type` SHOULD be `SYSTEM_AUDIT` with details indicating chain creation
- `entry_hash` computed normally

**Example**:
```json
{
  "entry_id": "prov:chain001:entry:0",
  "chain_id": "chain001",
  "sequence": 0,
  "timestamp": "2026-01-28T00:00:00.000Z",
  "event_type": "SYSTEM_AUDIT",
  "actor": {"id": "system:haven", "type": "SYSTEM"},
  "subject": {"type": "PATIENT", "id": "patient:alice-12345"},
  "details": {"event": "CHAIN_CREATED", "patient_id": "patient:alice-12345"},
  "previous_hash": null,
  "entry_hash": "sha256:genesis...",
  "signature": {...}
}
```

### 3.2 Subsequent Entries

Each entry after genesis links to its predecessor.

**Invariants**:
1. `entry[n].previous_hash == entry[n-1].entry_hash`
2. `entry[n].sequence == entry[n-1].sequence + 1`
3. `entry[n].timestamp >= entry[n-1].timestamp`

### 3.3 Chain Integrity Verification

To verify chain integrity from entry 0 to N:

```
function verifyChain(entries: ProvenanceEntry[]) → boolean:
    if entries[0].previous_hash != null:
        return false  // Genesis must have null previous_hash

    for i = 1 to len(entries) - 1:
        // Verify hash linkage
        if entries[i].previous_hash != entries[i-1].entry_hash:
            return false

        // Verify sequence
        if entries[i].sequence != entries[i-1].sequence + 1:
            return false

        // Verify temporal ordering
        if entries[i].timestamp < entries[i-1].timestamp:
            return false

        // Verify entry hash is correctly computed
        if computeEntryHash(entries[i]) != entries[i].entry_hash:
            return false

        // Verify signature
        if not verifySignature(entries[i]):
            return false

    return true
```

---

## 4. Merkle Tree Structure

### 4.1 Purpose

Merkle trees enable efficient O(log n) proofs that a specific entry exists in the chain without requiring the full chain.

### 4.2 Tree Construction

```
                    Root Hash
                   /         \
              H(AB)           H(CD)
             /     \         /     \
          H(A)     H(B)   H(C)     H(D)
           |        |       |        |
        Entry 0  Entry 1  Entry 2  Entry 3
```

**Construction Algorithm**:
1. Leaf nodes are `entry_hash` values
2. Parent nodes are SHA-256 of concatenated children (left || right)
3. If odd number of nodes, duplicate the last node
4. Continue until single root

### 4.3 Merkle Proof

A Merkle proof demonstrates entry inclusion with O(log n) hashes.

**Structure**:
```
MerkleProof := {
    root_hash       : Hash              // Merkle root at proof time
    leaf_index      : integer           // Position of entry's hash
    path            : ProofNode[]       // Sibling hashes from leaf to root
    tree_size       : integer           // Number of leaves when proof generated
}

ProofNode := {
    hash            : Hash
    position        : "LEFT" | "RIGHT"  // Sibling position
}
```

### 4.4 Proof Verification

```
function verifyMerkleProof(entry_hash, proof: MerkleProof) → boolean:
    current = entry_hash

    for node in proof.path:
        if node.position == "LEFT":
            current = sha256(node.hash || current)
        else:
            current = sha256(current || node.hash)

    return current == proof.root_hash
```

---

## 5. Operations

### 5.1 append()

Adds a new entry to the provenance chain.

**Signature**:
```
append(
    chain_id: ChainID,
    event_type: EventType,
    actor: ActorIdentity,
    subject: SubjectRef,
    details: EventDetails
) → ProvenanceEntry | Error
```

**Preconditions**:
- `actor` MUST be authenticated
- `actor` MUST be authorized to record this event type
- Chain MUST exist (or use `createChain` first)

**Postconditions**:
- Entry persisted with correct linkage
- Merkle tree updated
- Entry is immutable

**Atomicity**: The append operation MUST be atomic. Either the entry is fully persisted with correct linkage, or no change occurs.

### 5.2 get()

Retrieves a specific provenance entry.

**Signature**:
```
get(
    entry_id: EntryID
) → ProvenanceEntry | Error
```

### 5.3 getChain()

Retrieves a range of entries from a chain.

**Signature**:
```
getChain(
    chain_id: ChainID,
    from_sequence?: integer,
    to_sequence?: integer,
    include_proofs?: boolean
) → ProvenanceEntry[]
```

**Defaults**:
- `from_sequence`: 0
- `to_sequence`: latest
- `include_proofs`: false

### 5.4 query()

Queries provenance entries with filters.

**Signature**:
```
query(
    chain_id: ChainID,
    filters: ProvenanceFilters
) → ProvenanceEntry[]
```

**Filters**:
```
ProvenanceFilters := {
    event_types?: EventType[],
    actor_id?: string,
    subject_id?: string,
    subject_type?: SubjectType,
    from_timestamp?: Timestamp,
    to_timestamp?: Timestamp,
    limit?: integer,
    offset?: integer
}
```

### 5.5 verify()

Verifies chain integrity and/or entry inclusion.

**Signature**:
```
verify(
    chain_id: ChainID,
    entry_id?: EntryID,
    full_chain?: boolean
) → VerificationResult
```

**Returns**:
```
VerificationResult := {
    valid: boolean,
    chain_length: integer,
    verified_entries: integer,
    merkle_root: Hash,
    errors: VerificationError[]
}
```

### 5.6 getMerkleProof()

Generates a Merkle proof for an entry.

**Signature**:
```
getMerkleProof(
    entry_id: EntryID
) → MerkleProof | Error
```

---

## 6. Serialization

### 6.1 JSON Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": [
    "entry_id",
    "chain_id",
    "sequence",
    "timestamp",
    "event_type",
    "actor",
    "subject",
    "details",
    "entry_hash",
    "signature"
  ],
  "properties": {
    "entry_id": {
      "type": "string",
      "pattern": "^prov:[a-zA-Z0-9]+:entry:[0-9]+$"
    },
    "chain_id": {
      "type": "string"
    },
    "sequence": {
      "type": "integer",
      "minimum": 0
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "event_type": {
      "type": "string",
      "enum": [
        "ASSET_CREATED", "ASSET_ACCESSED", "ASSET_EXPORTED", "ASSET_DELETED",
        "CONSENT_GRANTED", "CONSENT_VERIFIED", "CONSENT_REVOKED", "CONSENT_EXPIRED",
        "QUERY_EXECUTED", "QUERY_RESULT_RELEASED",
        "COMPUTATION_STARTED", "COMPUTATION_COMPLETED",
        "MODEL_TRAINED", "MODEL_INFERENCE",
        "CONTRIBUTION_RECORDED", "COMPENSATION_DISTRIBUTED",
        "IDENTITY_VERIFIED", "DELEGATION_GRANTED", "DELEGATION_REVOKED",
        "SYSTEM_AUDIT", "ASSET_QUALITY_UPDATED", "CONSENT_REJECTED"
      ]
    },
    "actor": {
      "$ref": "#/$defs/ActorIdentity"
    },
    "subject": {
      "$ref": "#/$defs/SubjectRef"
    },
    "details": {
      "type": "object"
    },
    "previous_hash": {
      "type": ["string", "null"],
      "pattern": "^sha256:[a-f0-9]{64}$"
    },
    "entry_hash": {
      "type": "string",
      "pattern": "^sha256:[a-f0-9]{64}$"
    },
    "signature": {
      "$ref": "#/$defs/CryptoSignature"
    },
    "merkle_proof": {
      "$ref": "#/$defs/MerkleProof"
    }
  }
}
```

---

## 7. Conformance Requirements

### 7.1 MUST Requirements

Implementations MUST:

1. **M1**: Maintain append-only semantics (no modification or deletion)
2. **M2**: Compute and verify hash chain linkage
3. **M3**: Verify signatures on all entries
4. **M4**: Provide O(log n) Merkle proofs
5. **M5**: Record provenance for all asset and consent operations
6. **M6**: Maintain temporal ordering (no backdated entries)
7. **M7**: Support genesis entry with null previous_hash

### 7.2 SHOULD Requirements

Implementations SHOULD:

1. **S1**: Persist Merkle tree for efficient proof generation
2. **S2**: Support efficient range queries
3. **S3**: Archive old entries to cold storage with proofs
4. **S4**: Replicate provenance data for durability

### 7.3 MAY Requirements

Implementations MAY:

1. **O1**: Anchor Merkle roots to external timestamping services
2. **O2**: Support cross-chain verification
3. **O3**: Implement real-time provenance streaming
4. **O4**: Provide provenance visualization tools

---

## 8. Security Considerations

### 8.1 Threat Model

| Threat | Description | Mitigation |
|--------|-------------|------------|
| History rewriting | Modifying past entries | Hash chain prevents undetected changes |
| Entry insertion | Adding fake entries | Signatures verify actor authenticity |
| Denial of service | Flooding with entries | Rate limiting, authentication |
| Privacy leakage | Exposing sensitive details | Minimal detail in entries |
| Time manipulation | Backdating entries | Timestamp verification, external anchoring |

### 8.2 Implementation Guidance

- Use hardware timestamping where possible
- Consider external Merkle root anchoring (blockchain, RFC 3161)
- Implement retention policies for compliance
- Encrypt details field if contains sensitive data
- Monitor for anomalous provenance patterns

---

## 9. Examples

### 9.1 Asset Creation Event

```json
{
  "entry_id": "prov:chain001:entry:42",
  "chain_id": "chain001",
  "sequence": 42,
  "timestamp": "2026-01-28T10:30:00.000Z",
  "event_type": "ASSET_CREATED",
  "actor": {
    "id": "patient:alice-12345",
    "type": "PATIENT"
  },
  "subject": {
    "type": "HEALTH_ASSET",
    "id": "sha256:7d865e959b2466918c9863afca942d0fb89d7c9ac0c99bafc3749504ded97730"
  },
  "details": {
    "asset_id": "sha256:7d865e959b2466918c9863afca942d0fb89d7c9ac0c99bafc3749504ded97730",
    "substrate": "FHIR-R4",
    "quality_class": "A",
    "consent_ref": "consent:550e8400-e29b-41d4-a716-446655440000",
    "source_system": "epic-mychart"
  },
  "previous_hash": "sha256:prev123...",
  "entry_hash": "sha256:entry42...",
  "signature": {
    "algorithm": "ED25519",
    "public_key_id": "did:haven:alice#key-1",
    "value": "MEUCIQDx...",
    "signed_at": "2026-01-28T10:30:00.000Z"
  }
}
```

### 9.2 Query Execution Event

```json
{
  "entry_id": "prov:chain001:entry:100",
  "chain_id": "chain001",
  "sequence": 100,
  "timestamp": "2026-01-28T14:45:30.123Z",
  "event_type": "QUERY_EXECUTED",
  "actor": {
    "id": "researcher:bob@stanford.edu",
    "type": "RESEARCHER"
  },
  "subject": {
    "type": "QUERY",
    "id": "query:q-12345",
    "additional_refs": ["sha256:asset1...", "sha256:asset2..."]
  },
  "details": {
    "query_id": "query:q-12345",
    "query_type": "COHORT_ANALYSIS",
    "consent_refs": ["consent:550e8400..."],
    "assets_scanned": 5,
    "records_matched": 847,
    "execution_ms": 234,
    "purpose": "RESEARCH"
  },
  "previous_hash": "sha256:prev99...",
  "entry_hash": "sha256:entry100...",
  "signature": {
    "algorithm": "ED25519",
    "public_key_id": "did:haven:system#query-service",
    "value": "MEYCIQCw...",
    "signed_at": "2026-01-28T14:45:30.123Z"
  }
}
```

---

## 10. Test Vectors

See `/test-vectors/provenance/` for conformance test data.

### 10.1 Chain Verification Test Cases

| Test Case | Expected Result |
|-----------|-----------------|
| Valid genesis entry (previous_hash = null) | VALID |
| Valid chain linkage | VALID |
| Broken hash link | INVALID |
| Gap in sequence numbers | INVALID |
| Timestamp out of order | INVALID |
| Invalid signature | INVALID |
| Missing required field | INVALID |

---

## 11. References

- [Merkle Tree (Wikipedia)](https://en.wikipedia.org/wiki/Merkle_tree)
- [RFC 3161 - Timestamping](https://datatracker.ietf.org/doc/html/rfc3161)
- [W3C PROV-O](https://www.w3.org/TR/prov-o/)

---

*HAVEN Specification 003 | Version 2.0.0 | January 28, 2026*
