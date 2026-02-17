/**
 * Health Asset Type Definitions
 *
 * A Health Asset is a governed data reference - not raw data itself,
 * but a pointer with embedded governance metadata.
 */

import "./common.tsp";

namespace Haven.Models;

// ============================================================================
// Enums
// ============================================================================

/** Supported data substrate formats */
enum SubstrateType {
  /** HL7 FHIR Release 4 */
  @doc("FHIR R4 format")
  FHIR_R4: "FHIR-R4",

  /** OHDSI OMOP CDM version 5.4 */
  @doc("OMOP CDM 5.4 format")
  OMOP_CDM_5_4: "OMOP-CDM-5.4",

  /** OHDSI OMOP CDM version 6.0 */
  @doc("OMOP CDM 6.0 format")
  OMOP_CDM_6_0: "OMOP-CDM-6.0",

  /** Medical Event Data Standard */
  @doc("MEDS format")
  MEDS: "MEDS",

  /** HL7 CDA Release 2 */
  @doc("CDA R2 format")
  CDA_R2: "CDA-R2",

  /** Implementation-specific format */
  @doc("Custom format")
  CUSTOM: "CUSTOM",
}

/** Quality class grades from A (best) to D (lowest) */
enum QualityClass {
  /** Highest quality - all gates passed */
  @doc("Research-ready, fully mapped")
  A,

  /** High quality - partial Gate 2 */
  @doc("Research-usable, some unmapped concepts")
  B,

  /** Moderate quality - partial Gate 1 */
  @doc("Structurally incomplete")
  C,

  /** Low quality - Gate 0 only */
  @doc("Provenance valid, minimal structure")
  D,
}

/** Clinical data category */
enum DataType {
  /** Patient demographics */
  DEMOGRAPHICS,

  /** Laboratory results */
  LABORATORY,

  /** Medication records */
  MEDICATIONS,

  /** Diagnosis conditions */
  CONDITIONS,

  /** Clinical procedures */
  PROCEDURES,

  /** Vital sign measurements */
  VITAL_SIGNS,

  /** Medical imaging */
  IMAGING,

  /** Clinical notes */
  NOTES,

  /** Genomic data */
  GENOMIC,

  /** Device/wearable data */
  DEVICE,

  /** Patient-reported outcomes */
  PRO,
}

// ============================================================================
// Models
// ============================================================================

/** Additional asset attributes */
model AssetMetadata {
  /** Origin system identifier */
  sourceSystem?: string;

  /** Clinical data category */
  dataType?: DataType;

  /** Number of records (if aggregate) */
  @minValue(0)
  recordCount?: int32;

  /** Temporal coverage of the data */
  timeRange?: TimeRange;

  /** Asset version */
  version?: string;

  /** Classification tags */
  tags?: string[];

  /** Implementation-specific extensions */
  extensions?: Record<unknown>;
}

/**
 * Health Asset - A governed reference to clinical data
 *
 * Health Assets are never "naked" data - they always include
 * consent reference, quality classification, and provenance linkage.
 */
@doc("A governed reference to clinical data with embedded governance metadata")
model HealthAsset {
  /** Content-derived unique identifier */
  @doc("SHA-256 hash of canonical content")
  assetId: ContentHash;

  /** URI pointing to the underlying clinical data */
  @doc("Secure reference to clinical data (fhir://, omop://, haven://)")
  dataRef: url;

  /** Data format identifier */
  substrate: SubstrateType;

  /** Reference to active consent policy */
  @doc("Consent governing this asset - MUST be active")
  consentRef: ConsentID;

  /** Data quality grade */
  @doc("Quality class from three-gate protocol")
  qualityClass: QualityClass;

  /** Audit chain reference */
  provenanceRef: ProvenanceID;

  /** Owner patient reference */
  patientRef: PatientID;

  /** Creation timestamp (UTC) */
  createdAt: Timestamp;

  /** Optional additional attributes */
  metadata?: AssetMetadata;
}

/** Filters for listing Health Assets */
model AssetFilters {
  /** Filter by substrate type */
  substrate?: SubstrateType[];

  /** Filter by quality class */
  qualityClass?: QualityClass[];

  /** Filter by data type */
  dataType?: DataType[];

  /** Created after this time */
  createdAfter?: Timestamp;

  /** Created before this time */
  createdBefore?: Timestamp;

  /** Maximum results to return */
  @minValue(1)
  @maxValue(1000)
  limit?: int32 = 100;

  /** Offset for pagination */
  @minValue(0)
  offset?: int32 = 0;
}

/** Result of asset verification */
model AssetVerificationResult {
  /** Overall validity */
  valid: boolean;

  /** Content hash matches declared */
  contentHashMatches: boolean;

  /** Referenced consent is active */
  consentActive: boolean;

  /** Provenance chain is intact */
  provenanceIntact: boolean;

  /** Current quality classification */
  qualityClass: QualityClass;

  /** Any verification errors */
  errors: string[];
}

/** Request to create a new Health Asset */
model CreateAssetRequest {
  /** URI to clinical data */
  dataRef: url;

  /** Data format */
  substrate: SubstrateType;

  /** Governing consent */
  consentRef: ConsentID;

  /** Owner patient */
  patientRef: PatientID;

  /** Optional metadata */
  metadata?: AssetMetadata;
}
