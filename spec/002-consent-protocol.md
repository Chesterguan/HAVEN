# HAVEN Specification 002: Consent Protocol

**Status**: Draft
**Version**: 2.0.0
**Date**: January 28, 2026
**Authors**: Chester Guan

---

## 1. Overview

The **Consent Protocol** defines how authorization is granted, verified, and revoked in HAVEN. It transforms consent from a static, binary checkbox into a programmable, dynamic, and revocable authorization mechanism.

### 1.1 Design Goals

1. **Deterministic Evaluation**: Same inputs always produce the same authorization decision
2. **Immediate Revocation**: Consent withdrawal takes effect instantly
3. **Closed-World Scope**: Resources not explicitly granted are denied by default
4. **Granular Control**: Patients can specify exactly what data, for what purpose, under what conditions

### 1.2 Scope

This specification defines:
- The ConsentAttestation data structure
- Consent operations (grant, verify, revoke, list)
- Scope and condition semantics
- Cryptographic signature requirements
- PSDL integration points

---

## 2. Data Model

### 2.1 Consent Attestation Structure

```
ConsentAttestation := {
    consent_id      : UUID              // REQUIRED - Unique identifier
    grantor         : PatientIdentity   // REQUIRED - Who grants consent
    grantee         : AccessorIdentity  // REQUIRED - Who receives access
    scope           : DataScope         // REQUIRED - What data is covered
    purpose         : PurposeType[]     // REQUIRED - Why access is needed
    conditions      : Condition[]       // OPTIONAL - Usage restrictions
    granted_at      : Timestamp         // REQUIRED - When consent was granted
    expires_at      : Timestamp | null  // OPTIONAL - Expiration time
    status          : ConsentStatus     // REQUIRED - Current status
    signature       : CryptoSignature   // REQUIRED - Cryptographic attestation
    revoked_at      : Timestamp | null  // CONDITIONAL - If status is REVOKED
    policy_ref      : PolicyReference   // OPTIONAL - PSDL policy reference
    metadata        : ConsentMetadata   // OPTIONAL - Additional attributes
}
```

### 2.2 Field Definitions

#### 2.2.1 consent_id (UUID)

Unique identifier for the consent attestation.

**Format**: UUID v4, lowercase with hyphens

**Example**: `550e8400-e29b-41d4-a716-446655440000`

**Constraints**:
- MUST be globally unique
- MUST be generated using a cryptographically secure random generator

#### 2.2.2 grantor (PatientIdentity)

The patient granting consent.

**Structure**:
```
PatientIdentity := {
    id              : string            // REQUIRED - Patient identifier
    type            : IdentityType      // REQUIRED - Identifier type
    verification    : VerificationLevel // OPTIONAL - Identity assurance level
}

IdentityType := {
    HAVEN_ID,       // HAVEN-assigned identifier
    DID,            // Decentralized identifier
    FHIR_ID,        // FHIR Patient resource ID
    EXTERNAL        // External system identifier
}

VerificationLevel := {
    SELF_ASSERTED,  // Patient claimed identity
    VERIFIED,       // Identity verified by trusted party
    AUTHENTICATED   // Strong authentication performed
}
```

**Example**:
```json
{
  "id": "patient:alice-12345",
  "type": "HAVEN_ID",
  "verification": "AUTHENTICATED"
}
```

#### 2.2.3 grantee (AccessorIdentity)

The entity receiving consent.

**Structure**:
```
AccessorIdentity := {
    id              : string            // REQUIRED - Accessor identifier
    type            : AccessorType      // REQUIRED - Accessor category
    name            : string            // REQUIRED - Human-readable name
    organization    : string            // OPTIONAL - Organization name
    credentials     : Credential[]      // OPTIONAL - Verified credentials
}

AccessorType := {
    RESEARCHER,     // Academic/industry researcher
    CLINICIAN,      // Healthcare provider
    INSTITUTION,    // Healthcare organization
    STUDY,          // Clinical study/trial
    APPLICATION,    // Software application
    AI_MODEL,       // Machine learning model
    PUBLIC_HEALTH   // Public health authority
}
```

**Example**:
```json
{
  "id": "study:diabetes-cgm-2026",
  "type": "STUDY",
  "name": "Continuous Glucose Monitoring Outcomes Study",
  "organization": "Stanford Medicine",
  "credentials": [
    {"type": "IRB_APPROVAL", "id": "IRB-2026-001", "issuer": "stanford.edu"}
  ]
}
```

