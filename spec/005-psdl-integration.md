# HAVEN Specification 005: PSDL Integration

**Status**: Draft
**Version**: 2.0.0
**Date**: January 28, 2026
**Authors**: Chester Guan

---

## 1. Overview

This specification defines how HAVEN integrates with **PSDL** (Patient Scenario Definition Language) for declarative consent policies and clinical scenarios. PSDL makes authorization logic human-readable yet machine-executable.

### 1.1 PSDL Repository

**Official repository**: https://github.com/Chesterguan/PSDL

PSDL is a separate, complementary specification. This document defines the integration points, not the full PSDL language.

### 1.2 Integration Goals

1. **Reusable Policies**: Define consent templates as PSDL scenarios
2. **Transparent Logic**: Patients can understand consent in natural terms
3. **Deterministic Execution**: Same scenario + data = same result
4. **Auditability**: Every policy evaluation creates provenance

### 1.3 Scope

This specification defines:
- How PSDL policies are referenced in Consent Attestations
- Policy resolution and evaluation semantics
- Consent scope mapping
- Clinical scenario integration for cohort matching

---

## 2. PSDL Policy Reference

### 2.1 Reference Format

PSDL policies are referenced using a URI-style format:

```
PolicyReference := psdl:<repository>:<scenario>:<version>
```

**Components**:
- `repository`: Policy repository identifier (e.g., `haven/policies`, `stanford/research`)
- `scenario`: Scenario name (e.g., `research-consent`, `clinical-access`)
- `version`: Semantic version (e.g., `1.0.0`, `2.1.3`)

**Examples**:
```
psdl:haven/policies:research-consent:1.0.0
psdl:stanford/diabetes:cgm-study-consent:2.0.0
psdl:local:custom-policy:1.0.0
```

### 2.2 Reference in Consent Attestation

```json
{
  "consent_id": "550e8400-e29b-41d4-a716-446655440000",
  "grantor": {...},
  "grantee": {...},
  "scope": {"policy_defined": true},
  "purpose": ["RESEARCH"],
  "conditions": {"policy_defined": true},
  "policy_ref": "psdl:haven/policies:research-consent:1.0.0",
  "granted_at": "2026-01-28T10:30:00.000Z",
  "status": "ACTIVE",
  "signature": {...}
}
```

When `policy_ref` is present, `scope` and `conditions` MAY use `{"policy_defined": true}` to indicate values come from the referenced policy.

---

## 3. PSDL for Consent Policies

### 3.1 Consent Policy Structure

A PSDL consent policy defines scope and conditions declaratively:

```yaml
scenario: Research_Consent_Policy
version: "1.0.0"

audit:
  intent: "Define data sharing permissions for research participation"
  rationale: "Patient-controlled consent for biomedical research"
  provenance: "HAVEN Protocol v2.0"

# Data scope definition
scope:
  grant:
    - Observation.laboratory
    - Condition
    - MedicationRequest
    - Procedure
  deny:
    - Note.*                    # All clinical notes
    - Observation.mental_health
    - Condition.mental_health
    - DocumentReference.psychiatry

  time_range:
    start: "2020-01-01"
    end: null                   # Ongoing

# Usage conditions
conditions:
  - type: MIN_COHORT_SIZE
    minimum: 50
    action_on_violation: SUPPRESS

  - type: AGGREGATION_ONLY
    min_records: 10
    allowed_operations:
      - COUNT
      - AVG
      - PERCENTILE

  - type: NO_REIDENTIFICATION
    prohibition: ABSOLUTE
    attestation_required: true

  - type: PURPOSE_RESTRICTED
    allowed:
      - RESEARCH
      - PUBLIC_HEALTH

# Optional: additional metadata
metadata:
  category: research
  template: true
  tags: [diabetes, longitudinal, cgm]
```

### 3.2 Scope Mapping to HAVEN

PSDL scope elements map to HAVEN ConsentAttestation.scope:

| PSDL Element | HAVEN Field |
|--------------|-------------|
| `scope.grant` | `scope.resource_types` |
| `scope.deny` | `scope.exclusions` |
| `scope.time_range` | `scope.time_range` |
| `scope.data_classes` | `scope.data_classes` |

**Resolution Algorithm**:
```
function resolveScope(consent, policy):
    if consent.scope.policy_defined:
        return {
            resource_types: policy.scope.grant,
            exclusions: policy.scope.deny,
            time_range: policy.scope.time_range,
            data_classes: policy.scope.data_classes
        }
    else:
        // Explicit scope overrides policy
        return mergeScopes(consent.scope, policy.scope)
```

