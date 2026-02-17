# HAVEN Specification 004: Contribution Model

**Status**: Draft
**Version**: 2.0.0
**Date**: January 28, 2026
**Authors**: Chester Guan

---

## 1. Overview

The **Contribution Model** quantifies patient data value for fair distribution. This is HAVEN's core innovation—transforming abstract "data value" into measurable, attributable contributions that enable patients to participate in the value their data creates.

### 1.1 Design Goals

1. **Quantifiable**: Patient contributions have measurable values
2. **Fair Attribution**: Value is attributed based on actual contribution
3. **Quality-weighted**: Higher quality data receives higher attribution
4. **Transparent**: Patients can understand how their contribution is calculated
5. **Context-aware**: Same data may have different value in different contexts

### 1.2 Scope

This specification defines:
- The Contribution data structure
- Contribution tiers and their semantics
- Quality scoring algorithm (three-gate protocol)
- Value calculation formula
- Fair attribution approaches
- Temporal value considerations

### 1.3 Research Foundation

The Contribution Model draws from:
- **Data Shapley values** for fair attribution (Ghorbani & Zou, 2019)
- **Quality-adjusted life years (QALY)** for health economics analogy
- **Marginal contribution** economics

---

## 2. Data Model

### 2.1 Contribution Structure

```
Contribution := {
    contribution_id : ContributionID    // REQUIRED - Unique identifier
    patient_id      : PatientID         // REQUIRED - Contributing patient
    asset_refs      : AssetRef[]        // REQUIRED - Assets included
    quality_score   : Float[0, 1]       // REQUIRED - Quality metric
    tier            : ContributionTier  // REQUIRED - Complexity tier
    context         : UsageContext      // REQUIRED - How data was used
    raw_value       : Float[0, 1]       // REQUIRED - Calculated contribution
    timestamp       : Timestamp         // REQUIRED - When recorded
    provenance_ref  : ProvenanceID      // REQUIRED - Audit link
    attribution     : Attribution       // OPTIONAL - Multi-party attribution
    metadata        : ContribMetadata   // OPTIONAL - Additional info
}
```

### 2.2 Field Definitions

#### 2.2.1 contribution_id (ContributionID)

Unique identifier for this contribution record.

**Format**: `contrib:<uuid>`

**Example**: `contrib:7f3d2a1b-8c4e-5f6a-9b0c-1d2e3f4a5b6c`

#### 2.2.2 patient_id (PatientID)

Reference to the patient who contributed data.

**Format**: Same as Health Asset patient_ref

#### 2.2.3 asset_refs (AssetRef[])

Health Assets included in this contribution.

**Constraints**:
- At least one asset MUST be referenced
- All assets MUST belong to the same patient
- All assets MUST have active consent for the usage context

#### 2.2.4 quality_score (Float)

Aggregate quality metric for the contribution.

**Range**: [0.0, 1.0]

**Computation**: See Section 4 (Quality Scoring)

#### 2.2.5 tier (ContributionTier)

Complexity tier based on data types included.

**Enumerated Values**:

| Tier | Description | Data Types | Relative Complexity |
|------|-------------|------------|---------------------|
| `PROFILE` | Basic demographics | Patient, demographics | Low |
| `STRUCTURED` | Coded clinical data | Labs, meds, conditions, procedures | Medium |
| `LONGITUDINAL` | Multi-year records | Structured + 3+ years | High |
| `COMPLEX` | Rich, unstructured | Notes, imaging, genomics | Highest |

**Tier Determination Rules**:
```
function determineTier(assets: HealthAsset[]) → ContributionTier:
    has_complex = any(asset.data_type in [GENOMIC, IMAGING, NOTES] for asset in assets)
    has_structured = any(asset.data_type in [LABS, MEDS, CONDITIONS] for asset in assets)
    time_span = maxDate(assets) - minDate(assets)

    if has_complex:
        return COMPLEX
    elif has_structured AND time_span >= 3 years:
        return LONGITUDINAL
    elif has_structured:
        return STRUCTURED
    else:
        return PROFILE
```

#### 2.2.6 context (UsageContext)

How the data was used.