#### 2.2.4 scope (DataScope)

Defines what data is accessible under this consent.

**Structure**:
```
DataScope := {
    resource_types  : ResourceType[]    // REQUIRED - What types to include
    exclusions      : ResourceType[]    // OPTIONAL - Explicit exclusions
    time_range      : TimeRange | null  // OPTIONAL - Temporal bounds
    data_classes    : DataClass[]       // OPTIONAL - Semantic categories
    asset_ids       : AssetID[]         // OPTIONAL - Specific assets
    filters         : ScopeFilter[]     // OPTIONAL - Additional filters
}
```

**ResourceType Enumeration**:

| Category | Resource Types |
|----------|---------------|
| **Clinical** | `Condition`, `Procedure`, `Encounter`, `DiagnosticReport`, `Observation` |
| **Medications** | `MedicationRequest`, `MedicationAdministration`, `MedicationStatement` |
| **Laboratory** | `Observation.laboratory`, `DiagnosticReport.lab` |
| **Vital Signs** | `Observation.vital-signs` |
| **Imaging** | `ImagingStudy`, `Media`, `DiagnosticReport.imaging` |
| **Documents** | `DocumentReference`, `Note`, `ClinicalImpression` |
| **Demographics** | `Patient`, `Person` |
| **Administrative** | `Coverage`, `Claim`, `ExplanationOfBenefit` |
| **Genetic** | `MolecularSequence`, `Observation.genetics` |
| **Mental Health** | `Observation.mental_health`, `Condition.mental_health` |

**TimeRange**:
```
TimeRange := {
    start           : Timestamp | null  // Inclusive start (null = no lower bound)
    end             : Timestamp | null  // Inclusive end (null = ongoing)
}
```

**DataClass** (semantic categories):
```
DataClass := {
    DEMOGRAPHICS,   // Name, DOB, contact (sensitive)
    CLINICAL,       // Diagnoses, procedures
    LABORATORY,     // Lab results
    MEDICATIONS,    // Drug exposures
    IMAGING,        // Radiology, pathology
    GENOMIC,        // Genetic data
    BEHAVIORAL,     // Mental health, substance use
    REPRODUCTIVE,   // Sexual/reproductive health
    FINANCIAL       // Claims, coverage
}
```

**Example**:
```json
{
  "resource_types": ["Observation.laboratory", "Condition", "MedicationRequest"],
  "exclusions": ["Observation.mental_health", "Note"],
  "time_range": {
    "start": "2020-01-01T00:00:00.000Z",
    "end": null
  },
  "data_classes": ["CLINICAL", "LABORATORY", "MEDICATIONS"]
}
```

#### 2.2.5 purpose (PurposeType[])

Authorized purposes for data use.

**Enumerated Values**:

| Purpose | Description | Typical Grantee |
|---------|-------------|-----------------|
| `TREATMENT` | Direct patient care | Clinician |
| `RESEARCH` | Scientific research | Researcher, Study |
| `PUBLIC_HEALTH` | Disease surveillance, outbreak response | Public Health Authority |
| `QUALITY_IMPROVEMENT` | Healthcare quality assessment | Institution |
| `PAYMENT` | Billing, insurance | Institution, Payer |
| `OPERATIONS` | Healthcare operations | Institution |
| `MARKETING` | Health-related marketing | Application |
| `AI_TRAINING` | Machine learning model development | AI Model |
| `PERSONAL` | Patient's own use | Application |

**Constraints**:
- At least one purpose MUST be specified
- Multiple purposes MAY be combined
- `MARKETING` requires explicit opt-in (separate consent recommended)

#### 2.2.6 conditions (Condition[])

Usage restrictions that modify consent behavior.

**Condition Types**:

```
Condition := {
    type            : ConditionType     // REQUIRED
    parameters      : object            // Type-specific parameters
}

ConditionType := {
    AGGREGATION_ONLY,       // Data must be aggregated, no individual records
    MIN_COHORT_SIZE,        // Minimum population for query results
    NO_REIDENTIFICATION,    // Prohibition on re-identification attempts
    TIME_LIMITED_ACCESS,    // Access window (distinct from consent expiry)
    GEOGRAPHIC_RESTRICTION, // Where data can be accessed
    PURPOSE_RESTRICTED,     // Subset of stated purposes
    NOTIFICATION_REQUIRED,  // Notify patient on access
    APPROVAL_REQUIRED,      // Require additional approval per access
    AUDIT_REQUIRED,         // Enhanced audit logging
    COMPUTE_TO_DATA,        // Data must not leave origin
    OUTPUT_REVIEW           // Results require review before release
}
```

