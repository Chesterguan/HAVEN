/**
 * Consent Protocol Type Definitions
 *
 * The Consent Protocol defines how authorization is granted,
 * verified, and revoked in HAVEN.
 */

import "./common.tsp";

namespace Haven.Models;

// ============================================================================
// Enums
// ============================================================================

/** Authorized purposes for data use */
enum PurposeType {
  /** Direct patient care */
  TREATMENT,

  /** Scientific research */
  RESEARCH,

  /** Disease surveillance, outbreak response */
  PUBLIC_HEALTH,

  /** Healthcare quality assessment */
  QUALITY_IMPROVEMENT,

  /** Billing, insurance */
  PAYMENT,

  /** Healthcare operations */
  OPERATIONS,

  /** Health-related marketing */
  MARKETING,

  /** Machine learning model development */
  AI_TRAINING,

  /** Patient's own use */
  PERSONAL,
}

/** Current consent status */
enum ConsentStatus {
  /** Consent is valid and enforceable */
  ACTIVE,

  /** Patient withdrew consent */
  REVOKED,

  /** Consent passed expiration time */
  EXPIRED,

  /** Consent requested, not yet granted */
  PENDING,

  /** Patient declined consent request */
  REJECTED,
}

/** Types of usage conditions */
enum ConditionType {
  /** Data must be aggregated, no individual records */
  AGGREGATION_ONLY,

  /** Minimum population for query results */
  MIN_COHORT_SIZE,

  /** Prohibition on re-identification attempts */
  NO_REIDENTIFICATION,

  /** Access window (distinct from consent expiry) */
  TIME_LIMITED_ACCESS,

  /** Where data can be accessed */
  GEOGRAPHIC_RESTRICTION,

  /** Subset of stated purposes */
  PURPOSE_RESTRICTED,

  /** Notify patient on access */
  NOTIFICATION_REQUIRED,

  /** Require additional approval per access */
  APPROVAL_REQUIRED,

  /** Enhanced audit logging */
  AUDIT_REQUIRED,

  /** Data must not leave origin */
  COMPUTE_TO_DATA,

  /** Results require review before release */
  OUTPUT_REVIEW,
}

/** FHIR/OMOP resource types */
enum ResourceType {
  // Clinical
  Condition,
  Procedure,
  Encounter,
  DiagnosticReport,
  Observation,

  // Medications
  MedicationRequest,
  MedicationAdministration,
  MedicationStatement,

  // Laboratory
  @doc("Laboratory observations")
  Observation_laboratory: "Observation.laboratory",

  // Vital Signs
  @doc("Vital sign observations")
  Observation_vital_signs: "Observation.vital-signs",

  // Imaging
  ImagingStudy,
  Media,

  // Documents
  DocumentReference,
  Note,
  ClinicalImpression,

  // Demographics
  Patient,
  Person,

  // Administrative
  Coverage,
  Claim,
  ExplanationOfBenefit,

  // Genetic
  MolecularSequence,
  @doc("Genetic observations")
  Observation_genetics: "Observation.genetics",

  // Mental Health (sensitive)
  @doc("Mental health observations")
  Observation_mental_health: "Observation.mental_health",
  @doc("Mental health conditions")
  Condition_mental_health: "Condition.mental_health",

  // Wildcard
  @doc("All resource types")
  All: "*",
}

/** Semantic data categories */
enum DataClass {
  /** Name, DOB, contact (sensitive) */
  DEMOGRAPHICS,

  /** Diagnoses, procedures */
  CLINICAL,

  /** Lab results */
  LABORATORY,

  /** Drug exposures */
  MEDICATIONS,

  /** Radiology, pathology */
  IMAGING,

  /** Genetic data */
  GENOMIC,

  /** Mental health, substance use */
  BEHAVIORAL,

  /** Sexual/reproductive health */
  REPRODUCTIVE,

  /** Claims, coverage */
  FINANCIAL,
}

// ============================================================================
// Models
// ============================================================================

/** Data scope for consent */
model DataScope {
  /** Resource types to include */
  resourceTypes: ResourceType[];

  /** Resource types to explicitly exclude */
  exclusions?: ResourceType[];

  /** Temporal bounds for data */
  timeRange?: TimeRange;

  /** Semantic categories to include */
  dataClasses?: DataClass[];

  /** Specific asset IDs (if scoping to particular assets) */
  assetIds?: ContentHash[];

  /** Indicates scope is defined by PSDL policy */
  policyDefined?: boolean;
}