**Structure**:
```
UsageContext := {
    context_id      : string            // REQUIRED - Unique context identifier
    context_type    : ContextType       // REQUIRED - Category of use
    study_ref       : string            // OPTIONAL - Study/project reference
    query_ref       : string            // OPTIONAL - Specific query
    purpose         : PurposeType       // REQUIRED - Purpose from consent
    timestamp       : Timestamp         // REQUIRED - When use occurred
}

ContextType := {
    RESEARCH_STUDY,     // Clinical/observational study
    COHORT_QUERY,       // Cohort identification query
    AGGREGATE_ANALYSIS, // Population-level analysis
    MODEL_TRAINING,     // ML model training
    MODEL_INFERENCE,    // ML model prediction
    QUALITY_MEASURE,    // Healthcare quality reporting
    PUBLIC_HEALTH       // Disease surveillance
}
```

#### 2.2.7 raw_value (Float)

Calculated contribution value before normalization.

**Range**: [0.0, 1.0]

**Formula**: See Section 5 (Value Calculation)

#### 2.2.8 attribution (Attribution) - OPTIONAL

For multi-party contributions, how value is split.

**Structure**:
```
Attribution := {
    method          : AttributionMethod // How attribution was computed
    shares          : PatientShare[]    // Value allocation
    total_patients  : integer           // Cohort size
    computed_at     : Timestamp
}

AttributionMethod := {
    EQUAL,          // Equal split across all participants
    QUALITY_WEIGHTED,// Weighted by quality score
    SHAPLEY,        // Data Shapley values
    MARGINAL,       // Marginal contribution
    CUSTOM          // Implementation-defined
}

PatientShare := {
    patient_id      : PatientID
    share           : Float[0, 1]       // Fraction of total value
    raw_value       : Float
}
```

---

## 3. Contribution Tiers

### 3.1 Tier Definitions

#### PROFILE Tier
**Description**: Basic demographic and administrative data

**Included Data Types**:
- Patient demographics (age, sex, location)
- Insurance/coverage information
- Healthcare utilization patterns (encounter counts)

**Typical Use Cases**:
- Population segmentation
- Market analysis
- Basic eligibility screening

**Reference Weight**: 0.25

#### STRUCTURED Tier
**Description**: Coded clinical observations

**Included Data Types**:
- Laboratory results (LOINC-coded)
- Medications (RxNorm-coded)
- Diagnoses (ICD-10, SNOMED-coded)
- Procedures (CPT-coded)
- Vital signs

**Typical Use Cases**:
- Cohort identification
- Outcomes research
- Drug safety monitoring

**Reference Weight**: 0.50

#### LONGITUDINAL Tier
**Description**: Extended temporal records

**Requirements**:
- All STRUCTURED tier data types
- Minimum 3 years of continuous data
- Temporal consistency (no major gaps)

**Typical Use Cases**:
- Disease progression studies
- Treatment effectiveness
- Predictive modeling

**Reference Weight**: 0.75

#### COMPLEX Tier
**Description**: Rich, multi-modal data

**Included Data Types**:
- Clinical notes (unstructured text)
- Medical imaging (DICOM)
- Genomic data (VCF, FASTQ)
- Waveform data (ECG, EEG)
- Patient-reported outcomes

**Typical Use Cases**:
- Deep learning model training
- Precision medicine
- Novel biomarker discovery

**Reference Weight**: 1.00

### 3.2 Tier Weight Configuration

Implementations SHOULD use reference weights but MAY adjust based on context:

```
TierWeights := {
    PROFILE:      0.25,
    STRUCTURED:   0.50,
    LONGITUDINAL: 0.75,
    COMPLEX:      1.00
}
```

**Constraints on Custom Weights**:
- PROFILE weight MUST be ≤ STRUCTURED weight
- STRUCTURED weight MUST be ≤ LONGITUDINAL weight
- LONGITUDINAL weight MUST be ≤ COMPLEX weight
- All weights MUST be in range [0.1, 1.0]

---

## 4. Quality Scoring

### 4.1 Three-Gate Protocol

Quality score is determined by the three-gate validation protocol:

```
┌─────────────────────────────────────────────────────────┐
│                   RAW DATA INPUT                         │
└────────────────────────┬────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│  GATE 0: PROVENANCE VALIDATION                          │
│  ├─ Source authentication                               │
│  ├─ Hash integrity verification                         │
│  └─ Temporal consistency check                          │
│                                                         │
│  Scoring: Pass (1.0) or Fail (REJECT)                   │
└────────────────────────┬────────────────────────────────┘
                    PASS │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  GATE 1: STRUCTURAL COMPLETENESS                        │
│  ├─ Required fields present                             │
│  ├─ Data type validation                                │
│  ├─ Code system validity                                │
│  └─ Reference integrity                                 │
│                                                         │
│  Scoring: Completeness ratio [0.0, 1.0]                 │
│  ├─ ≥ 0.95 → Pass (proceed to Gate 2)                   │
│  └─ < 0.95 → Class C (0.6) or D (0.4)                   │
└────────────────────────┬────────────────────────────────┘
                    PASS │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  GATE 2: SEMANTIC MAPPING                               │
│  ├─ Standard concept mapping (SNOMED, LOINC, RxNorm)    │
│  ├─ Cross-reference validation                          │
│  └─ Research-readiness assessment                       │
│                                                         │
│  Scoring: Mapping ratio [0.0, 1.0]                      │
│  ├─ ≥ 0.90 → Class A (1.0)                              │
│  ├─ 0.70-0.89 → Class B (0.8)                           │
│  └─ < 0.70 → Class C (0.6)                              │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Gate 0: Provenance Validation

**Checks**:
1. **Source Authentication**: Data source has valid signature from known origin
2. **Hash Integrity**: Content hash matches declared hash
3. **Temporal Consistency**: No future dates, logical ordering

**Scoring**:
- Pass: Continue to Gate 1
- Fail: REJECT (cannot create contribution)

**Algorithm**:
```
function gate0(data) → {pass: boolean, details: object}:
    // Source authentication
    if not verifySourceSignature(data.source):
        return {pass: false, reason: "Invalid source signature"}

    // Hash integrity
    computed_hash = computeContentHash(data.content)
    if computed_hash != data.declared_hash:
        return {pass: false, reason: "Hash mismatch"}

    // Temporal consistency
    for record in data.records:
        if record.timestamp > now():
            return {pass: false, reason: "Future timestamp"}

    return {pass: true}
```

### 4.3 Gate 1: Structural Completeness

**Checks**:
1. **Required Fields**: Schema-required fields are present
2. **Data Types**: Values match expected types
3. **Code Validity**: Coded values are valid in their code systems
4. **Reference Integrity**: Internal references resolve

**Scoring**:
```
function gate1(data) → Float[0, 1]:
    total_checks = 0
    passed_checks = 0

    for record in data.records:
        for field in record.required_fields:
            total_checks += 1
            if field.present AND field.valid_type AND field.valid_code:
                passed_checks += 1

    completeness = passed_checks / total_checks
    return completeness
```

**Thresholds**:
- ≥ 0.95: Pass (proceed to Gate 2)
- 0.80-0.94: Class C (quality_score = 0.6)
- < 0.80: Class D (quality_score = 0.4)

### 4.4 Gate 2: Semantic Mapping

**Checks**:
1. **Concept Mapping**: Local codes map to standard vocabularies
2. **Mapping Quality**: Mappings are direct (not approximate)
3. **Research Readiness**: Data can be queried with standard analytics

**Scoring**:
```
function gate2(data) → Float[0, 1]:
    total_concepts = 0
    mapped_concepts = 0

    for record in data.records:
        for concept in record.coded_concepts:
            total_concepts += 1
            mapping = findMapping(concept, target_vocab)
            if mapping AND mapping.relationship == "EXACT":
                mapped_concepts += 1
            elif mapping AND mapping.relationship == "NARROWER":
                mapped_concepts += 0.5

    mapping_ratio = mapped_concepts / total_concepts
    return mapping_ratio
```

**Thresholds**:
- ≥ 0.90: Class A (quality_score = 1.0)
- 0.70-0.89: Class B (quality_score = 0.8)
- < 0.70: Class C (quality_score = 0.6)

### 4.5 Quality Score Calculation

```
function calculateQualityScore(data) → Float[0, 1]:
    // Gate 0: Binary pass/fail
    gate0_result = gate0(data)
    if not gate0_result.pass:
        return REJECT

    // Gate 1: Structural completeness
    gate1_score = gate1(data)
    if gate1_score < 0.80:
        return 0.4  // Class D
    if gate1_score < 0.95:
        return 0.6  // Class C

    // Gate 2: Semantic mapping
    gate2_score = gate2(data)
    if gate2_score >= 0.90:
        return 1.0  // Class A
    if gate2_score >= 0.70:
        return 0.8  // Class B
    return 0.6      // Class C