**Condition Examples**:

**AGGREGATION_ONLY**:
```json
{
  "type": "AGGREGATION_ONLY",
  "parameters": {
    "min_records": 10,
    "allowed_operations": ["COUNT", "AVG", "PERCENTILE"]
  }
}
```

**MIN_COHORT_SIZE**:
```json
{
  "type": "MIN_COHORT_SIZE",
  "parameters": {
    "minimum": 50,
    "action_on_violation": "SUPPRESS"
  }
}
```

**NO_REIDENTIFICATION**:
```json
{
  "type": "NO_REIDENTIFICATION",
  "parameters": {
    "prohibition": "ABSOLUTE",
    "attestation_required": true
  }
}
```

**GEOGRAPHIC_RESTRICTION**:
```json
{
  "type": "GEOGRAPHIC_RESTRICTION",
  "parameters": {
    "allowed_regions": ["US", "EU"],
    "prohibited_regions": ["CN", "RU"]
  }
}
```

#### 2.2.7 status (ConsentStatus)

Current consent status.

**Enumerated Values**:

| Status | Description | Transitions |
|--------|-------------|-------------|
| `ACTIVE` | Consent is valid and enforceable | → REVOKED, → EXPIRED |
| `REVOKED` | Patient withdrew consent | Terminal |
| `EXPIRED` | Consent passed expiration time | Terminal |
| `PENDING` | Consent requested, not yet granted | → ACTIVE, → REJECTED |
| `REJECTED` | Patient declined consent request | Terminal |

**State Transitions**:
```
         ┌──────────┐
         │ PENDING  │
         └────┬─────┘
              │
     ┌────────┴────────┐
     ▼                 ▼
┌─────────┐      ┌──────────┐
│ ACTIVE  │      │ REJECTED │
└────┬────┘      └──────────┘
     │
     ├─────────────┐
     ▼             ▼
┌─────────┐  ┌─────────┐
│ REVOKED │  │ EXPIRED │
└─────────┘  └─────────┘
```

#### 2.2.8 signature (CryptoSignature)

Cryptographic attestation of consent.

**Structure**:
```
CryptoSignature := {
    algorithm       : SignatureAlgorithm    // REQUIRED
    public_key_id   : string                // REQUIRED - Key reference
    value           : string                // REQUIRED - Base64-encoded signature
    signed_at       : Timestamp             // REQUIRED - Signing time
}

SignatureAlgorithm := {
    ED25519,        // EdDSA with Curve25519 (recommended)
    ES256,          // ECDSA with P-256
    ES384,          // ECDSA with P-384
    RS256           // RSA with SHA-256 (legacy support)
}
```

**Signing Process**:
1. Create canonical JSON of ConsentAttestation (excluding `signature` field)
2. Compute SHA-256 hash of canonical JSON
3. Sign hash with private key
4. Encode signature as base64url

**Example**:
```json
{
  "algorithm": "ED25519",
  "public_key_id": "did:haven:alice#key-1",
  "value": "MEUCIQDx...base64url...",
  "signed_at": "2026-01-28T10:30:00.000Z"
}
```

#### 2.2.9 policy_ref (PolicyReference) - OPTIONAL

Reference to PSDL policy definition.

**Format**: `psdl:<repository>:<scenario>:<version>`

**Example**: `psdl:haven/policies:research-consent:1.0.0`

---

## 3. Operations

### 3.1 grant()

Creates a new consent attestation.

**Signature**:
```
grant(
    grantor: PatientIdentity,
    grantee: AccessorIdentity,
    scope: DataScope,
    purpose: PurposeType[],
    conditions?: Condition[],
    expires_at?: Timestamp,
    policy_ref?: PolicyReference
) → ConsentAttestation | Error
```

**Preconditions**:
- `grantor` MUST be authenticated
- `grantor` MUST have authority to consent (e.g., not a minor without guardian)
- `scope` MUST contain at least one resource type
- `expires_at`, if specified, MUST be in the future

**Postconditions**:
- New ConsentAttestation with status `ACTIVE` is persisted
- Provenance entry of type `CONSENT_GRANTED` is recorded
- Grantee is notified of consent grant

**Errors**:
- `INVALID_GRANTOR`: Grantor authentication failed
- `UNAUTHORIZED_GRANTOR`: Grantor lacks authority to consent
- `INVALID_SCOPE`: Scope specification is invalid
- `INVALID_GRANTEE`: Grantee identifier is invalid
- `PAST_EXPIRATION`: Expiration time is in the past

