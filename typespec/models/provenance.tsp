/**
 * Provenance Record Type Definitions
 *
 * The Provenance Record is an append-only audit trail
 * of all governance events in HAVEN.
 */

import "./common.tsp";

namespace Haven.Models;

// ============================================================================
// Enums
// ============================================================================

/** Category of governance event */
enum EventType {
  // Asset events
  /** New Health Asset registered */
  ASSET_CREATED,
  /** Health Asset data retrieved */
  ASSET_ACCESSED,
  /** Health Asset exported to external system */
  ASSET_EXPORTED,
  /** Health Asset removed (soft delete) */
  ASSET_DELETED,
  /** Quality class reassessed */
  ASSET_QUALITY_UPDATED,

  // Consent events
  /** New consent attestation created */
  CONSENT_GRANTED,
  /** Consent checked for access decision */
  CONSENT_VERIFIED,
  /** Patient withdrew consent */
  CONSENT_REVOKED,
  /** Consent reached expiration */
  CONSENT_EXPIRED,
  /** Patient declined consent request */
  CONSENT_REJECTED,

  // Query events
  /** Research query ran against data */
  QUERY_EXECUTED,
  /** Query results released to requester */
  QUERY_RESULT_RELEASED,

  // Compute events
  /** Computation began on patient data */
  COMPUTATION_STARTED,
  /** Computation finished */
  COMPUTATION_COMPLETED,

  // AI events
  /** ML model trained using patient data */
  MODEL_TRAINED,
  /** ML model made prediction using patient data */
  MODEL_INFERENCE,

  // Value events
  /** Patient contribution quantified */
  CONTRIBUTION_RECORDED,
  /** Value distributed to patient */
  COMPENSATION_DISTRIBUTED,

  // Identity events
  /** Patient identity verification event */
  IDENTITY_VERIFIED,
  /** Access delegation created */
  DELEGATION_GRANTED,
  /** Access delegation removed */
  DELEGATION_REVOKED,

  // System events
  /** System-level audit event */
  SYSTEM_AUDIT,
}

/** Type of actor performing an action */
enum ActorType {
  /** Patient themselves */
  PATIENT,

  /** Healthcare provider */
  CLINICIAN,

  /** Research accessor */
  RESEARCHER,

  /** Automated system process */
  SYSTEM,

  /** System administrator */
  ADMINISTRATOR,

  /** Acting on behalf of patient */
  DELEGATE,
}

/** Type of subject affected by event */
enum SubjectType {
  HEALTH_ASSET,
  CONSENT_ATTESTATION,
  PATIENT,
  QUERY,
  COMPUTATION,
  MODEL,
  CONTRIBUTION,
}

// ============================================================================
// Models
// ============================================================================

/** Identity of actor performing an action */
model ActorIdentity {
  /** Actor identifier */
  id: string;

  /** Type of actor */
  type: ActorType;

  /** Human-readable name */
  name?: string;

  /** Delegation chain (if acting on behalf of another) */
  onBehalfOf?: ActorIdentity;
}

/** Reference to subject of an event */
model SubjectRef {
  /** Type of subject */
  type: SubjectType;

  /** Subject identifier */
  id: string;

  /** Related subjects */
  additionalRefs?: string[];
}

/** Node in a Merkle proof */
model ProofNode {
  /** Hash value */
  hash: ContentHash;

  /** Position relative to current node */
  position: "LEFT" | "RIGHT";
}

/** Merkle inclusion proof */
model MerkleProof {
  /** Merkle root at proof time */
  rootHash: ContentHash;

  /** Position of entry's hash in tree */
  @minValue(0)
  leafIndex: int32;

  /** Sibling hashes from leaf to root */
  path: ProofNode[];

  /** Number of leaves when proof generated */
  @minValue(1)
  treeSize: int32;
}

/**
 * Provenance Entry
 *
 * A single entry in the append-only audit trail.
 * Hash-chained to previous entry for integrity.
 */
@doc("Immutable, hash-chained audit trail entry")
model ProvenanceEntry {
  /** Unique entry identifier (prov:<chain>:entry:<seq>) */
  entryId: string;

  /** Provenance chain identifier */
  chainId: UUID;

  /** Zero-indexed position in chain */
  @minValue(0)
  sequence: int32;

  /** When event occurred */
  timestamp: Timestamp;

  /** Category of event */
  eventType: EventType;

  /** Entity that performed the action */
  actor: ActorIdentity;

  /** What was affected */
  subject: SubjectRef;

  /** Event-specific data */
  details: Record<unknown>;

  /** Hash of previous entry (null for genesis) */
  previousHash: ContentHash | null;

  /** Hash of this entry */
  entryHash: ContentHash;

  /** Actor's cryptographic signature */
  signature: CryptoSignature;

  /** Optional Merkle inclusion proof */
  merkleProof?: MerkleProof;
}

/** Result of chain verification */
model ChainVerificationResult {
  /** Overall validity */
  valid: boolean;

  /** Total entries in chain */
  @minValue(0)
  chainLength: int32;

  /** Number of entries verified */
  @minValue(0)
  verifiedEntries: int32;

  /** Current Merkle root */
  merkleRoot: ContentHash;

  /** Any verification errors */
  errors: VerificationError[];
}

/** Verification error details */
model VerificationError {
  /** Entry where error occurred */
  entryId: string;

  /** Error type */
  errorType: string;

  /** Error description */
  message: string;
}

/** Filters for querying provenance */
model ProvenanceFilters {
  /** Filter by event types */
  eventTypes?: EventType[];

  /** Filter by actor ID */
  actorId?: string;

  /** Filter by subject ID */
  subjectId?: string;

  /** Filter by subject type */
  subjectType?: SubjectType;

  /** Events after this time */
  fromTimestamp?: Timestamp;

  /** Events before this time */
  toTimestamp?: Timestamp;

  /** Maximum results */
  @minValue(1)
  @maxValue(1000)
  limit?: int32 = 100;

  /** Pagination offset */
  @minValue(0)
  offset?: int32 = 0;
}

/** Request to append a provenance entry */
model AppendProvenanceRequest {
  /** Chain to append to */
  chainId: UUID;

  /** Event type */
  eventType: EventType;

  /** Actor performing action */
  actor: ActorIdentity;

  /** Subject of event */
  subject: SubjectRef;

  /** Event details */
  details: Record<unknown>;
}