```

### 4.6 Quality Class Summary

| Class | Quality Score | Gate 0 | Gate 1 (≥95%) | Gate 2 (≥90%/70%) |
|-------|---------------|--------|---------------|-------------------|
| A | 1.0 | Pass | Pass | ≥90% |
| B | 0.8 | Pass | Pass | 70-89% |
| C | 0.6 | Pass | Partial or <70% | N/A |
| D | 0.4 | Pass | Fail (<80%) | N/A |
| REJECT | N/A | Fail | N/A | N/A |

---

## 5. Value Calculation

### 5.1 Base Formula

```
ContributionValue = TierWeight × QualityScore × VolumeNorm × ContextMultiplier
```

**Components**:
- **TierWeight**: Weight based on contribution tier (Section 3.2)
- **QualityScore**: Quality assessment result (Section 4)
- **VolumeNorm**: Volume normalization factor
- **ContextMultiplier**: Usage context adjustment

### 5.2 Volume Normalization (VolumeNorm)

Volume normalization prevents gaming through data quantity while rewarding meaningful volume.

**Formula**:
```
VolumeNorm = min(1.0, log₂(1 + RecordCount) / log₂(1 + ReferenceCount))
```

**Parameters**:
- `RecordCount`: Number of records in contribution
- `ReferenceCount`: Context-dependent reference (e.g., 1000 for typical study)

**Rationale**: Logarithmic scaling provides diminishing returns for volume, rewarding data diversity over raw quantity.

**Example**:
```
RecordCount = 100, ReferenceCount = 1000
VolumeNorm = log₂(101) / log₂(1001)
          = 6.66 / 9.97
          = 0.67
```

### 5.3 Context Multiplier

Different usage contexts may have different value profiles.

**Reference Multipliers**:

| Context Type | Multiplier | Rationale |
|--------------|------------|-----------|
| `RESEARCH_STUDY` | 1.0 | Base reference |
| `COHORT_QUERY` | 0.5 | Lower intensity use |
| `AGGREGATE_ANALYSIS` | 0.3 | Highly aggregated |
| `MODEL_TRAINING` | 1.5 | Intensive, high-value use |
| `MODEL_INFERENCE` | 0.2 | Per-prediction, low intensity |
| `QUALITY_MEASURE` | 0.4 | Routine reporting |
| `PUBLIC_HEALTH` | 0.1 | Societal benefit emphasis |

**Custom Multipliers**: Implementations MAY define custom multipliers but MUST document them.

### 5.4 Complete Calculation Example

```
Patient Alice contributes to Study X:
  - 3 years of lab data → Tier: LONGITUDINAL
  - 847 measurements, 23 conditions, 15 medications
  - Quality Class A (all gates passed)
  - Context: RESEARCH_STUDY

Calculation:
  TierWeight      = 0.75 (LONGITUDINAL)
  QualityScore    = 1.0 (Class A)
  RecordCount     = 847 + 23 + 15 = 885
  ReferenceCount  = 1000
  VolumeNorm      = min(1.0, log₂(886) / log₂(1001))
                  = min(1.0, 9.79 / 9.97)
                  = 0.98
  ContextMult     = 1.0 (RESEARCH_STUDY)

  ContributionValue = 0.75 × 1.0 × 0.98 × 1.0
                    = 0.735
