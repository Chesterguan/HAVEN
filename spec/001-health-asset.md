# HAVEN Specification 001: Health Asset

**Status**: Draft
**Version**: 2.0.0
**Date**: January 28, 2026
**Authors**: Chester Guan

---

## 1. Overview

A **Health Asset** is the fundamental data primitive in HAVEN. It represents a governed reference to clinical data—not raw data itself, but a pointer with embedded governance metadata that ensures data is never "naked" (i.e., without consent and provenance).

### 1.1 Design Goals

1. **Governance-embedded**: Every Health Asset MUST reference an active consent policy
2. **Content-addressed**: Asset identity derived from content hash ensures immutability
3. **Substrate-agnostic**: Same asset can exist in multiple representations (FHIR, OMOP, etc.)
4. **Quality-scored**: Every asset carries a quality classification

### 1.2 Scope

This specification defines:
- The Health Asset data structure
- Content addressing algorithm
- Quality classification grades
- Serialization format
- Conformance requirements

---

## 2. Data Model

### 2.1 Health Asset Structure

```
HealthAsset := {
    asset_id        : ContentHash       // REQUIRED - Derived from content
    data_ref        : SecureReference   // REQUIRED - Pointer to clinical data
    substrate       : SubstrateType     // REQUIRED - Data format identifier
    consent_ref     : ConsentID         // REQUIRED - Active consent policy
    quality_class   : QualityClass      // REQUIRED - Data quality grade
    provenance_ref  : ProvenanceID      // REQUIRED - Audit chain reference
    patient_ref     : PatientID         // REQUIRED - Patient identifier
    created_at      : Timestamp         // REQUIRED - ISO 8601 UTC
    metadata        : AssetMetadata     // OPTIONAL - Additional attributes
}
```

### 2.2 Field Definitions

#### 2.2.1 asset_id (ContentHash)

A content-derived identifier ensuring asset immutability.

**Format**: `sha256:<hex_digest>`

**Constraints**:
- MUST be exactly 64 hexadecimal characters (256 bits)
- MUST be lowercase
- MUST be derived using the canonicalization algorithm in Section 4.1

**Example**: `sha256:a1b2c3d4e5f6789012345678901234567890123456789012345678901234abcd`

#### 2.2.2 data_ref (SecureReference)

A URI pointing to the underlying clinical data.

**Format**: `<scheme>://<authority>/<path>`

**Supported Schemes**:

| Scheme | Description | Example |
|--------|-------------|---------|
| `fhir` | FHIR R4 resource | `fhir://server.example.com/Observation/12345` |
| `omop` | OMOP CDM record | `omop://cdm.example.com/measurement/67890` |
| `haven` | HAVEN internal reference | `haven://vault/asset/abc123` |
| `urn` | Universal Resource Name | `urn:uuid:550e8400-e29b-41d4-a716-446655440000` |

**Constraints**:
- MUST be a valid URI per RFC 3986
- Scheme MUST be one of the supported schemes or a registered extension
- MUST NOT contain credentials in the URI

#### 2.2.3 substrate (SubstrateType)

Identifies the underlying data format.

**Enumerated Values**:

| Value | Description |
|-------|-------------|
| `FHIR-R4` | HL7 FHIR Release 4 |
| `OMOP-CDM-5.4` | OHDSI OMOP CDM version 5.4 |
| `OMOP-CDM-6.0` | OHDSI OMOP CDM version 6.0 |
| `MEDS` | Medical Event Data Standard |
| `CDA-R2` | HL7 CDA Release 2 |
| `CUSTOM` | Implementation-specific format |

**Constraints**:
- MUST be one of the enumerated values
- Implementations MAY register additional substrate types

#### 2.2.4 consent_ref (ConsentID)

Reference to the governing consent attestation.

**Format**: `consent:<uuid>`

**Constraints**:
- MUST reference a valid, active ConsentAttestation
- MUST be a UUID v4 formatted as lowercase hexadecimal with hyphens
- Referenced consent MUST NOT be expired or revoked

**Example**: `consent:550e8400-e29b-41d4-a716-446655440000`