### 3.2 verify()

Checks if access is authorized under a consent.

**Signature**:
```
verify(
    consent_id: UUID,
    accessor: AccessorIdentity,
    requested_scope: DataScope,
    requested_purpose: PurposeType
) → VerificationResult
```

**Returns**:
```
VerificationResult := {
    authorized: boolean,
    consent_status: ConsentStatus,
    scope_match: ScopeMatchResult,
    purpose_match: boolean,
    conditions_met: ConditionResult[],
    denial_reasons: string[],
    expires_in: Duration | null
}

ScopeMatchResult := {
    full_match: boolean,
    covered_types: ResourceType[],
    uncovered_types: ResourceType[],
    time_range_valid: boolean
}

ConditionResult := {
    condition_type: ConditionType,
    satisfied: boolean,
    details: string
}
```

**Verification Algorithm**:

```
function verify(consent_id, accessor, requested_scope, requested_purpose):
    consent = getConsent(consent_id)

    // 1. Status check
    if consent.status != ACTIVE:
        return {authorized: false, denial_reasons: ["Consent not active"]}

    // 2. Expiration check
    if consent.expires_at != null AND now() > consent.expires_at:
        updateStatus(consent_id, EXPIRED)
        return {authorized: false, denial_reasons: ["Consent expired"]}

    // 3. Grantee match
    if not matchesGrantee(consent.grantee, accessor):
        return {authorized: false, denial_reasons: ["Accessor not authorized"]}

    // 4. Purpose match
    if requested_purpose not in consent.purpose:
        return {authorized: false, denial_reasons: ["Purpose not authorized"]}

    // 5. Scope match (closed-world)
    scope_result = matchScope(consent.scope, requested_scope)
    if not scope_result.full_match:
        return {authorized: false, denial_reasons: ["Scope not covered"], scope_match: scope_result}

    // 6. Condition evaluation
    for condition in consent.conditions:
        result = evaluateCondition(condition, requested_scope, accessor)
        if not result.satisfied:
            return {authorized: false, denial_reasons: [result.details]}

    // 7. All checks passed
    recordProvenance(CONSENT_VERIFIED, consent_id, accessor)
    return {authorized: true, ...}
```

**Semantic Guarantees**:
1. **Deterministic**: Same inputs MUST produce same authorization result
2. **Closed-world**: Resource types not in `scope.resource_types` are DENIED
3. **Fail-closed**: Any error during verification results in DENIED

### 3.3 revoke()

Withdraws consent immediately.

**Signature**:
```
revoke(
    consent_id: UUID,
    grantor: PatientIdentity,
    reason?: string
) → RevokeResult | Error
```

**Returns**:
```
RevokeResult := {
    consent_id: UUID,
    revoked_at: Timestamp,
    previous_status: ConsentStatus
}
```

**Preconditions**:
- `grantor` MUST match the original consent grantor (or authorized delegate)
- Consent status MUST be `ACTIVE`

**Postconditions**:
- Consent status set to `REVOKED`
- `revoked_at` timestamp recorded
- All subsequent `verify()` calls return `authorized: false`
- Provenance entry of type `CONSENT_REVOKED` is recorded
- Grantee is notified of revocation

**Timing Guarantee**:
After `revoke()` returns successfully, ALL subsequent calls to `verify()` for this consent MUST return `authorized: false`. This MUST be achieved within 1 second (implementation may use synchronous locking or distributed consensus).

**Errors**:
- `NOT_FOUND`: Consent does not exist
- `UNAUTHORIZED`: Requester is not the grantor
- `INVALID_STATE`: Consent is not ACTIVE

### 3.4 list()

Lists all consents for a patient.

**Signature**:
```
list(
    patient_id: PatientIdentity,
    filters?: ConsentFilters
) → ConsentAttestation[]
```

**Filters**:
```
ConsentFilters := {
    status?: ConsentStatus[],
    grantee_type?: AccessorType[],
    purpose?: PurposeType[],
    granted_after?: Timestamp,
    granted_before?: Timestamp,
    include_expired?: boolean,
    limit?: integer,
    offset?: integer
}
```

**Default**: Returns only `ACTIVE` consents unless `include_expired` or `status` filters are specified.

---

## 4. Cryptographic Requirements

### 4.1 Signature Algorithm

Implementations MUST support Ed25519. MAY support ES256, ES384, RS256.