```

---

## 6. Fair Attribution

### 6.1 Challenge

When multiple patients contribute to a study, how should value be distributed fairly?

**Scenarios**:
1. **Homogeneous cohort**: All patients contribute similar data
2. **Heterogeneous cohort**: Varying data quality and volume
3. **Rare condition**: Some patients uniquely valuable
4. **Model training**: Complex interaction effects

### 6.2 Attribution Methods

#### 6.2.1 EQUAL Attribution

**Description**: Split value equally among all contributing patients.

**Formula**:
```
PatientShare[i] = TotalValue / N
```

**When to use**:
- Simple, explainable
- When quality is approximately uniform
- When marginal contributions are similar

#### 6.2.2 QUALITY_WEIGHTED Attribution

**Description**: Weight by individual contribution values.

**Formula**:
```
PatientShare[i] = (ContributionValue[i] / Σ ContributionValue) × TotalValue
```

**When to use**:
- Default recommendation
- Quality varies significantly
- Want to incentivize quality improvement

#### 6.2.3 SHAPLEY Attribution

**Description**: Game-theoretic fair value based on marginal contribution across all possible coalitions.

**Formula** (simplified):
```
Shapley[i] = Σ [ |S|!(n-|S|-1)! / n! ] × [ v(S ∪ {i}) - v(S) ]
```
Where `v(S)` is the value function for coalition S.

**Properties**:
- **Efficiency**: Sum of Shapley values equals total value
- **Symmetry**: Equal contributors get equal share
- **Null player**: Non-contributors get zero
- **Additivity**: Consistent across compositions

**When to use**:
- High-stakes, high-value use cases
- Need provably fair attribution
- Computational resources available

**Approximation**: Exact Shapley is O(2^n). Use Monte Carlo approximation:
```
function approximateShapley(patients, v, iterations = 1000):
    shapley = [0] * len(patients)

    for _ in range(iterations):
        perm = randomPermutation(patients)
        coalition = {}
        prev_value = 0

        for i, patient in enumerate(perm):
            coalition.add(patient)
            curr_value = v(coalition)
            shapley[patient] += curr_value - prev_value
            prev_value = curr_value

    return [s / iterations for s in shapley]
```

#### 6.2.4 MARGINAL Attribution

**Description**: Attribute based on marginal contribution when added to existing cohort.

**Formula**:
```
Marginal[i] = v(All) - v(All \ {i})
```

**When to use**:
- Simpler than Shapley
- When order of contribution matters
- For incremental value calculation

**Caveat**: Order-dependent; same patient may get different values depending on when they joined.

### 6.3 Attribution Selection Guide

| Factor | EQUAL | QUALITY_WEIGHTED | SHAPLEY | MARGINAL |
|--------|-------|------------------|---------|----------|
| Simplicity | ★★★★★ | ★★★★ | ★★ | ★★★ |
| Fairness | ★★★ | ★★★★ | ★★★★★ | ★★★ |
| Compute cost | O(1) | O(n) | O(n!) or O(n²) approx | O(n) |
| Incentive alignment | Low | High | Highest | Medium |
| Explainability | High | High | Low | Medium |

**Recommendation**: Use QUALITY_WEIGHTED as default. Use SHAPLEY for high-value model training where fairness is critical.

---

## 7. Temporal Value

### 7.1 Challenge

Does 5-year-old data have the same value as current data?

### 7.2 Temporal Decay Model

Some data types decay in value over time:

```
TemporalValue = BaseValue × DecayFactor(age)
```

**Decay Functions by Data Type**:

| Data Type | Decay Model | Half-life | Rationale |
|-----------|-------------|-----------|-----------|
| Demographics | None | ∞ | Age, sex stable |
| Genomics | None | ∞ | Genome stable |
| Historical diagnoses | Slow | 10 years | Chronic conditions persist |
| Labs | Moderate | 2 years | Physiologic state changes |
| Vitals | Fast | 6 months | Highly variable |
| Medications | Moderate | 1 year | Treatment changes |

**Decay Function**:
```
function decayFactor(age_days, half_life_days):
    if half_life_days == INFINITY:
        return 1.0
    return 0.5 ^ (age_days / half_life_days)
```

### 7.3 Temporal Value Calculation

```
function temporalValue(asset, reference_date):
    age = reference_date - asset.created_at
    half_life = getHalfLife(asset.data_type)
    decay = decayFactor(age, half_life)
    return asset.contribution_value × decay
```

### 7.4 When NOT to Apply Decay

Decay should NOT be applied when:
- Historical data is explicitly requested (e.g., "all data from 2020")
- Longitudinal analysis requires complete history
- Studying disease progression or outcomes

---

## 8. Multi-Use Attribution

### 8.1 Challenge

If the same data is used in 5 studies, does the patient get paid 5x?

### 8.2 Attribution Models

#### 8.2.1 Per-Use Model
**Description**: Patient receives value for each use.

**Formula**:
```
TotalValue = Σ ValuePerUse[i]
```

**Pros**: Simple, clear incentive
**Cons**: May overcompensate high-volume data

#### 8.2.2 License Model
**Description**: One-time value grant for unlimited use within consent scope.

**Formula**:
```
TotalValue = FixedLicenseValue
```

**Pros**: Predictable costs for researchers
**Cons**: May undervalue highly-reused data

#### 8.2.3 Hybrid Model (Recommended)
**Description**: Base license fee + diminishing per-use fee.

**Formula**:
```
TotalValue = BaseLicense + Σ (UseValue × DecayingMultiplier[i])

