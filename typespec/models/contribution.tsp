/**
 * Contribution Model Type Definitions
 *
 * The Contribution Model quantifies patient data value
 * for fair distribution.
 */

import "./common.tsp";

namespace Haven.Models;

// ============================================================================
// Enums
// ============================================================================

/** Contribution tiers based on data complexity */
enum ContributionTier {
  /** Demographics, basic info */
  @doc("Basic demographic and administrative data")
  PROFILE,

  /** Labs, meds, conditions */
  @doc("Coded clinical observations")
  STRUCTURED,

  /** Multi-year records */
  @doc("Extended temporal records (3+ years)")
  LONGITUDINAL,

  /** Notes, imaging, genomics */
  @doc("Rich, multi-modal data")
  COMPLEX,
}

/** Type of usage context */
enum ContextType {
  /** Clinical/observational study */
  RESEARCH_STUDY,

  /** Cohort identification query */
  COHORT_QUERY,

  /** Population-level analysis */
  AGGREGATE_ANALYSIS,

  /** ML model training */
  MODEL_TRAINING,

  /** ML model prediction */
  MODEL_INFERENCE,

  /** Healthcare quality reporting */
  QUALITY_MEASURE,

  /** Disease surveillance */
  PUBLIC_HEALTH,
}

/** Method for multi-party attribution */
enum AttributionMethod {
  /** Equal split across all participants */
  EQUAL,

  /** Weighted by quality score */
  QUALITY_WEIGHTED,

  /** Data Shapley values */
  SHAPLEY,

  /** Marginal contribution */
  MARGINAL,

  /** Implementation-defined */
  CUSTOM,
}

// ============================================================================
// Models
// ============================================================================

/** How data was used */
model UsageContext {
  /** Unique context identifier */
  contextId: string;

  /** Category of use */
  contextType: ContextType;

  /** Study/project reference */
  studyRef?: string;

  /** Specific query reference */
  queryRef?: string;

  /** Purpose from consent */
  purpose: PurposeType;

  /** When use occurred */
  timestamp: Timestamp;
}

/** Individual patient's share in multi-party attribution */
model PatientShare {
  /** Patient identifier */
  patientId: PatientID;

  /** Fraction of total value [0, 1] */
  @minValue(0)
  @maxValue(1)
  share: float32;

  /** Raw contribution value */
  @minValue(0)
  rawValue: float32;
}

/** Multi-party attribution details */
model Attribution {
  /** How attribution was computed */
  method: AttributionMethod;

  /** Value allocation per patient */
  shares: PatientShare[];

  /** Total patients in cohort */
  @minValue(1)
  totalPatients: int32;

  /** When attribution was computed */
  computedAt: Timestamp;
}

/** Breakdown of value components */
model ValueBreakdown {
  /** Tier weight component */
  @minValue(0)
  @maxValue(1)
  tierWeight: float32;

  /** Quality score component */
  @minValue(0)
  @maxValue(1)
  qualityScore: float32;

  /** Volume normalization component */
  @minValue(0)
  @maxValue(1)
  volumeNorm: float32;

  /** Context multiplier component */
  @minValue(0)
  contextMultiplier: float32;
}

/** Additional contribution metadata */
model ContributionMetadata {
  /** Number of records contributed */
  @minValue(0)
  recordCount?: int32;

  /** Time span of data in days */
  @minValue(0)
  timeSpanDays?: int32;

  /** Data types included */
  dataTypes?: DataType[];

  /** Implementation-specific fields */
  extensions?: Record<unknown>;
}

/**
 * Contribution
 *
 * Quantified patient data contribution for a specific usage context.
 */
@doc("Quantified patient data contribution")
model Contribution {
  /** Unique contribution identifier */
  contributionId: ContributionID;

  /** Contributing patient */
  patientId: PatientID;

  /** Health Assets included */
  @minItems(1)
  assetRefs: ContentHash[];

  /** Aggregate quality metric [0, 1] */
  @minValue(0)
  @maxValue(1)
  qualityScore: float32;

  /** Complexity tier */
  tier: ContributionTier;

  /** How data was used */
  context: UsageContext;

  /** Calculated contribution value [0, 1] */
  @minValue(0)
  @maxValue(1)
  rawValue: float32;

  /** When contribution was recorded */
  timestamp: Timestamp;

  /** Link to provenance entry */
  provenanceRef: ProvenanceID;

  /** Multi-party attribution (for cohort contributions) */
  attribution?: Attribution;

  /** Additional metadata */
  metadata?: ContributionMetadata;
}

