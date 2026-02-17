/**
 * HAVEN Protocol API Operations
 *
 * RESTful API definitions for HAVEN Protocol primitives.
 */

import "@typespec/http";
import "@typespec/rest";
import "../models/common.tsp";
import "../models/health-asset.tsp";
import "../models/consent.tsp";
import "../models/provenance.tsp";
import "../models/contribution.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;

namespace Haven.Api;

// ============================================================================
// Health Asset Operations
// ============================================================================

@tag("Health Assets")
@route("/assets")
interface HealthAssets {
  /**
   * Create a new Health Asset
   *
   * Creates a governed reference to clinical data.
   * Performs quality assessment and records provenance.
   */
  @post
  @doc("Create a new Health Asset")
  create(@body request: Haven.Models.CreateAssetRequest):
    | {
        @statusCode statusCode: 201;
        @body asset: Haven.Models.HealthAsset;
      }
    | {
        @statusCode statusCode: 400;
        @body error: Haven.Models.ErrorResponse;
      }
    | {
        @statusCode statusCode: 403;
        @body error: Haven.Models.ErrorResponse;
      };

  /**
   * Get a Health Asset by ID
   *
   * Retrieves asset details. Requires active consent.
   */
  @get
  @route("/{assetId}")
  @doc("Get a Health Asset by ID")
  get(@path assetId: Haven.Models.ContentHash):
    | {
        @statusCode statusCode: 200;
        @body asset: Haven.Models.HealthAsset;
      }
    | {
        @statusCode statusCode: 403;
        @body error: Haven.Models.ErrorResponse;
      }
    | {
        @statusCode statusCode: 404;
        @body error: Haven.Models.ErrorResponse;
      };

  /**
   * Verify Health Asset integrity
   *
   * Checks content hash, consent status, and provenance.
   */
  @post
  @route("/{assetId}/verify")
  @doc("Verify Health Asset integrity and consent status")
  verify(@path assetId: Haven.Models.ContentHash): {
    @statusCode statusCode: 200;
    @body result: Haven.Models.AssetVerificationResult;
  };

  /**
   * List Health Assets for a patient
   */
  @get
  @doc("List Health Assets for a patient")
  list(
    @query patientId: Haven.Models.PatientID,
    @query substrate?: Haven.Models.SubstrateType,
    @query qualityClass?: Haven.Models.QualityClass,
    @query limit?: int32,
    @query offset?: int32,
  ): {
    @statusCode statusCode: 200;
    @body assets: Haven.Models.HealthAsset[];
  };
}

// ============================================================================
// Consent Operations
// ============================================================================

@tag("Consent")
@route("/consents")
interface Consents {
  /**
   * Grant new consent
   *
   * Creates a signed consent attestation.
   */
  @post
  @doc("Grant new consent")
  grant(@body request: Haven.Models.GrantConsentRequest):
    | {
        @statusCode statusCode: 201;
        @body consent: Haven.Models.ConsentAttestation;
      }
    | {
        @statusCode statusCode: 400;
        @body error: Haven.Models.ErrorResponse;
      }
    | {
        @statusCode statusCode: 403;
        @body error: Haven.Models.ErrorResponse;
      };

  /**
   * Get a consent by ID
   */
  @get
  @route("/{consentId}")
  @doc("Get a consent by ID")
  get(@path consentId: Haven.Models.UUID):
    | {
        @statusCode statusCode: 200;
        @body consent: Haven.Models.ConsentAttestation;
      }
    | {
        @statusCode statusCode: 404;
        @body error: Haven.Models.ErrorResponse;
      };

  /**
   * Verify consent for access
   *
   * Checks if access is authorized under a consent.
   */
  @post
  @route("/verify")
  @doc("Verify consent for data access")
  verify(@body request: Haven.Models.VerifyConsentRequest): {
    @statusCode statusCode: 200;
    @body result: Haven.Models.ConsentVerificationResult;
  };

  /**
   * Revoke consent
   *
   * Immediately withdraws consent. All subsequent
   * verifications will return denied.
   */
  @post
  @route("/{consentId}/revoke")
  @doc("Revoke consent (immediate effect)")
  revoke(@path consentId: Haven.Models.UUID, @query reason?: string):
    | {
        @statusCode statusCode: 200;
        @body result: Haven.Models.RevokeResult;
      }
    | {
        @statusCode statusCode: 403;
        @body error: Haven.Models.ErrorResponse;
      }
    | {
        @statusCode statusCode: 404;
        @body error: Haven.Models.ErrorResponse;
      };

  /**
   * List consents for a patient
   */
  @get
  @doc("List consents for a patient")
  list(
    @query patientId: Haven.Models.PatientID,
    @query status?: Haven.Models.ConsentStatus,
    @query includeExpired?: boolean,
    @query limit?: int32,
    @query offset?: int32,
  ): {
    @statusCode statusCode: 200;
    @body consents: Haven.Models.ConsentAttestation[];
  };
}

// ============================================================================
// Provenance Operations
// ============================================================================