**Recommended**: Ed25519 for new implementations (smaller keys, faster verification).

### 4.2 Canonical Signing Input

The signing input is computed as:
1. Create JSON object with all ConsentAttestation fields except `signature`
2. Sort keys alphabetically (recursive)
3. Remove whitespace
4. Encode as UTF-8 bytes
5. Compute SHA-256 hash of bytes

### 4.3 Signature Verification

To verify a signature:
1. Reconstruct canonical signing input from ConsentAttestation
2. Retrieve public key using `signature.public_key_id`
3. Verify signature using specified algorithm
4. Confirm `signature.signed_at` is within acceptable time window

---

## 5. PSDL Integration

### 5.1 Policy Reference

Consent attestations MAY reference PSDL policy definitions for:
- Complex scope definitions
- Conditional logic
- Reusable policy templates

**Example**:
```yaml
# PSDL policy: research-consent-v1
scenario: Research_Consent_Policy
version: "1.0.0"

audit:
  intent: "Define data sharing for research"
  rationale: "Patient-controlled research consent"

scope:
  grant:
    - Measurement.laboratory
    - Condition
    - DrugExposure
  deny:
    - Note.*
    - Observation.mental_health

conditions:
  - type: MIN_COHORT_SIZE
    minimum: 50
  - type: AGGREGATION_ONLY
```

**Consent referencing PSDL**:
```json
{
  "consent_id": "...",
  "policy_ref": "psdl:haven/policies:research-consent:1.0.0",
  "scope": { "policy_defined": true },
  "conditions": { "policy_defined": true }
}
```

### 5.2 Policy Resolution

When `policy_ref` is present:
1. Fetch PSDL policy from repository
2. Parse and validate policy
3. Merge policy-defined scope/conditions with explicit fields
4. Explicit fields override policy defaults

---

## 6. Serialization