/** Preview of contribution calculation (before recording) */
model ContributionPreview {
  /** Determined tier */
  tier: ContributionTier;

  /** Quality score */
  @minValue(0)
  @maxValue(1)
  qualityScore: float32;

  /** Volume normalization factor */
  @minValue(0)
  @maxValue(1)
  volumeNorm: float32;

  /** Context multiplier */
  @minValue(0)
  contextMultiplier: float32;

  /** Calculated raw value */
  @minValue(0)
  @maxValue(1)
  rawValue: float32;

  /** Component breakdown */
  breakdown: ValueBreakdown;
}

/** Filters for querying contributions */
model ContributionFilters {
  /** Filter by context types */
  contextTypes?: ContextType[];

  /** Contributions after this date */
  fromDate?: Timestamp;

  /** Contributions before this date */
  toDate?: Timestamp;

  /** Minimum contribution value */
  @minValue(0)
  minValue?: float32;

  /** Filter by tier */
  tiers?: ContributionTier[];

  /** Maximum results */
  @minValue(1)
  @maxValue(1000)
  limit?: int32 = 100;

  /** Pagination offset */
  @minValue(0)
  offset?: int32 = 0;
}

/** Aggregated contribution summary */
model ContributionSummary {
  /** Time period covered */
  period: TimeRange;

  /** Total contributions in period */
  @minValue(0)
  totalContributions: int32;

  /** Sum of all contribution values */
  @minValue(0)
  totalValue: float32;

  /** Breakdown by tier */
  byTier: TierBreakdown;

  /** Breakdown by context type */
  byContext: ContextBreakdown;

  /** Top contributing studies */
  topStudies: StudyContribution[];
}

/** Breakdown by contribution tier */
model TierBreakdown {
  /** Profile tier contributions */
  @minValue(0)
  profile: int32;

  /** Structured tier contributions */
  @minValue(0)
  structured: int32;

  /** Longitudinal tier contributions */
  @minValue(0)
  longitudinal: int32;

  /** Complex tier contributions */
  @minValue(0)
  complex: int32;
}

/** Breakdown by context type */
model ContextBreakdown {
  /** Research study contributions */
  @minValue(0)
  researchStudy: int32;

  /** Cohort query contributions */
  @minValue(0)
  cohortQuery: int32;

  /** Aggregate analysis contributions */
  @minValue(0)
  aggregateAnalysis: int32;

  /** Model training contributions */
  @minValue(0)
  modelTraining: int32;

  /** Other context contributions */
  @minValue(0)
  other: int32;
}

/** Contribution to a specific study */
model StudyContribution {
  /** Study reference */
  studyRef: string;

  /** Study name */
  studyName: string;

  /** Number of contributions */
  @minValue(0)
  contributionCount: int32;

  /** Total value contributed */
  @minValue(0)
  totalValue: float32;
}

/** Request to record a contribution */
model RecordContributionRequest {
  /** Patient making contribution */
  patientId: PatientID;

  /** Assets being contributed */
  @minItems(1)
  assetRefs: ContentHash[];

  /** Usage context */
  context: UsageContext;
}

/** Request to calculate contribution (preview) */
model CalculateContributionRequest {
  /** Assets to evaluate */
  @minItems(1)
  assetIds: ContentHash[];

  /** Context for calculation */
  context: UsageContext;
}

/** Reference tier weights */
model TierWeights {
  /** Weight for Profile tier */
  @minValue(0.1)
  @maxValue(1)
  profile: float32 = 0.25;

  /** Weight for Structured tier */
  @minValue(0.1)
  @maxValue(1)
  structured: float32 = 0.50;

  /** Weight for Longitudinal tier */
  @minValue(0.1)
  @maxValue(1)
  longitudinal: float32 = 0.75;

  /** Weight for Complex tier */
  @minValue(0.1)
  @maxValue(1)
  complex: float32 = 1.00;
}

/** Reference context multipliers */
model ContextMultipliers {
  /** Research study multiplier */
  @minValue(0)
  researchStudy: float32 = 1.0;

  /** Cohort query multiplier */
  @minValue(0)
  cohortQuery: float32 = 0.5;

  /** Aggregate analysis multiplier */
  @minValue(0)
  aggregateAnalysis: float32 = 0.3;

  /** Model training multiplier */
  @minValue(0)
  modelTraining: float32 = 1.5;

  /** Model inference multiplier */
  @minValue(0)
  modelInference: float32 = 0.2;

  /** Quality measure multiplier */
  @minValue(0)
  qualityMeasure: float32 = 0.4;

  /** Public health multiplier */
  @minValue(0)
  publicHealth: float32 = 0.1;
}