#### 2.2.5 quality_class (QualityClass)

Quality grade derived from the three-gate validation protocol.

**Enumerated Values**:

| Grade | Description | Gate Status |
|-------|-------------|-------------|
| `A` | Highest quality | All gates passed |
| `B` | High quality | Gates 0-1 passed, partial Gate 2 |
| `C` | Moderate quality | Gate 0 passed, partial Gate 1 |
| `D` | Low quality | Gate 0 passed only |

**Constraints**:
- MUST be one of: `A`, `B`, `C`, `D`
- Grade determination MUST follow the three-gate protocol (Section 3.2)

#### 2.2.6 provenance_ref (ProvenanceID)

Reference to the provenance chain for this asset.

**Format**: `prov:<chain_id>:<entry_id>`

**Components**:
- `chain_id`: Identifier for the provenance chain (UUID)
- `entry_id`: Specific entry in the chain (UUID or sequence number)

**Example**: `prov:abc123:entry:456`

#### 2.2.7 patient_ref (PatientID)

Reference to the patient who owns this data.

**Format**: `patient:<identifier>`

**Constraints**:
- MUST be a stable patient identifier
- MAY be a UUID, DID, or implementation-specific identifier
- MUST NOT contain PII directly (use indirection)

#### 2.2.8 created_at (Timestamp)

Creation timestamp in ISO 8601 format.

**Format**: `YYYY-MM-DDTHH:mm:ss.sssZ`

**Constraints**:
- MUST be UTC timezone (Z suffix)
- MUST include milliseconds
- MUST NOT be in the future

#### 2.2.9 metadata (AssetMetadata) - OPTIONAL

Additional asset attributes.

```
AssetMetadata := {
    source_system   : string            // Origin system identifier
    data_type       : DataType          // Clinical data category
    record_count    : integer           // Number of records (if aggregate)
    time_range      : TimeRange         // Temporal coverage
    version         : string            // Asset version
    tags            : string[]          // Classification tags
    extensions      : object            // Implementation-specific fields
}
```

### 2.3 Invariants

The following invariants MUST hold for all Health Assets:

1. **I1**: `asset_id` MUST be derivable from content using the specified algorithm
2. **I2**: `consent_ref` MUST reference an active (non-revoked, non-expired) consent
3. **I3**: `quality_class` MUST match the result of the three-gate protocol
4. **I4**: `created_at` MUST be ≤ current time
5. **I5**: `data_ref` MUST resolve to accessible data (when authorized)

---

## 3. Operations

### 3.1 create()

Creates a new Health Asset.

**Signature**:
```
create(
    data_ref: SecureReference,
    substrate: SubstrateType,
    consent_ref: ConsentID,
    patient_ref: PatientID,
    metadata?: AssetMetadata
) → HealthAsset | Error
```

**Preconditions**:
- `consent_ref` MUST reference an active consent
- Caller MUST be authorized to create assets for `patient_ref`
- `data_ref` MUST be accessible

**Postconditions**:
- Asset is persisted with generated `asset_id`
- Provenance entry of type `ASSET_CREATED` is recorded
- Quality assessment is performed and `quality_class` assigned

**Errors**:
- `INVALID_CONSENT`: Consent is expired, revoked, or nonexistent
- `UNAUTHORIZED`: Caller lacks permission
- `DATA_INACCESSIBLE`: Referenced data cannot be accessed
- `VALIDATION_FAILED`: Data fails Gate 0 validation

### 3.2 get()

Retrieves a Health Asset by ID.

**Signature**:
```
get(
    asset_id: ContentHash,
    accessor: AccessorIdentity
) → HealthAsset | Error
```

**Preconditions**:
- `accessor` MUST have active consent for this asset

**Postconditions**:
- Provenance entry of type `ASSET_ACCESSED` is recorded

**Errors**:
- `NOT_FOUND`: Asset does not exist
- `CONSENT_DENIED`: No valid consent for accessor
- `CONSENT_EXPIRED`: Consent has expired

### 3.3 verify()

Verifies asset integrity and consent status.