### 6.1 JSON Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": [
    "consent_id",
    "grantor",
    "grantee",
    "scope",
    "purpose",
    "granted_at",
    "status",
    "signature"
  ],
  "properties": {
    "consent_id": {
      "type": "string",
      "format": "uuid"
    },
    "grantor": {
      "$ref": "#/$defs/PatientIdentity"
    },
    "grantee": {
      "$ref": "#/$defs/AccessorIdentity"
    },
    "scope": {
      "$ref": "#/$defs/DataScope"
    },
    "purpose": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["TREATMENT", "RESEARCH", "PUBLIC_HEALTH", "QUALITY_IMPROVEMENT", "PAYMENT", "OPERATIONS", "MARKETING", "AI_TRAINING", "PERSONAL"]
      },
      "minItems": 1
    },
    "conditions": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/Condition"
      }
    },
    "granted_at": {
      "type": "string",
      "format": "date-time"
    },
    "expires_at": {
      "type": ["string", "null"],
      "format": "date-time"
    },
    "status": {
      "type": "string",
      "enum": ["ACTIVE", "REVOKED", "EXPIRED", "PENDING", "REJECTED"]
    },
    "signature": {
      "$ref": "#/$defs/CryptoSignature"
    },
    "revoked_at": {
      "type": ["string", "null"],
      "format": "date-time"
    },
    "policy_ref": {
      "type": "string",
      "pattern": "^psdl:.+:.+:.+$"
    }
  }
}
```

---

## 7. Conformance Requirements

### 7.1 MUST Requirements

Implementations MUST:

1. **M1**: Verify consent status before granting any data access
2. **M2**: Apply closed-world semantics (deny by default)
3. **M3**: Process revocation within 1 second
4. **M4**: Validate cryptographic signatures on all consent attestations
5. **M5**: Record provenance for grant, verify, and revoke operations
6. **M6**: Support at least Ed25519 signatures
7. **M7**: Reject expired consents without explicit check (auto-transition)

### 7.2 SHOULD Requirements

Implementations SHOULD:

1. **S1**: Support PSDL policy references
2. **S2**: Provide real-time consent status notifications
3. **S3**: Support consent delegation (guardian for minor)
4. **S4**: Implement condition evaluation plugins

### 7.3 MAY Requirements

Implementations MAY:

1. **O1**: Support additional signature algorithms
2. **O2**: Implement consent templates
3. **O3**: Provide consent negotiation workflow
4. **O4**: Support bulk consent operations

---

## 8. Security Considerations

### 8.1 Threat Model

| Threat | Description | Mitigation |
|--------|-------------|------------|
| Consent forgery | Creating fake consent | Cryptographic signature verification |
| Scope expansion | Accessing more than authorized | Closed-world semantics, strict scope matching |
| Revocation delay | Accessing after revocation | Synchronous revocation propagation |
| Replay attacks | Reusing old consent | Timestamp validation, status checking |
| Coercion | Forcing patient consent | Audit trail, revocation always available |
| Condition bypass | Ignoring usage restrictions | Server-side condition enforcement |

### 8.2 Implementation Guidance

- Never cache consent decisions longer than scope allows
- Implement consent revocation as atomic operation
- Log all verification attempts (including denials)
- Use hardware security modules for signature keys
- Implement rate limiting on consent operations

---

## 9. Examples

### 9.1 Research Consent

```json
{
  "consent_id": "550e8400-e29b-41d4-a716-446655440000",
  "grantor": {
    "id": "patient:alice-12345",
    "type": "HAVEN_ID",
    "verification": "AUTHENTICATED"
  },
  "grantee": {
    "id": "study:diabetes-cgm-2026",
    "type": "STUDY",
    "name": "Diabetes CGM Outcomes Study",
    "organization": "Stanford Medicine",
    "credentials": [
      {"type": "IRB_APPROVAL", "id": "IRB-2026-001", "issuer": "stanford.edu"}
    ]
  },
  "scope": {
    "resource_types": ["Observation.laboratory", "Condition", "MedicationRequest"],
    "exclusions": ["Observation.mental_health", "Note"],
    "time_range": {
      "start": "2020-01-01T00:00:00.000Z",
      "end": null
    }
  },
  "purpose": ["RESEARCH"],
  "conditions": [
    {
      "type": "AGGREGATION_ONLY",
      "parameters": {"min_records": 10}
    },
    {
      "type": "MIN_COHORT_SIZE",
      "parameters": {"minimum": 50}
    },
    {
      "type": "NO_REIDENTIFICATION",
      "parameters": {"prohibition": "ABSOLUTE"}
    }
  ],
  "granted_at": "2026-01-28T10:30:00.000Z",
  "expires_at": "2027-01-28T10:30:00.000Z",
  "status": "ACTIVE",
  "signature": {
    "algorithm": "ED25519",
    "public_key_id": "did:haven:alice#key-1",
    "value": "MEUCIQDx...",
    "signed_at": "2026-01-28T10:30:00.000Z"
  }
}
```

### 9.2 Clinical Care Consent

```json
{
  "consent_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
  "grantor": {
    "id": "patient:bob-67890",
    "type": "HAVEN_ID"
  },
  "grantee": {
    "id": "clinician:dr-smith-001",
    "type": "CLINICIAN",
    "name": "Dr. Sarah Smith",
    "organization": "City General Hospital"
  },
  "scope": {
    "resource_types": ["*"],
    "exclusions": [],
    "time_range": null
  },
  "purpose": ["TREATMENT"],
  "conditions": [
    {
      "type": "NOTIFICATION_REQUIRED",
      "parameters": {"notify_on": ["EXPORT"]}
    }
  ],
  "granted_at": "2026-01-15T08:00:00.000Z",
  "expires_at": null,
  "status": "ACTIVE",
  "signature": {
    "algorithm": "ED25519",
    "public_key_id": "did:haven:bob#key-1",
    "value": "MEYCIQCw...",
    "signed_at": "2026-01-15T08:00:00.000Z"
  }
}
```

---

## 10. Test Vectors

See `/test-vectors/consent/` for conformance test data.

### 10.1 Verification Test Cases

| Test Case | Expected Result |
|-----------|-----------------|
| Active consent, matching accessor, covered scope | AUTHORIZED |
| Active consent, wrong accessor | DENIED |
| Active consent, uncovered resource type | DENIED |
| Active consent, excluded resource type | DENIED |
| Revoked consent | DENIED |
| Expired consent | DENIED |
| Active consent, wrong purpose | DENIED |
| Active consent, condition not met | DENIED |

---

## 11. References

- [RFC 2119 - Keywords](https://datatracker.ietf.org/doc/html/rfc2119)
- [RFC 7515 - JSON Web Signature (JWS)](https://datatracker.ietf.org/doc/html/rfc7515)
- [Ed25519 (RFC 8032)](https://datatracker.ietf.org/doc/html/rfc8032)
- [PSDL Specification](https://github.com/Chesterguan/PSDL)

---

*HAVEN Specification 002 | Version 2.0.0 | January 28, 2026*