### 3.3 Condition Mapping

PSDL conditions map directly to HAVEN Condition types:

| PSDL Condition | HAVEN ConditionType |
|----------------|---------------------|
| `MIN_COHORT_SIZE` | `MIN_COHORT_SIZE` |
| `AGGREGATION_ONLY` | `AGGREGATION_ONLY` |
| `NO_REIDENTIFICATION` | `NO_REIDENTIFICATION` |
| `PURPOSE_RESTRICTED` | `PURPOSE_RESTRICTED` |
| `TIME_LIMITED_ACCESS` | `TIME_LIMITED_ACCESS` |
| `GEOGRAPHIC_RESTRICTION` | `GEOGRAPHIC_RESTRICTION` |

---

## 4. PSDL for Clinical Scenarios

### 4.1 Cohort Matching

PSDL clinical scenarios define patient inclusion criteria for research:

```yaml
scenario: T2DM_CGM_Cohort
version: "1.0.0"

audit:
  intent: "Identify Type 2 Diabetes patients suitable for CGM study"
  rationale: "CGM studies require confirmed T2DM with recent HbA1c"
  provenance: "ADA Standards of Medical Care 2024"

# Patient population criteria
population:
  age: ">= 30 AND <= 65"
  conditions:
    - type_2_diabetes         # SNOMED: 44054006
  medications:
    - metformin               # RxNorm: 6809
  min_history: 365d

# Clinical signals to evaluate
signals:
  HbA1c:
    ref: hemoglobin_a1c
    concept_id: 3004410       # OMOP standard concept
    unit: "%"

  glucose:
    ref: fasting_glucose
    concept_id: 3004501
    unit: mg/dL

# Temporal computations
trends:
  hba1c_recent:
    expr: last(HbA1c)
    description: "Most recent HbA1c value"

  hba1c_trend:
    expr: slope(HbA1c, 180d)
    description: "HbA1c change over 6 months"

# Matching logic
logic:
  eligible:
    when: hba1c_recent >= 7.0 AND hba1c_recent <= 10.0
    description: "HbA1c in target range for study"

  stable:
    when: abs(hba1c_trend) < 0.5
    description: "Relatively stable glycemic control"

  cohort_match:
    when: eligible AND stable
    severity: match
    description: "Matches CGM study eligibility criteria"
```

### 4.2 Scenario Evaluation

**Signature**:
```
evaluate(
    scenario: PSDLScenario,
    patient_data: HealthAsset[]
) → EvaluationResult
```

**Returns**:
```
EvaluationResult := {
    matched: boolean,
    triggered_rules: RuleResult[],
    confidence: Float[0, 1],
    signals_computed: SignalValue[],
    audit_entry: ProvenanceEntry
}

RuleResult := {
    rule_name: string,
    triggered: boolean,
    expression: string,
    computed_value: any
}
```

### 4.3 HAVEN Integration for Cohort Queries

When a researcher queries for eligible patients:

```
1. Researcher submits PSDL scenario
2. HAVEN validates scenario syntax
3. For each patient with matching consent:
   a. Retrieve authorized Health Assets
   b. Evaluate scenario against patient data
   c. Record QUERY_EXECUTED provenance
4. Return matched patients (subject to consent conditions)
5. Record CONTRIBUTION_RECORDED for each match
```

**Sequence Diagram**:
```
Researcher           HAVEN               Patient Data
    |                  |                      |
    |-- Submit PSDL -->|                      |
    |                  |                      |
    |                  |-- Verify consent --->|
    |                  |<-- Consent valid ----|
    |                  |                      |
    |                  |-- Fetch assets ----->|
    |                  |<-- Health Assets ----|
    |                  |                      |
    |                  |-- Evaluate PSDL ---->|
    |                  |<-- Match result -----|
    |                  |                      |
    |                  |-- Record provenance->|
    |<-- Results ------|                      |
```

---

## 5. PSDL Temporal Operators

### 5.1 Supported Operators

| Operator | Syntax | Description |
|----------|--------|-------------|
| `last` | `last(signal)` | Most recent value |
| `first` | `first(signal)` | Earliest value |
| `delta` | `delta(signal, window)` | Change over window |
| `slope` | `slope(signal, window)` | Linear trend |
| `ema` | `ema(signal, window)` | Exponential moving average |
| `min` | `min(signal, window)` | Minimum in window |
| `max` | `max(signal, window)` | Maximum in window |
| `avg` | `avg(signal, window)` | Average in window |
| `count` | `count(signal, window)` | Observation count |
| `any` | `any(signal, window)` | Any value present |
| `all` | `all(signal, window)` | All values satisfy |