**Signature**:
```
verify(
    asset_id: ContentHash
) → VerificationResult
```

**Returns**:
```
VerificationResult := {
    valid: boolean,
    content_hash_matches: boolean,
    consent_active: boolean,
    provenance_intact: boolean,
    quality_class: QualityClass,
    errors: string[]
}
```

### 3.4 list()

Lists assets for a patient.

**Signature**:
```
list(
    patient_ref: PatientID,
    filters?: AssetFilters
) → HealthAsset[]
```

**Filters**:
```
AssetFilters := {
    substrate?: SubstrateType[],
    quality_class?: QualityClass[],
    data_type?: DataType[],
    created_after?: Timestamp,
    created_before?: Timestamp,
    limit?: integer,
    offset?: integer
}
```

---

## 4. Cryptographic Requirements

### 4.1 Content Addressing Algorithm

The `asset_id` MUST be computed as follows:

1. **Canonicalize** the asset content:
   - Serialize the HealthAsset (excluding `asset_id`) to JSON
   - Sort all object keys alphabetically (recursive)
   - Remove all whitespace (minify)
   - Use UTF-8 encoding

2. **Hash** the canonical form:
   - Apply SHA-256 to the canonical bytes
   - Encode result as lowercase hexadecimal

3. **Format** the asset_id:
   - Prefix with `sha256:`
   - Append the 64-character hex digest

**Pseudocode**:
```
function computeAssetId(asset: HealthAsset) → ContentHash:
    // Create copy without asset_id
    canonical = deepCopy(asset)
    delete canonical.asset_id

    // Canonicalize
    json = serializeJSON(canonical, {sortKeys: true, minify: true})
    bytes = encodeUTF8(json)

    // Hash
    digest = sha256(bytes)
    hex = encodeHex(digest).toLowerCase()

    return "sha256:" + hex
```

### 4.2 Example Canonicalization

**Input** (formatted for readability):
```json
{
  "data_ref": "fhir://example.com/Observation/123",
  "substrate": "FHIR-R4",
  "consent_ref": "consent:550e8400-e29b-41d4-a716-446655440000",
  "quality_class": "A",
  "provenance_ref": "prov:abc123:entry:001",
  "patient_ref": "patient:alice",
  "created_at": "2026-01-28T10:30:00.000Z"
}
```

**Canonical form** (single line, sorted keys):
```
{"consent_ref":"consent:550e8400-e29b-41d4-a716-446655440000","created_at":"2026-01-28T10:30:00.000Z","data_ref":"fhir://example.com/Observation/123","patient_ref":"patient:alice","provenance_ref":"prov:abc123:entry:001","quality_class":"A","substrate":"FHIR-R4"}
```

---

## 5. Quality Assessment Protocol

### 5.1 Three-Gate Protocol

Quality class is determined by a three-gate validation protocol:

```
┌─────────────┐
│  Raw Data   │
└──────┬──────┘
       ▼
┌─────────────────────────────────────────┐
│  Gate 0: Provenance Validation          │
│  - Source authenticity                  │
│  - Hash integrity                       │
│  - Temporal consistency                 │
└──────┬───────────────────────┬──────────┘
       │ PASS                  │ FAIL
       ▼                       ▼
┌──────────────┐         ┌──────────┐
│   Gate 1     │         │  REJECT  │
└──────┬───────┘         └──────────┘
       ▼
┌─────────────────────────────────────────┐
│  Gate 1: Structural Completeness        │
│  - Required fields present              │
│  - Valid data types                     │
│  - Code system validity                 │
└──────┬───────────────────────┬──────────┘
       │ PASS                  │ FAIL
       ▼                       ▼
┌──────────────┐         ┌──────────┐
│   Gate 2     │         │ Class D  │
└──────┬───────┘         └──────────┘
       ▼
┌─────────────────────────────────────────┐
│  Gate 2: Semantic Mapping               │
│  - Standard concept mapping             │
│  - Research-ready transformation        │
│  - Cross-reference validation           │
└──────┬───────────────────────┬──────────┘
       │ FULL                  │ PARTIAL
       ▼                       ▼
┌──────────────┐         ┌──────────┐
│   Class A    │         │ Class B  │
└──────────────┘         └──────────┘
```

