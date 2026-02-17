# HAVEN Specification 006: Exchange Bundle

**Status**: Draft
**Version**: 2.0.0
**Date**: February 13, 2026
**Authors**: Chester Guan

---

## 1. Overview

The **Exchange Bundle** defines a standard format for transferring HAVEN data between systems. It enables interoperability across different HAVEN implementations while maintaining integrity and provenance.

### 1.1 Use Cases

1. **Patient portability** - Patient moves from System A to System B
2. **Research collaboration** - Institutions share authorized data
3. **Backup/export** - Patient exports their complete record
4. **Audit** - Third-party verification of provenance

### 1.2 Scope

This specification defines:
- Bundle structure and required fields
- Integrity verification
- Signature requirements
- Processing semantics

---

## 2. Data Model

### 2.1 Exchange Bundle Structure

```
ExchangeBundle := {
    bundle_id       : UUID              // REQUIRED - Unique bundle identifier
    version         : string            // REQUIRED - HAVEN protocol version
    created_at      : Timestamp         // REQUIRED - Bundle creation time
    created_by      : ActorIdentity     // REQUIRED - Who created the bundle

    // Payload
    assets          : HealthAsset[]     // Health Assets included
    consents        : ConsentAttestation[] // Related consents
    provenance      : ProvenanceEntry[] // Provenance entries
    contributions   : Contribution[]    // Contribution records

    // Integrity
    bundle_hash     : ContentHash       // REQUIRED - Hash of payload
    signature       : CryptoSignature   // REQUIRED - Creator's signature

    // Metadata
    metadata        : BundleMetadata    // OPTIONAL - Additional context
}
```

### 2.2 Field Definitions

#### 2.2.1 bundle_id (UUID)

Unique identifier for this bundle.

**Format**: UUID v4

**Constraints**:
- MUST be unique across all bundles from the creating system
- SHOULD be globally unique

#### 2.2.2 version (string)

HAVEN protocol version this bundle conforms to.

**Format**: Semantic versioning (e.g., "2.0.0")

**Constraints**:
- MUST match a released HAVEN protocol version
- Receiving system MUST reject bundles with incompatible versions

#### 2.2.3 created_at (Timestamp)

When the bundle was created.

**Format**: ISO 8601 UTC with milliseconds

**Constraints**:
- MUST NOT be in the future
- SHOULD be within reasonable time of transmission

#### 2.2.4 created_by (ActorIdentity)

The entity that created this bundle.

**Structure**: Same as Provenance Record ActorIdentity

#### 2.2.5 assets (HealthAsset[])

Array of Health Assets to transfer.

**Constraints**:
- Each asset MUST be valid per spec/001-health-asset.md
- Asset references (consent_ref, provenance_ref) SHOULD be resolvable within the bundle or the receiving system

#### 2.2.6 consents (ConsentAttestation[])

Consent attestations relevant to the included assets.

**Constraints**:
- Each consent MUST be valid per spec/002-consent-protocol.md
- SHOULD include all consents referenced by included assets

#### 2.2.7 provenance (ProvenanceEntry[])

Provenance entries for included assets and consents.

**Constraints**:
- Each entry MUST be valid per spec/003-provenance-record.md
- SHOULD maintain hash chain integrity within the bundle
- MAY be a subset of the full chain (with Merkle proofs)

#### 2.2.8 contributions (Contribution[])

Contribution records for included assets.

**Constraints**:
- Each contribution MUST be valid per spec/004-contribution-model.md
- OPTIONAL - may be empty

#### 2.2.9 bundle_hash (ContentHash)

Hash of the bundle payload for integrity verification.

**Computation**:
1. Create canonical JSON of payload (assets, consents, provenance, contributions)
2. Sort keys alphabetically (recursive)
3. Compute SHA-256
4. Format as `sha256:<hex>`

**Note**: bundle_id, version, created_at, created_by are NOT included in the hash (they are envelope metadata).

#### 2.2.10 signature (CryptoSignature)

Creator's signature over the bundle_hash.

**Structure**: Same as Consent Protocol signature

**Constraints**:
- MUST be verifiable using creator's public key
- Algorithm MUST be ED25519 or ES256

#### 2.2.11 metadata (BundleMetadata) - OPTIONAL

Additional context about the bundle.

```
BundleMetadata := {
    purpose         : string            // Why this bundle was created
    source_system   : string            // Originating system identifier
    destination     : string            // Intended recipient (if known)
    patient_ref     : PatientID         // If bundle is for single patient
    expires_at      : Timestamp         // Bundle expiration (optional)
    tags            : string[]          // Classification tags
    extensions      : Record<unknown>   // Implementation-specific
}
```

---

## 3. Bundle Types

### 3.1 Full Export