### 5.2 Window Formats

```
30s   - 30 seconds
6h    - 6 hours
24h   - 24 hours / 1 day
7d    - 7 days
30d   - 30 days
90d   - 90 days
1y    - 1 year
3y    - 3 years
```

### 5.3 Operator Semantics

**delta(signal, window)**:
```
delta(signal, window) = last(signal) - first(signal, within=window)
```

**slope(signal, window)**:
```
slope(signal, window) = linear_regression_slope(signal.values_in(window))
```

**ema(signal, window)**:
```
ema(signal, window) = exponential_moving_average(
    signal.values,
    alpha = 2 / (window.observations + 1)
)
```

---

## 6. Policy Resolution

### 6.1 Resolution Process

When a consent references a PSDL policy:

```
function resolvePolicy(policy_ref: PolicyReference) → PSDLPolicy | Error:
    // 1. Parse reference
    {repository, scenario, version} = parseRef(policy_ref)

    // 2. Fetch from repository
    policy = fetchPolicy(repository, scenario, version)
    if policy == null:
        return Error("Policy not found")

    // 3. Validate syntax
    if not validatePSDL(policy):
        return Error("Invalid PSDL syntax")

    // 4. Check version compatibility
    if not compatibleVersion(policy, HAVEN_VERSION):
        return Error("Incompatible policy version")

    // 5. Cache for performance
    cache(policy_ref, policy)

    return policy
```

### 6.2 Repository Types

| Type | URI Prefix | Description |
|------|------------|-------------|
| `haven` | `psdl:haven/...` | Official HAVEN policies |
| `local` | `psdl:local/...` | Implementation-local policies |
| `<org>` | `psdl:<org>/...` | Organization-specific policies |

### 6.3 Version Resolution

- **Exact**: `1.0.0` matches only `1.0.0`
- **Minor**: `1.0.x` matches `1.0.*` (highest patch)
- **Major**: `1.x` matches `1.*.*` (highest minor.patch)

---

## 7. Execution Guarantees

### 7.1 Determinism

PSDL execution MUST be deterministic:

```
evaluate(scenario, data) at T1 == evaluate(scenario, data) at T2
```

**Requirements**:
- No random operations
- No external state (current time, random sources)
- Floating point operations use IEEE 754 semantics

### 7.2 Sandboxing

PSDL scenarios are sandboxed:

**ALLOWED**:
- Access declared signals
- Compute temporal features
- Boolean logic on declared signals

**NOT ALLOWED**:
- Access undeclared data
- External network calls
- File system access
- Arbitrary code execution

### 7.3 Auditability

Every PSDL evaluation creates provenance:

```json
{
  "event_type": "QUERY_EXECUTED",
  "details": {
    "scenario_ref": "psdl:haven/policies:t2dm-cohort:1.0.0",
    "scenario_hash": "sha256:abc123...",
    "signals_accessed": ["HbA1c", "glucose"],
    "rules_evaluated": ["eligible", "stable", "cohort_match"],
    "result": "MATCH",
    "execution_ms": 45
  }
}
```

---

## 8. Standard Consent Policies

### 8.1 Research Consent (Basic)

**Reference**: `psdl:haven/policies:research-basic:1.0.0`

```yaml
scenario: Research_Basic
version: "1.0.0"

audit:
  intent: "Basic research data sharing"
  rationale: "Enables participation in clinical research"

scope:
  grant:
    - Observation.laboratory
    - Condition
    - MedicationRequest
  deny:
    - Note.*
    - Observation.mental_health

conditions:
  - type: MIN_COHORT_SIZE
    minimum: 20
  - type: AGGREGATION_ONLY
    min_records: 5
```

### 8.2 Research Consent (Enhanced)

**Reference**: `psdl:haven/policies:research-enhanced:1.0.0`

```yaml
scenario: Research_Enhanced
version: "1.0.0"

audit:
  intent: "Enhanced research with longitudinal data"
  rationale: "Enables detailed research participation"

scope:
  grant:
    - Observation.*
    - Condition
    - MedicationRequest
    - Procedure
    - DiagnosticReport
  deny:
    - Note.*
    - Observation.mental_health
    - Condition.substance_abuse

conditions:
  - type: MIN_COHORT_SIZE
    minimum: 50
  - type: NO_REIDENTIFICATION
    prohibition: ABSOLUTE
  - type: AUDIT_REQUIRED
```