@tag("Provenance")
@route("/provenance")
interface Provenance {
  /**
   * Append a provenance entry
   *
   * Adds a new entry to the hash-chained audit trail.
   */
  @post
  @route("/chains/{chainId}/entries")
  @doc("Append a provenance entry to a chain")
  append(
    @path chainId: Haven.Models.UUID,
    @body request: Haven.Models.AppendProvenanceRequest,
  ):
    | {
        @statusCode statusCode: 201;
        @body entry: Haven.Models.ProvenanceEntry;
      }
    | {
        @statusCode statusCode: 400;
        @body error: Haven.Models.ErrorResponse;
      };

  /**
   * Get a provenance entry by ID
   */
  @get
  @route("/entries/{entryId}")
  @doc("Get a provenance entry by ID")
  getEntry(@path entryId: string):
    | {
        @statusCode statusCode: 200;
        @body entry: Haven.Models.ProvenanceEntry;
      }
    | {
        @statusCode statusCode: 404;
        @body error: Haven.Models.ErrorResponse;
      };

  /**
   * Get entries from a chain
   */
  @get
  @route("/chains/{chainId}/entries")
  @doc("Get entries from a provenance chain")
  getChain(
    @path chainId: Haven.Models.UUID,
    @query fromSequence?: int32,
    @query toSequence?: int32,
    @query includeProofs?: boolean,
    @query limit?: int32,
  ): {
    @statusCode statusCode: 200;
    @body entries: Haven.Models.ProvenanceEntry[];
  };

  /**
   * Query provenance entries
   */
  @get
  @route("/chains/{chainId}/query")
  @doc("Query provenance entries with filters")
  query(
    @path chainId: Haven.Models.UUID,
    @query eventTypes?: Haven.Models.EventType[],
    @query actorId?: string,
    @query subjectId?: string,
    @query fromTimestamp?: utcDateTime,
    @query toTimestamp?: utcDateTime,
    @query limit?: int32,
    @query offset?: int32,
  ): {
    @statusCode statusCode: 200;
    @body entries: Haven.Models.ProvenanceEntry[];
  };

  /**
   * Verify chain integrity
   */
  @post
  @route("/chains/{chainId}/verify")
  @doc("Verify provenance chain integrity")
  verifyChain(
    @path chainId: Haven.Models.UUID,
    @query fullChain?: boolean,
  ): {
    @statusCode statusCode: 200;
    @body result: Haven.Models.ChainVerificationResult;
  };

  /**
   * Get Merkle proof for an entry
   */
  @get
  @route("/entries/{entryId}/proof")
  @doc("Get Merkle proof for a provenance entry")
  getMerkleProof(@path entryId: string):
    | {
        @statusCode statusCode: 200;
        @body proof: Haven.Models.MerkleProof;
      }
    | {
        @statusCode statusCode: 404;
        @body error: Haven.Models.ErrorResponse;
      };
}

// ============================================================================
// Contribution Operations
// ============================================================================

@tag("Contributions")
@route("/contributions")
interface Contributions {
  /**
   * Record a contribution
   *
   * Records patient data contribution for a usage context.
   * Performs quality assessment and calculates value.
   */
  @post
  @doc("Record a patient data contribution")
  record(@body request: Haven.Models.RecordContributionRequest):
    | {
        @statusCode statusCode: 201;
        @body contribution: Haven.Models.Contribution;
      }
    | {
        @statusCode statusCode: 400;
        @body error: Haven.Models.ErrorResponse;
      }
    | {
        @statusCode statusCode: 403;
        @body error: Haven.Models.ErrorResponse;
      };

  /**
   * Calculate contribution value (preview)
   *
   * Calculates contribution without recording.
   */
  @post
  @route("/calculate")
  @doc("Calculate contribution value without recording")
  calculate(@body request: Haven.Models.CalculateContributionRequest): {
    @statusCode statusCode: 200;
    @body preview: Haven.Models.ContributionPreview;
  };

  /**
   * Get a contribution by ID
   */
  @get
  @route("/{contributionId}")
  @doc("Get a contribution by ID")
  get(@path contributionId: Haven.Models.ContributionID):
    | {
        @statusCode statusCode: 200;
        @body contribution: Haven.Models.Contribution;
      }
    | {
        @statusCode statusCode: 404;
        @body error: Haven.Models.ErrorResponse;
      };

  /**
   * Query contributions for a patient
   */
  @get
  @doc("Query contributions for a patient")
  query(
    @query patientId: Haven.Models.PatientID,
    @query contextTypes?: Haven.Models.ContextType[],
    @query fromDate?: utcDateTime,
    @query toDate?: utcDateTime,
    @query minValue?: float32,
    @query limit?: int32,
    @query offset?: int32,
  ): {
    @statusCode statusCode: 200;
    @body contributions: Haven.Models.Contribution[];
  };

  /**
   * Get contribution summary
   *
   * Aggregates contributions for reporting.
   */
  @get
  @route("/summary")
  @doc("Get aggregated contribution summary")
  getSummary(
    @query patientId: Haven.Models.PatientID,
    @query periodStart: utcDateTime,
    @query periodEnd: utcDateTime,
  ): {
    @statusCode statusCode: 200;
    @body summary: Haven.Models.ContributionSummary;
  };
}