Complete patient record export.

```json
{
  "bundle_id": "...",
  "version": "2.0.0",
  "metadata": {
    "purpose": "FULL_EXPORT",
    "patient_ref": "patient:alice-12345"
  },
  "assets": [...all patient's assets...],
  "consents": [...all patient's consents...],
  "provenance": [...complete chain...],
  "contributions": [...all contributions...]
}
```

### 3.2 Selective Share

Specific data shared for a purpose.

```json
{
  "bundle_id": "...",
  "version": "2.0.0",
  "metadata": {
    "purpose": "RESEARCH_SHARE",
    "destination": "study:diabetes-cgm-2026"
  },
  "assets": [...only consented assets...],
  "consents": [...relevant consent...],
  "provenance": [...relevant entries with Merkle proofs...],
  "contributions": []
}
```

### 3.3 Provenance Proof

Audit trail without data.

```json
{
  "bundle_id": "...",
  "version": "2.0.0",
  "metadata": {
    "purpose": "AUDIT_PROOF"
  },
  "assets": [],
  "consents": [],
  "provenance": [...entries with Merkle proofs...],
  "contributions": []
}
```

---

## 4. Operations

### 4.1 create()

Creates a new Exchange Bundle.

**Signature**:
```
create(
    assets: HealthAsset[],
    consents: ConsentAttestation[],
    provenance: ProvenanceEntry[],
    contributions: Contribution[],
    metadata?: BundleMetadata
) → ExchangeBundle | Error
```

**Preconditions**:
- Creator MUST be authorized to export included data
- All referenced objects MUST be valid

**Postconditions**:
- bundle_hash is computed
- signature is applied
- Provenance entry ASSET_EXPORTED recorded for each asset

### 4.2 verify()

Verifies bundle integrity and authenticity.

**Signature**:
```
verify(
    bundle: ExchangeBundle
) → VerificationResult
```

**Checks**:
1. bundle_hash matches computed hash of payload
2. signature is valid for bundle_hash
3. All assets are valid
4. All consents are valid
5. Provenance chain is intact (or Merkle proofs valid)

**Returns**:
```
VerificationResult := {
    valid: boolean,
    hash_valid: boolean,
    signature_valid: boolean,
    assets_valid: boolean,
    consents_valid: boolean,
    provenance_valid: boolean,
    errors: string[]
}
```

### 4.3 import()

Imports a verified bundle into a HAVEN system.

**Signature**:
```
import(
    bundle: ExchangeBundle,
    options?: ImportOptions
) → ImportResult | Error
```

**Options**:
```
ImportOptions := {
    conflict_resolution: "REJECT" | "SKIP" | "MERGE",
    verify_signatures: boolean,
    record_provenance: boolean
}
```

**Postconditions**:
- Assets are stored (or merged)
- Consents are recorded
- Provenance is appended (not replaced)
- SYSTEM_AUDIT entry recorded for import

---

## 5. Serialization

### 5.1 JSON Format (Normative)

```json
{
  "bundle_id": "550e8400-e29b-41d4-a716-446655440000",
  "version": "2.0.0",
  "created_at": "2026-02-13T10:30:00.000Z",
  "created_by": {
    "id": "system:haven-export",
    "type": "SYSTEM",
    "name": "HAVEN Export Service"
  },
  "assets": [
    {
      "asset_id": "sha256:...",
      "data_ref": "...",
      ...
    }
  ],
  "consents": [...],
  "provenance": [...],
  "contributions": [...],
  "bundle_hash": "sha256:...",
  "signature": {
    "algorithm": "ED25519",
    "publicKeyId": "did:haven:system#export-key",
    "value": "...",
    "signedAt": "2026-02-13T10:30:00.000Z"
  },
  "metadata": {
    "purpose": "FULL_EXPORT",
    "patient_ref": "patient:alice-12345"
  }
}
```

### 5.2 Wire Format

Content-Type: `application/vnd.haven.bundle+json`

For large bundles, implementations MAY support:
- Streaming JSON (JSON Lines)
- Compressed bundles (gzip)
- Chunked transfer

---

## 6. Conformance Requirements

### 6.1 MUST Requirements

Implementations MUST:

1. **M1**: Compute bundle_hash using the canonical algorithm
2. **M2**: Verify signature before processing bundle
3. **M3**: Reject bundles with invalid hash or signature
4. **M4**: Record provenance for import operations
5. **M5**: Validate all included objects against their specs

### 6.2 SHOULD Requirements

Implementations SHOULD:

1. **S1**: Include complete provenance chains (not just proofs)
2. **S2**: Include all consents referenced by assets
3. **S3**: Support conflict resolution options
4. **S4**: Verify bundle version compatibility before import

### 6.3 MAY Requirements