### 5.2 Gate 0: Provenance Validation

**Requirements**:
- Source MUST be authenticated (valid signature from known origin)
- Content hash MUST match declared hash
- Timestamps MUST be consistent (no future dates, logical ordering)

**Pass criteria**: All requirements met
**Fail criteria**: Any requirement not met → REJECT (no Health Asset created)

### 5.3 Gate 1: Structural Completeness

**Requirements**:
- All required fields present per substrate schema
- Data types valid (dates are dates, numbers are numbers)
- Code systems valid (ICD-10 codes are valid ICD-10)

**Pass criteria**: ≥95% of records meet requirements
**Fail criteria**: <95% compliance → Class C or D

### 5.4 Gate 2: Semantic Mapping

**Requirements**:
- Concepts map to standard vocabularies (SNOMED CT, LOINC, RxNorm)
- Mappings are unambiguous
- Records are research-ready (can be queried with standard queries)

**Full pass**: ≥90% concepts mapped → Class A
**Partial pass**: 70-89% concepts mapped → Class B
**Fail**: <70% concepts mapped → Class C (if Gate 1 passed)

### 5.5 Quality Class Summary

| Class | Gate 0 | Gate 1 | Gate 2 | Description |
|-------|--------|--------|--------|-------------|
| A | Pass | Pass | Full | Research-ready, fully mapped |
| B | Pass | Pass | Partial | Research-usable, some unmapped concepts |
| C | Pass | Partial | N/A | Structurally incomplete |
| D | Pass | Fail | N/A | Provenance valid, minimal structure |
| REJECT | Fail | N/A | N/A | Cannot create Health Asset |

---

## 6. Serialization

### 6.1 JSON Serialization (Normative)