DecayingMultiplier = 1 / (1 + log₂(use_count))
```

**Example**:
```
BaseLicense = 0.5
UseValue = 0.3

Use 1: 0.5 + 0.3 × (1/1) = 0.80
Use 2: 0.5 + 0.3 × (1/1) + 0.3 × (1/2) = 0.95
Use 3: 0.5 + 0.3 × 1 + 0.3 × 0.5 + 0.3 × 0.37 = 1.06
...
Converges to ~1.5 as uses → ∞
```

### 8.3 Recommendation

Use Hybrid Model with:
- `BaseLicense` = 50% of theoretical single-use value
- `UseValue` = 30% of theoretical single-use value
- Logarithmic decay on subsequent uses

---

## 9. Operations

### 9.1 record()

Records a new contribution.

**Signature**:
```
record(
    patient_id: PatientID,
    asset_refs: AssetRef[],
    context: UsageContext
) → Contribution | Error
```

**Preconditions**:
- All assets MUST have active consent for the context
- Assets MUST belong to the patient

**Postconditions**:
- Contribution persisted
- Provenance entry `CONTRIBUTION_RECORDED` created
- Attribution calculated (if multi-party)

### 9.2 calculate()

Calculates contribution value without recording.

**Signature**:
```
calculate(
    assets: HealthAsset[],
    context: UsageContext
) → ContributionPreview
```

**Returns**:
```
ContributionPreview := {
    tier: ContributionTier,
    quality_score: Float,
    volume_norm: Float,
    context_mult: Float,
    raw_value: Float,
    breakdown: ValueBreakdown
}
```

### 9.3 query()

Queries contribution history.

**Signature**:
```
query(
    patient_id: PatientID,
    filters?: ContributionFilters
) → Contribution[]
```

**Filters**:
```
ContributionFilters := {
    context_types?: ContextType[],
    from_date?: Timestamp,
    to_date?: Timestamp,
    min_value?: Float,
    limit?: integer
}
```

### 9.4 aggregate()

Aggregates contributions for reporting.

**Signature**:
```
aggregate(
    patient_id: PatientID,
    period: TimePeriod
) → ContributionSummary
```

**Returns**:
```
ContributionSummary := {
    period: TimePeriod,
    total_contributions: integer,
    total_value: Float,
    by_tier: TierBreakdown,
    by_context: ContextBreakdown,
    top_studies: StudyContribution[]
}
```

---

## 10. Serialization

### 10.1 JSON Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": [
    "contribution_id",
    "patient_id",
    "asset_refs",
    "quality_score",
    "tier",
    "context",
    "raw_value",
    "timestamp",
    "provenance_ref"
  ],
  "properties": {
    "contribution_id": {
      "type": "string",
      "pattern": "^contrib:[a-f0-9-]{36}$"
    },
    "patient_id": {
      "type": "string"
    },
    "asset_refs": {
      "type": "array",
      "items": {"type": "string"},
      "minItems": 1
    },
    "quality_score": {
      "type": "number",
      "minimum": 0,
      "maximum": 1
    },
    "tier": {
      "type": "string",
      "enum": ["PROFILE", "STRUCTURED", "LONGITUDINAL", "COMPLEX"]
    },
    "context": {
      "$ref": "#/$defs/UsageContext"
    },
    "raw_value": {
      "type": "number",
      "minimum": 0,
      "maximum": 1
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "provenance_ref": {
      "type": "string"
    },
    "attribution": {
      "$ref": "#/$defs/Attribution"
    }
  }
}
```

---

## 11. Conformance Requirements

### 11.1 MUST Requirements

Implementations MUST:

1. **M1**: Calculate quality_score using the three-gate protocol
2. **M2**: Assign tier based on data type rules
3. **M3**: Record provenance for all contributions
4. **M4**: Verify consent before recording contribution
5. **M5**: Use the base formula for value calculation
6. **M6**: Support QUALITY_WEIGHTED attribution method