Implementations MAY:

1. **O1**: Support compressed bundles
2. **O2**: Support streaming for large bundles
3. **O3**: Implement bundle expiration
4. **O4**: Add implementation-specific metadata extensions

---

## 7. Security Considerations

### 7.1 Threat Model

| Threat | Description | Mitigation |
|--------|-------------|------------|
| Bundle tampering | Attacker modifies bundle in transit | Hash + signature verification |
| Replay attack | Attacker re-submits old bundle | Bundle ID tracking, timestamps |
| Unauthorized export | Data exported without consent | Consent verification before export |
| Signature forgery | Fake bundle from untrusted source | Public key verification |

### 7.2 Implementation Guidance

- Verify signatures using trusted public keys only
- Track imported bundle IDs to prevent replay
- Log all import operations for audit
- Encrypt bundles in transit (TLS) and at rest

---

## 8. Examples

### 8.1 Minimal Bundle

```json
{
  "bundle_id": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
  "version": "2.0.0",
  "created_at": "2026-02-13T10:30:00.000Z",
  "created_by": {
    "id": "patient:alice-12345",
    "type": "PATIENT"
  },
  "assets": [],
  "consents": [],
  "provenance": [],
  "contributions": [],
  "bundle_hash": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "signature": {
    "algorithm": "ED25519",
    "publicKeyId": "did:haven:alice#key-1",
    "value": "...",
    "signedAt": "2026-02-13T10:30:00.000Z"
  }
}
```

### 8.2 Patient Export Bundle

```json
{
  "bundle_id": "export-2026-02-13-alice",
  "version": "2.0.0",
  "created_at": "2026-02-13T10:30:00.000Z",
  "created_by": {
    "id": "system:haven-instance-1",
    "type": "SYSTEM"
  },
  "assets": [
    {
      "asset_id": "sha256:7d865e959b2466918c9863afca942d0fb89d7c9ac0c99bafc3749504ded97730",
      "data_ref": "haven://vault/encrypted/abc123",
      "substrate": "FHIR-R4",
      "consent_ref": "consent:550e8400-e29b-41d4-a716-446655440000",
      "quality_class": "A",
      "provenance_ref": "prov:chain001:entry:42",
      "patient_ref": "patient:alice-12345",
      "created_at": "2026-01-15T10:30:00.000Z"
    }
  ],
  "consents": [
    {
      "consent_id": "550e8400-e29b-41d4-a716-446655440000",
      "grantor": {"id": "patient:alice-12345", "type": "HAVEN_ID"},
      "grantee": {"id": "system:haven-instance-2", "type": "SYSTEM"},
      "scope": {"resourceTypes": ["*"]},
      "purpose": ["PORTABILITY"],
      "status": "ACTIVE",
      "granted_at": "2026-02-13T10:00:00.000Z",
      "signature": {...}
    }
  ],
  "provenance": [
    {
      "entryId": "prov:chain001:entry:0",
      "chainId": "chain001",
      "sequence": 0,
      "timestamp": "2026-01-01T00:00:00.000Z",
      "eventType": "SYSTEM_AUDIT",
      "actor": {"id": "system:haven", "type": "SYSTEM"},
      "subject": {"type": "PATIENT", "id": "patient:alice-12345"},
      "details": {"event": "CHAIN_CREATED"},
      "previousHash": null,
      "entryHash": "sha256:genesis...",
      "signature": {...}
    }
  ],
  "contributions": [],
  "bundle_hash": "sha256:abc123...",
  "signature": {
    "algorithm": "ED25519",
    "publicKeyId": "did:haven:system#export-key",
    "value": "MEUCIQDx...",
    "signedAt": "2026-02-13T10:30:00.000Z"
  },
  "metadata": {
    "purpose": "FULL_EXPORT",
    "patient_ref": "patient:alice-12345",
    "source_system": "haven-instance-1",
    "destination": "haven-instance-2"
  }
}
```

---

## 9. Test Vectors

See `/test-vectors/exchange-bundle/` for conformance test data.

| Test Case | Expected Result |
|-----------|-----------------|
| Valid minimal bundle | VALID |
| Valid full export | VALID |
| Invalid hash | INVALID - hash mismatch |
| Invalid signature | INVALID - signature verification failed |
| Missing required field | INVALID - schema violation |
| Incompatible version | INVALID - version mismatch |

---

## 10. References

- [HAVEN Health Asset Spec](./001-health-asset.md)
- [HAVEN Consent Protocol Spec](./002-consent-protocol.md)
- [HAVEN Provenance Record Spec](./003-provenance-record.md)
- [HAVEN Contribution Model Spec](./004-contribution-model.md)

---

*HAVEN Specification 006 | Version 2.0.0 | February 13, 2026*