/** Usage condition */
model Condition {
  /** Type of condition */
  type: ConditionType;

  /** Condition-specific parameters */
  parameters: Record<unknown>;
}

/**
 * Consent Attestation
 *
 * A signed record of consent from a patient to an accessor
 * for specific data, purposes, and conditions.
 */
@doc("Signed consent attestation from patient to accessor")
model ConsentAttestation {
  /** Unique identifier for this consent */
  consentId: UUID;

  /** Patient granting consent */
  grantor: PatientIdentity;

  /** Entity receiving consent */
  grantee: AccessorIdentity;

  /** Data scope covered by consent */
  scope: DataScope;

  /** Authorized purposes (at least one required) */
  @minItems(1)
  purpose: PurposeType[];

  /** Usage restrictions */
  conditions?: Condition[];

  /** When consent was granted */
  grantedAt: Timestamp;

  /** When consent expires (null = no expiration) */
  expiresAt?: Timestamp;

  /** Current consent status */
  status: ConsentStatus;

  /** Cryptographic attestation */
  signature: CryptoSignature;

  /** When consent was revoked (if status is REVOKED) */
  revokedAt?: Timestamp;

  /** Reference to PSDL policy definition */
  policyRef?: PolicyReference;

  /** Additional metadata */
  metadata?: Record<unknown>;
}

/** Result of consent verification */
model ConsentVerificationResult {
  /** Whether access is authorized */
  authorized: boolean;

  /** Current consent status */
  consentStatus: ConsentStatus;

  /** Scope matching details */
  scopeMatch: ScopeMatchResult;

  /** Whether purpose matches */
  purposeMatch: boolean;

  /** Condition evaluation results */
  conditionsMet: ConditionResult[];

  /** Reasons for denial (if any) */
  denialReasons: string[];

  /** Time until consent expires */
  expiresIn?: duration;
}

/** Result of scope matching */
model ScopeMatchResult {
  /** All requested types are covered */
  fullMatch: boolean;

  /** Types that are covered */
  coveredTypes: ResourceType[];

  /** Types that are NOT covered */
  uncoveredTypes: ResourceType[];

  /** Whether time range is valid */
  timeRangeValid: boolean;
}

/** Result of condition evaluation */
model ConditionResult {
  /** Condition type evaluated */
  conditionType: ConditionType;

  /** Whether condition is satisfied */
  satisfied: boolean;

  /** Additional details */
  details: string;
}

/** Result of consent revocation */
model RevokeResult {
  /** Consent that was revoked */
  consentId: UUID;

  /** When revocation occurred */
  revokedAt: Timestamp;

  /** Previous status */
  previousStatus: ConsentStatus;
}

/** Filters for listing consents */
model ConsentFilters {
  /** Filter by status */
  status?: ConsentStatus[];

  /** Filter by grantee type */
  granteeType?: AccessorType[];

  /** Filter by purpose */
  purpose?: PurposeType[];

  /** Granted after this time */
  grantedAfter?: Timestamp;

  /** Granted before this time */
  grantedBefore?: Timestamp;

  /** Include expired consents */
  includeExpired?: boolean = false;

  /** Maximum results */
  @minValue(1)
  @maxValue(1000)
  limit?: int32 = 100;

  /** Pagination offset */
  @minValue(0)
  offset?: int32 = 0;
}

/** Request to grant new consent */
model GrantConsentRequest {
  /** Patient granting consent */
  grantor: PatientIdentity;

  /** Entity receiving consent */
  grantee: AccessorIdentity;

  /** Data scope */
  scope: DataScope;

  /** Authorized purposes */
  @minItems(1)
  purpose: PurposeType[];

  /** Usage conditions */
  conditions?: Condition[];

  /** When consent expires */
  expiresAt?: Timestamp;

  /** PSDL policy reference */
  policyRef?: PolicyReference;
}

/** Request to verify consent */
model VerifyConsentRequest {
  /** Consent to verify */
  consentId: UUID;

  /** Entity requesting access */
  accessor: AccessorIdentity;

  /** Requested data scope */
  requestedScope: DataScope;

  /** Purpose of access */
  requestedPurpose: PurposeType;
}
