# HAVEN Protocol Implementation Guide

**Version**: 2.0.0
**Date**: January 28, 2026

This guide explains how to implement HAVEN Protocol in your system.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Prerequisites](#2-prerequisites)
3. [Implementation Phases](#3-implementation-phases)
4. [Health Asset Implementation](#4-health-asset-implementation)
5. [Consent Protocol Implementation](#5-consent-protocol-implementation)
6. [Provenance Record Implementation](#6-provenance-record-implementation)
7. [Contribution Model Implementation](#7-contribution-model-implementation)
8. [Cryptographic Requirements](#8-cryptographic-requirements)
9. [Testing & Conformance](#9-testing--conformance)
10. [Deployment Considerations](#10-deployment-considerations)

---

## 1. Introduction

### 1.1 Purpose

This guide provides practical guidance for implementing HAVEN-compliant systems. It covers the four core primitives (Health Asset, Consent Protocol, Provenance Record, Contribution Model) and their integration.

### 1.2 Audience

- Backend engineers implementing HAVEN APIs
- Security engineers reviewing cryptographic implementations
- Integration engineers connecting existing health systems to HAVEN

### 1.3 Related Documents

| Document | Purpose |
|----------|---------|
| [Whitepaper](./WHITEPAPER.md) | Protocol overview and design rationale |
| [spec/001-health-asset.md](../spec/001-health-asset.md) | Health Asset specification |
| [spec/002-consent-protocol.md](../spec/002-consent-protocol.md) | Consent Protocol specification |
| [spec/003-provenance-record.md](../spec/003-provenance-record.md) | Provenance Record specification |
| [spec/004-contribution-model.md](../spec/004-contribution-model.md) | Contribution Model specification |
| [spec/005-psdl-integration.md](../spec/005-psdl-integration.md) | PSDL integration |

---

## 2. Prerequisites

### 2.1 Technical Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **Language** | Any with crypto libraries | TypeScript, Python, Go |
| **Database** | Any persistent store | PostgreSQL with JSONB |
| **Crypto library** | SHA-256, Ed25519 | libsodium or equivalent |
| **FHIR support** | FHIR R4 parsing | HAPI FHIR or fhir.js |

### 2.2 Dependencies

**Required capabilities:**
- SHA-256 hashing
- Ed25519 signing/verification (or ES256)
- JSON parsing with canonical serialization
- UUID v4 generation
- ISO 8601 timestamp handling

**Recommended libraries:**

| Language | Crypto | JSON | UUID |
|----------|--------|------|------|
| TypeScript | `@noble/ed25519` | `fast-json-stable-stringify` | `uuid` |
| Python | `cryptography` | `json` (sort_keys) | `uuid` |
| Go | `crypto/ed25519` | `encoding/json` | `github.com/google/uuid` |

### 2.3 Standards Familiarity

Implementers should understand:
- HL7 FHIR R4 (resource types, references)
- OHDSI OMOP CDM (if supporting OMOP substrate)
- RFC 2119 (MUST/SHOULD/MAY keywords)

---

## 3. Implementation Phases

### Phase 1: Foundation

1. Set up cryptographic primitives
2. Implement canonical JSON serialization
3. Create base types from TypeSpec definitions
4. Set up database schema

### Phase 2: Health Assets

1. Implement content addressing (SHA-256)
2. Implement quality assessment (three-gate protocol)
3. Create/verify Health Assets
4. Test with test vectors

### Phase 3: Consent Protocol

1. Implement consent attestation structure
2. Implement grant/verify/revoke operations
3. Integrate with Health Asset access
4. Test consent enforcement

### Phase 4: Provenance Records

1. Implement hash-chained entries
2. Implement Merkle tree construction
3. Integrate provenance recording
4. Test chain integrity

### Phase 5: Contribution Model

1. Implement quality scoring
2. Implement value calculation
3. Implement attribution methods
4. Test contribution tracking

---

## 4. Health Asset Implementation

### 4.1 Content Addressing

The `asset_id` MUST be computed using this algorithm:

```typescript
import { createHash } from 'crypto';

interface HealthAsset {
  asset_id?: string;
  data_ref: string;
  substrate: string;
  consent_ref: string;
  quality_class: string;
  provenance_ref: string;
  patient_ref: string;
  created_at: string;
  metadata?: Record<string, unknown>;
}

function computeAssetId(asset: HealthAsset): string {
  // 1. Create copy without asset_id
  const { asset_id, ...canonical } = asset;

  // 2. Sort keys recursively and serialize
  const json = JSON.stringify(canonical, Object.keys(canonical).sort());

  // 3. Compute SHA-256
  const hash = createHash('sha256').update(json, 'utf8').digest('hex');

  // 4. Return formatted hash
  return `sha256:${hash.toLowerCase()}`;
}
```

### 4.2 Quality Assessment (Three-Gate Protocol)

```typescript
interface QualityResult {
  passed: boolean;
  qualityClass: 'A' | 'B' | 'C' | 'D' | null;
  gate0: { passed: boolean; details: string };
  gate1: { score: number; passed: boolean };
  gate2: { score: number; class: string };
}

function assessQuality(data: ClinicalData): QualityResult {
  // Gate 0: Provenance validation
  const gate0 = validateProvenance(data);
  if (!gate0.passed) {
    return { passed: false, qualityClass: null, gate0, gate1: null, gate2: null };
  }

  // Gate 1: Structural completeness
  const gate1 = assessStructure(data);
  if (gate1.score < 0.80) {
    return { passed: true, qualityClass: 'D', gate0, gate1, gate2: null };
  }
  if (gate1.score < 0.95) {
    return { passed: true, qualityClass: 'C', gate0, gate1, gate2: null };
  }

  // Gate 2: Semantic mapping
  const gate2 = assessMapping(data);
  if (gate2.score >= 0.90) {
    return { passed: true, qualityClass: 'A', gate0, gate1, gate2 };
  }
  if (gate2.score >= 0.70) {
    return { passed: true, qualityClass: 'B', gate0, gate1, gate2 };
  }
  return { passed: true, qualityClass: 'C', gate0, gate1, gate2 };
}
```

### 4.3 Database Schema (PostgreSQL)

```sql
CREATE TABLE health_assets (
  asset_id VARCHAR(71) PRIMARY KEY,  -- sha256:64chars
  data_ref TEXT NOT NULL,
  substrate VARCHAR(20) NOT NULL,
  consent_ref VARCHAR(44) NOT NULL,  -- consent:uuid
  quality_class CHAR(1) NOT NULL CHECK (quality_class IN ('A','B','C','D')),
  provenance_ref TEXT NOT NULL,
  patient_ref TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  metadata JSONB,

  CONSTRAINT valid_asset_id CHECK (asset_id ~ '^sha256:[a-f0-9]{64}$'),
  CONSTRAINT valid_consent_ref CHECK (consent_ref ~ '^consent:[a-f0-9-]{36}$')
);

CREATE INDEX idx_assets_patient ON health_assets(patient_ref);
CREATE INDEX idx_assets_consent ON health_assets(consent_ref);
CREATE INDEX idx_assets_quality ON health_assets(quality_class);
```

---

## 5. Consent Protocol Implementation

### 5.1 Verification Algorithm

```typescript
interface VerifyResult {
  authorized: boolean;
  denialReasons: string[];
}

function verifyConsent(
  consent: ConsentAttestation,
  accessor: AccessorIdentity,
  requestedScope: DataScope,
  requestedPurpose: PurposeType
): VerifyResult {
  const denialReasons: string[] = [];

  // 1. Status check
  if (consent.status !== 'ACTIVE') {
    denialReasons.push('Consent not active');
    return { authorized: false, denialReasons };
  }

  // 2. Expiration check
  if (consent.expiresAt && new Date(consent.expiresAt) < new Date()) {
    denialReasons.push('Consent expired');
    return { authorized: false, denialReasons };
  }

  // 3. Grantee match
  if (!matchesGrantee(consent.grantee, accessor)) {
    denialReasons.push('Accessor not authorized');
    return { authorized: false, denialReasons };
  }

  // 4. Purpose match
  if (!consent.purpose.includes(requestedPurpose)) {
    denialReasons.push('Purpose not authorized');
    return { authorized: false, denialReasons };
  }

  // 5. Scope match (closed-world)
  const scopeResult = matchScope(consent.scope, requestedScope);
  if (!scopeResult.fullMatch) {
    denialReasons.push(`Uncovered types: ${scopeResult.uncoveredTypes.join(', ')}`);
    return { authorized: false, denialReasons };
  }

  // 6. Condition evaluation
  for (const condition of consent.conditions || []) {
    const result = evaluateCondition(condition, requestedScope, accessor);
    if (!result.satisfied) {
      denialReasons.push(result.details);
      return { authorized: false, denialReasons };
    }
  }

  return { authorized: true, denialReasons: [] };
}
```

### 5.2 Revocation (Critical Path)

Revocation MUST take effect immediately:

```typescript
async function revokeConsent(
  consentId: string,
  grantorId: string
): Promise<RevokeResult> {
  // Use database transaction with row-level lock
  return await db.transaction(async (tx) => {
    // Lock the consent row
    const consent = await tx.query(
      'SELECT * FROM consents WHERE consent_id = $1 FOR UPDATE',
      [consentId]
    );

    if (!consent) throw new Error('NOT_FOUND');
    if (consent.grantor_id !== grantorId) throw new Error('UNAUTHORIZED');
    if (consent.status !== 'ACTIVE') throw new Error('INVALID_STATE');

    // Update status
    const revokedAt = new Date().toISOString();
    await tx.query(
      'UPDATE consents SET status = $1, revoked_at = $2 WHERE consent_id = $3',
      ['REVOKED', revokedAt, consentId]
    );

    // Record provenance
    await recordProvenance(tx, {
      eventType: 'CONSENT_REVOKED',
      subject: { type: 'CONSENT_ATTESTATION', id: consentId },
      details: { reason: 'Patient requested' }
    });

    return { consentId, revokedAt, previousStatus: 'ACTIVE' };
  });
}
```

---

## 6. Provenance Record Implementation

### 6.1 Hash Chain Construction

```typescript
interface ProvenanceEntry {
  entryId: string;
  chainId: string;
  sequence: number;
  timestamp: string;
  eventType: string;
  actor: ActorIdentity;
  subject: SubjectRef;
  details: Record<string, unknown>;
  previousHash: string | null;
  entryHash: string;
  signature: CryptoSignature;
}

function computeEntryHash(entry: Omit<ProvenanceEntry, 'entryHash' | 'merkleProof'>): string {
  const canonical = JSON.stringify(entry, Object.keys(entry).sort());
  const hash = createHash('sha256').update(canonical, 'utf8').digest('hex');
  return `sha256:${hash.toLowerCase()}`;
}

async function appendEntry(
  chainId: string,
  eventType: string,
  actor: ActorIdentity,
  subject: SubjectRef,
  details: Record<string, unknown>
): Promise<ProvenanceEntry> {
  return await db.transaction(async (tx) => {
    // Get last entry
    const lastEntry = await tx.query(
      'SELECT * FROM provenance_entries WHERE chain_id = $1 ORDER BY sequence DESC LIMIT 1',
      [chainId]
    );

    const sequence = lastEntry ? lastEntry.sequence + 1 : 0;
    const previousHash = lastEntry ? lastEntry.entry_hash : null;

    // Build entry (without hash yet)
    const entry = {
      entryId: `prov:${chainId}:entry:${sequence}`,
      chainId,
      sequence,
      timestamp: new Date().toISOString(),
      eventType,
      actor,
      subject,
      details,
      previousHash
    };

    // Compute hash
    const entryHash = computeEntryHash(entry);

    // Sign
    const signature = await signEntry(entryHash, actor);

    const fullEntry = { ...entry, entryHash, signature };

    // Persist
    await tx.query('INSERT INTO provenance_entries ...', [fullEntry]);

    return fullEntry;
  });
}
```

### 6.2 Merkle Tree

```typescript
class MerkleTree {
  private leaves: string[];
  private layers: string[][];

  constructor(entryHashes: string[]) {
    this.leaves = entryHashes;
    this.layers = [this.leaves];
    this.buildTree();
  }

  private buildTree(): void {
    let currentLayer = this.leaves;

    while (currentLayer.length > 1) {
      const nextLayer: string[] = [];

      for (let i = 0; i < currentLayer.length; i += 2) {
        const left = currentLayer[i];
        const right = currentLayer[i + 1] || left; // Duplicate if odd
        const combined = createHash('sha256')
          .update(left + right)
          .digest('hex');
        nextLayer.push(`sha256:${combined}`);
      }

      this.layers.push(nextLayer);
      currentLayer = nextLayer;
    }
  }

  getRoot(): string {
    return this.layers[this.layers.length - 1][0];
  }

  getProof(leafIndex: number): MerkleProof {
    const path: ProofNode[] = [];
    let index = leafIndex;

    for (let i = 0; i < this.layers.length - 1; i++) {
      const layer = this.layers[i];
      const isLeft = index % 2 === 0;
      const siblingIndex = isLeft ? index + 1 : index - 1;

      if (siblingIndex < layer.length) {
        path.push({
          hash: layer[siblingIndex],
          position: isLeft ? 'RIGHT' : 'LEFT'
        });
      }

      index = Math.floor(index / 2);
    }

    return {
      rootHash: this.getRoot(),
      leafIndex,
      path,
      treeSize: this.leaves.length
    };
  }
}
```

---

## 7. Contribution Model Implementation

### 7.1 Value Calculation

```typescript
const TIER_WEIGHTS = {
  PROFILE: 0.25,
  STRUCTURED: 0.50,
  LONGITUDINAL: 0.75,
  COMPLEX: 1.00
};

const CONTEXT_MULTIPLIERS = {
  RESEARCH_STUDY: 1.0,
  COHORT_QUERY: 0.5,
  AGGREGATE_ANALYSIS: 0.3,
  MODEL_TRAINING: 1.5,
  MODEL_INFERENCE: 0.2,
  QUALITY_MEASURE: 0.4,
  PUBLIC_HEALTH: 0.1
};

interface ContributionValue {
  rawValue: number;
  tierWeight: number;
  qualityScore: number;
  volumeNorm: number;
  contextMultiplier: number;
}

function calculateContribution(
  tier: ContributionTier,
  qualityScore: number,
  recordCount: number,
  contextType: ContextType,
  referenceCount: number = 1000
): ContributionValue {
  const tierWeight = TIER_WEIGHTS[tier];
  const contextMultiplier = CONTEXT_MULTIPLIERS[contextType];

  // Volume normalization: log₂(1 + count) / log₂(1 + reference)
  const volumeNorm = Math.min(
    1.0,
    Math.log2(1 + recordCount) / Math.log2(1 + referenceCount)
  );

  const rawValue = tierWeight * qualityScore * volumeNorm * contextMultiplier;

  return {
    rawValue: Math.min(1.0, rawValue), // Cap at 1.0
    tierWeight,
    qualityScore,
    volumeNorm,
    contextMultiplier
  };
}
```

### 7.2 Tier Determination

```typescript
function determineTier(assets: HealthAsset[]): ContributionTier {
  const dataTypes = new Set(assets.map(a => a.metadata?.dataType).filter(Boolean));
  const timestamps = assets.map(a => new Date(a.created_at).getTime());
  const timeSpan = Math.max(...timestamps) - Math.min(...timestamps);
  const timeSpanYears = timeSpan / (365.25 * 24 * 60 * 60 * 1000);

  const hasComplex = dataTypes.has('GENOMIC') ||
                    dataTypes.has('IMAGING') ||
                    dataTypes.has('NOTES');

  const hasStructured = dataTypes.has('LABORATORY') ||
                       dataTypes.has('MEDICATIONS') ||
                       dataTypes.has('CONDITIONS');

  if (hasComplex) {
    return 'COMPLEX';
  } else if (hasStructured && timeSpanYears >= 3) {
    return 'LONGITUDINAL';
  } else if (hasStructured) {
    return 'STRUCTURED';
  } else {
    return 'PROFILE';
  }
}
```

---

## 8. Cryptographic Requirements

### 8.1 Signature Algorithm

Ed25519 is REQUIRED. Example using `@noble/ed25519`:

```typescript
import * as ed from '@noble/ed25519';

async function signMessage(
  message: string,
  privateKey: Uint8Array
): Promise<CryptoSignature> {
  const messageBytes = new TextEncoder().encode(message);
  const signature = await ed.signAsync(messageBytes, privateKey);

  return {
    algorithm: 'ED25519',
    publicKeyId: 'did:haven:user#key-1', // Your key ID scheme
    value: Buffer.from(signature).toString('base64url'),
    signedAt: new Date().toISOString()
  };
}

async function verifySignature(
  message: string,
  signature: CryptoSignature,
  publicKey: Uint8Array
): Promise<boolean> {
  const messageBytes = new TextEncoder().encode(message);
  const signatureBytes = Buffer.from(signature.value, 'base64url');
  return await ed.verifyAsync(signatureBytes, messageBytes, publicKey);
}
```

### 8.2 Key Management

- Store private keys in HSM or secure enclave
- Use separate keys for different purposes (consent signing vs. system signing)
- Implement key rotation procedures
- Never expose private keys in logs or error messages

---

## 9. Testing & Conformance

### 9.1 Using Test Vectors

Load and validate against test vectors:

```typescript
import { readFileSync, readdirSync } from 'fs';

function runTestVectors(primitive: string): void {
  const validDir = `test-vectors/${primitive}/valid`;
  const invalidDir = `test-vectors/${primitive}/invalid`;

  // Test valid cases - all MUST pass
  for (const file of readdirSync(validDir)) {
    const vector = JSON.parse(readFileSync(`${validDir}/${file}`, 'utf8'));
    const result = validate(vector.data);
    assert(result.valid, `Expected valid: ${file}`);
  }

  // Test invalid cases - all MUST fail
  for (const file of readdirSync(invalidDir)) {
    const vector = JSON.parse(readFileSync(`${invalidDir}/${file}`, 'utf8'));
    const result = validate(vector.data);
    assert(!result.valid, `Expected invalid: ${file}`);
    assert(result.error === vector._meta.expected_error, `Expected error ${vector._meta.expected_error}`);
  }
}
```

### 9.2 Conformance Checklist

| Requirement | Spec | Test |
|-------------|------|------|
| Health Asset content addressing | 001 M1 | Compute hash, compare with test vectors |
| Consent verification semantics | 002 M1-M7 | Run consent verification test cases |
| Provenance hash chain | 003 M1-M2 | Verify chain integrity |
| Contribution value formula | 004 M5 | Compare calculated values |

---

## 10. Deployment Considerations

### 10.1 Performance

| Operation | Target Latency | Optimization |
|-----------|----------------|--------------|
| Health Asset creation | < 500ms | Async quality assessment |
| Consent verification | < 50ms | Cache active consents |
| Provenance append | < 100ms | Batch Merkle updates |
| Contribution calculation | < 200ms | Pre-compute tier/quality |

### 10.2 Scalability

- Partition provenance chains by patient
- Index Health Assets by patient, consent, quality
- Consider event sourcing for high-volume deployments

### 10.3 Compliance

- HIPAA: Audit all access via provenance
- GDPR: Support consent revocation and data portability
- 21st Century Cures: Ensure FHIR R4 compatibility

---

## 11. References

- [HAVEN Protocol Specifications](../spec/)
- [TypeSpec Type Definitions](../typespec/)
- [Test Vectors](../test-vectors/)
- [PSDL Repository](https://github.com/Chesterguan/PSDL)

---

*HAVEN Implementation Guide | Version 2.0.0 | January 28, 2026*