Health Assets MUST be serializable to JSON with the following schema:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": [
    "asset_id",
    "data_ref",
    "substrate",
    "consent_ref",
    "quality_class",
    "provenance_ref",
    "patient_ref",
    "created_at"
  ],
  "properties": {
    "asset_id": {
      "type": "string",
      "pattern": "^sha256:[a-f0-9]{64}$"
    },
    "data_ref": {
      "type": "string",
      "format": "uri"
    },
    "substrate": {
      "type": "string",
      "enum": ["FHIR-R4", "OMOP-CDM-5.4", "OMOP-CDM-6.0", "MEDS", "CDA-R2", "CUSTOM"]
    },
    "consent_ref": {
      "type": "string",
      "pattern": "^consent:[a-f0-9-]{36}$"
    },
    "quality_class": {
      "type": "string",
      "enum": ["A", "B", "C", "D"]
    },
    "provenance_ref": {
      "type": "string",
      "pattern": "^prov:[a-zA-Z0-9]+:.*$"
    },
    "patient_ref": {
      "type": "string",
      "pattern": "^patient:.+$"
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "metadata": {
      "type": "object"
    }
  }
}
```

### 6.2 Wire Format

For transmission, Health Assets SHOULD be serialized as:
1. JSON with UTF-8 encoding (default)
2. Protocol Buffers (for high-performance scenarios)

Content-Type headers:
- JSON: `application/vnd.haven.health-asset+json`
- Protobuf: `application/vnd.haven.health-asset+protobuf`

---

## 7. Conformance Requirements

### 7.1 MUST Requirements

Implementations MUST:

1. **M1**: Compute `asset_id` using the canonicalization algorithm in Section 4.1
2. **M2**: Reject asset creation if consent is not active
3. **M3**: Record provenance entry for every asset access
4. **M4**: Validate `data_ref` resolves to accessible data before asset creation
5. **M5**: Assign `quality_class` using the three-gate protocol
6. **M6**: Use UTC timestamps with millisecond precision
7. **M7**: Validate all required fields before persistence

### 7.2 SHOULD Requirements

Implementations SHOULD:

1. **S1**: Cache quality assessments to avoid redundant computation
2. **S2**: Support multiple substrates (at minimum FHIR-R4 and OMOP-CDM-5.4)
3. **S3**: Provide bulk asset creation for efficiency
4. **S4**: Index assets by patient, quality class, and creation time

### 7.3 MAY Requirements

Implementations MAY:

1. **O1**: Support additional substrate types beyond the enumerated list
2. **O2**: Extend metadata with implementation-specific fields
3. **O3**: Implement asset versioning for updates
4. **O4**: Support asset deletion (with provenance record)

---

## 8. Security Considerations

### 8.1 Threat Model

| Threat | Description | Mitigation |
|--------|-------------|------------|
| Hash collision | Attacker creates different data with same hash | SHA-256 collision resistance (2^128 operations) |
| Consent bypass | Accessing data without valid consent | Consent verification on every access |
| Data tampering | Modifying data after asset creation | Content-addressed ID detects changes |
| Replay attacks | Reusing old, revoked consent | Consent status check includes timestamp |
| Enumeration | Guessing asset IDs | Random component in underlying data reference |

### 8.2 Implementation Guidance

- Store consent references, not consent content, to handle revocation
- Implement rate limiting on asset verification
- Log all verification failures for security monitoring
- Use constant-time comparison for hash validation

---

## 9. Examples

### 9.1 Minimal Health Asset

```json
{
  "asset_id": "sha256:7d865e959b2466918c9863afca942d0fb89d7c9ac0c99bafc3749504ded97730",
  "data_ref": "fhir://ehr.hospital.org/Observation/bp-123",
  "substrate": "FHIR-R4",
  "consent_ref": "consent:550e8400-e29b-41d4-a716-446655440000",
  "quality_class": "A",
  "provenance_ref": "prov:chain001:entry:001",
  "patient_ref": "patient:alice-12345",
  "created_at": "2026-01-28T10:30:00.000Z"
}
```

### 9.2 Health Asset with Metadata

```json
{
  "asset_id": "sha256:2c624232cdd221771294dfbb310aca000a0df6ac8b66b696d90ef06fdefb64a3",
  "data_ref": "omop://research-cdm.org/measurement/bulk/2026-01",
  "substrate": "OMOP-CDM-6.0",
  "consent_ref": "consent:6ba7b810-9dad-11d1-80b4-00c04fd430c8",
  "quality_class": "B",
  "provenance_ref": "prov:chain002:entry:047",
  "patient_ref": "patient:bob-67890",
  "created_at": "2026-01-28T14:45:30.123Z",
  "metadata": {
    "source_system": "epic-mychart-2024",
    "data_type": "MEASUREMENT",
    "record_count": 847,
    "time_range": {
      "start": "2023-01-01T00:00:00.000Z",
      "end": "2025-12-31T23:59:59.999Z"
    },
    "version": "1.0.0",
    "tags": ["diabetes", "cgm", "research-cohort"]
  }
}
```

---

## 10. Test Vectors

See `/test-vectors/health-asset/` for conformance test data:

- `valid/` - Assets that MUST be accepted
- `invalid/` - Assets that MUST be rejected

### 10.1 Reference Test Vector

**Input** (canonical form for hashing):
```json
{"consent_ref":"consent:550e8400-e29b-41d4-a716-446655440000","created_at":"2026-01-28T10:30:00.000Z","data_ref":"fhir://example.com/Observation/test-001","patient_ref":"patient:test-patient","provenance_ref":"prov:test:entry:001","quality_class":"A","substrate":"FHIR-R4"}
```

**Expected SHA-256**: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` (placeholder - compute from actual input)

---

## 11. References

- [HL7 FHIR R4](https://hl7.org/fhir/R4/)
- [OHDSI OMOP CDM](https://ohdsi.github.io/CommonDataModel/)
- [RFC 3986 - URI](https://datatracker.ietf.org/doc/html/rfc3986)
- [RFC 2119 - Keywords](https://datatracker.ietf.org/doc/html/rfc2119)
- [SHA-256 (FIPS 180-4)](https://csrc.nist.gov/publications/detail/fips/180/4/final)

---

*HAVEN Specification 001 | Version 2.0.0 | January 28, 2026*