### 8.3 Clinical Care Consent

**Reference**: `psdl:haven/policies:clinical-care:1.0.0`

```yaml
scenario: Clinical_Care
version: "1.0.0"

audit:
  intent: "Enable clinical care access"
  rationale: "Healthcare providers need data for treatment"

scope:
  grant:
    - "*"
  deny: []

conditions:
  - type: PURPOSE_RESTRICTED
    allowed: [TREATMENT]
  - type: NOTIFICATION_REQUIRED
    notify_on: [EXPORT]
```

---

## 9. Conformance Requirements

### 9.1 MUST Requirements

Implementations MUST:

1. **M1**: Parse and validate PSDL policy references
2. **M2**: Resolve policies from configured repositories
3. **M3**: Evaluate PSDL scenarios deterministically
4. **M4**: Record provenance for all policy evaluations
5. **M5**: Enforce sandboxing constraints

### 9.2 SHOULD Requirements

Implementations SHOULD:

1. **S1**: Cache resolved policies for performance
2. **S2**: Support standard HAVEN policies
3. **S3**: Provide policy simulation/preview
4. **S4**: Support policy versioning

### 9.3 MAY Requirements

Implementations MAY:

1. **O1**: Extend PSDL with custom operators
2. **O2**: Implement local policy repositories
3. **O3**: Support policy inheritance
4. **O4**: Provide visual policy editors

---

## 10. Security Considerations

### 10.1 Policy Injection

**Threat**: Malicious policies accessing unauthorized data

**Mitigation**:
- Validate all PSDL syntax before execution
- Whitelist signal references
- Sandbox execution environment

### 10.2 Version Pinning

**Threat**: Policy changes affecting existing consents

**Mitigation**:
- Pin exact versions in consent attestations
- Require re-consent for policy upgrades
- Maintain version history

### 10.3 Repository Trust

**Threat**: Compromised policy repositories

**Mitigation**:
- Sign all policies cryptographically
- Verify policy signatures before execution
- Use trusted repository mirrors

---

## 11. Examples

### 11.1 Consent with PSDL Policy

```json
{
  "consent_id": "550e8400-e29b-41d4-a716-446655440000",
  "grantor": {
    "id": "patient:alice-12345",
    "type": "HAVEN_ID"
  },
  "grantee": {
    "id": "study:diabetes-cgm-2026",
    "type": "STUDY",
    "name": "CGM Outcomes Study"
  },
  "scope": {"policy_defined": true},
  "purpose": ["RESEARCH"],
  "conditions": {"policy_defined": true},
  "policy_ref": "psdl:stanford/diabetes:cgm-study-consent:1.0.0",
  "granted_at": "2026-01-28T10:30:00.000Z",
  "expires_at": "2027-01-28T10:30:00.000Z",
  "status": "ACTIVE",
  "signature": {...}
}
```

### 11.2 Cohort Query Evaluation Result

```json
{
  "matched": true,
  "triggered_rules": [
    {
      "rule_name": "eligible",
      "triggered": true,
      "expression": "hba1c_recent >= 7.0 AND hba1c_recent <= 10.0",
      "computed_value": true
    },
    {
      "rule_name": "stable",
      "triggered": true,
      "expression": "abs(hba1c_trend) < 0.5",
      "computed_value": true
    },
    {
      "rule_name": "cohort_match",
      "triggered": true,
      "expression": "eligible AND stable",
      "computed_value": true
    }
  ],
  "confidence": 0.95,
  "signals_computed": [
    {"name": "hba1c_recent", "value": 7.8, "unit": "%"},
    {"name": "hba1c_trend", "value": -0.2, "unit": "%/6mo"}
  ],
  "audit_entry": {
    "entry_id": "prov:chain001:entry:200",
    "event_type": "QUERY_EXECUTED"
  }
}
```

---

## 12. References

- [PSDL Repository](https://github.com/Chesterguan/PSDL)
- [HAVEN Consent Protocol](./002-consent-protocol.md)
- [HL7 FHIR Clinical Reasoning](https://hl7.org/fhir/R4/clinicalreasoning-module.html)

---

*HAVEN Specification 005 | Version 2.0.0 | January 28, 2026*