### 11.2 SHOULD Requirements

Implementations SHOULD:

1. **S1**: Support SHAPLEY attribution for high-value contexts
2. **S2**: Apply temporal decay to appropriate data types
3. **S3**: Use hybrid model for multi-use attribution
4. **S4**: Provide contribution previews before recording

### 11.3 MAY Requirements

Implementations MAY:

1. **O1**: Define custom tier weights (within constraints)
2. **O2**: Define custom context multipliers
3. **O3**: Implement additional attribution methods
4. **O4**: Support real-time contribution streaming

---

## 12. Security Considerations

### 12.1 Threat Model

| Threat | Description | Mitigation |
|--------|-------------|------------|
| Value inflation | Gaming quality scores | Independent quality assessment |
| Sybil attacks | Creating fake patients | Identity verification |
| Data duplication | Submitting same data twice | Asset deduplication via content hash |
| Attribution manipulation | Falsely claiming contribution | Cryptographic provenance |

### 12.2 Implementation Guidance

- Audit quality assessments regularly
- Implement anomaly detection for contribution patterns
- Use independent validators for high-value contributions
- Rate limit contribution recording

---

## 13. Examples

### 13.1 Research Study Contribution

```json
{
  "contribution_id": "contrib:7f3d2a1b-8c4e-5f6a-9b0c-1d2e3f4a5b6c",
  "patient_id": "patient:alice-12345",
  "asset_refs": [
    "sha256:asset1...",
    "sha256:asset2...",
    "sha256:asset3..."
  ],
  "quality_score": 1.0,
  "tier": "LONGITUDINAL",
  "context": {
    "context_id": "ctx:study-001-alice",
    "context_type": "RESEARCH_STUDY",
    "study_ref": "study:diabetes-cgm-2026",
    "purpose": "RESEARCH",
    "timestamp": "2026-01-28T14:30:00.000Z"
  },
  "raw_value": 0.735,
  "timestamp": "2026-01-28T14:30:00.000Z",
  "provenance_ref": "prov:chain001:entry:150",
  "metadata": {
    "record_count": 885,
    "time_span_days": 1095,
    "data_types": ["LABS", "CONDITIONS", "MEDICATIONS"]
  }
}
```

### 13.2 Cohort Query Contribution

```json
{
  "contribution_id": "contrib:9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d",
  "patient_id": "patient:bob-67890",
  "asset_refs": [
    "sha256:asset4..."
  ],
  "quality_score": 0.8,
  "tier": "STRUCTURED",
  "context": {
    "context_id": "ctx:query-789",
    "context_type": "COHORT_QUERY",
    "query_ref": "query:eligibility-screen-2026-01",
    "purpose": "RESEARCH",
    "timestamp": "2026-01-28T09:15:00.000Z"
  },
  "raw_value": 0.16,
  "timestamp": "2026-01-28T09:15:00.000Z",
  "provenance_ref": "prov:chain002:entry:42"
}
```

---

## 14. Test Vectors

See `/test-vectors/contribution/` for conformance test data.

### 14.1 Value Calculation Test Cases

| Tier | Quality | Records | Context | Expected Value |
|------|---------|---------|---------|----------------|
| PROFILE | 1.0 (A) | 10 | RESEARCH_STUDY | 0.25 × 1.0 × 0.33 × 1.0 = 0.083 |
| STRUCTURED | 0.8 (B) | 100 | RESEARCH_STUDY | 0.50 × 0.8 × 0.67 × 1.0 = 0.268 |
| LONGITUDINAL | 1.0 (A) | 1000 | MODEL_TRAINING | 0.75 × 1.0 × 1.0 × 1.5 = 1.125 |
| COMPLEX | 0.6 (C) | 50 | AGGREGATE_ANALYSIS | 1.0 × 0.6 × 0.56 × 0.3 = 0.101 |

---

## 15. References

- Ghorbani, A., & Zou, J. (2019). Data Shapley: Equitable Valuation of Data for Machine Learning. ICML.
- Jia, R., et al. (2019). Towards Efficient Data Valuation Based on the Shapley Value. AISTATS.
- OHDSI Data Quality Framework. https://ohdsi.github.io/DataQualityDashboard/

---

*HAVEN Specification 004 | Version 2.0.0 | January 28, 2026*
