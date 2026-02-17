/**
 * Common types used across HAVEN Protocol
 */

namespace Haven.Models;

// ============================================================================
// Scalar Types
// ============================================================================

/** SHA-256 content hash with 'sha256:' prefix */
@pattern("^sha256:[a-f0-9]{64}$")
scalar ContentHash extends string;

/** UUID v4 identifier */
@pattern("^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$")
scalar UUID extends string;

/** ISO 8601 timestamp in UTC */
scalar Timestamp extends utcDateTime;

/** Consent reference with 'consent:' prefix */
@pattern("^consent:[a-f0-9-]{36}$")
scalar ConsentID extends string;

/** Provenance reference with 'prov:' prefix */
@pattern("^prov:[a-zA-Z0-9]+:.*$")
scalar ProvenanceID extends string;

/** Patient reference with 'patient:' prefix */
@pattern("^patient:.+$")
scalar PatientID extends string;

/** Contribution reference with 'contrib:' prefix */
@pattern("^contrib:[a-f0-9-]{36}$")
scalar ContributionID extends string;

/** PSDL policy reference */
@pattern("^psdl:.+:.+:.+$")
scalar PolicyReference extends string;

// ============================================================================
// Cryptographic Types
// ============================================================================

/** Supported signature algorithms */
enum SignatureAlgorithm {
  /** EdDSA with Curve25519 (recommended) */
  ED25519,

  /** ECDSA with P-256 */
  ES256,

  /** ECDSA with P-384 */
  ES384,

  /** RSA with SHA-256 (legacy) */
  RS256,
}

/** Cryptographic signature */
model CryptoSignature {
  /** Signature algorithm used */
  algorithm: SignatureAlgorithm;

  /** Reference to the public key */
  @doc("Key identifier (e.g., did:haven:alice#key-1)")
  publicKeyId: string;

  /** Base64url-encoded signature value */
  value: string;

  /** When the signature was created */
  signedAt: Timestamp;
}

// ============================================================================
// Identity Types
// ============================================================================

/** Type of identity identifier */
enum IdentityType {
  /** HAVEN-assigned identifier */
  HAVEN_ID,

  /** Decentralized identifier */
  DID,

  /** FHIR Patient resource ID */
  FHIR_ID,

  /** External system identifier */
  EXTERNAL,
}

/** Level of identity verification */
enum VerificationLevel {
  /** Identity claimed by user */
  SELF_ASSERTED,

  /** Identity verified by trusted party */
  VERIFIED,

  /** Strong authentication performed */
  AUTHENTICATED,
}

/** Patient identity information */
model PatientIdentity {
  /** Patient identifier */
  id: PatientID;

  /** Type of identifier */
  type: IdentityType;

  /** Verification level */
  verification?: VerificationLevel;
}

/** Type of accessor entity */
enum AccessorType {
  /** Academic/industry researcher */
  RESEARCHER,

  /** Healthcare provider */
  CLINICIAN,

  /** Healthcare organization */
  INSTITUTION,

  /** Clinical study/trial */
  STUDY,

  /** Software application */
  APPLICATION,

  /** Machine learning model */
  AI_MODEL,

  /** Public health authority */
  PUBLIC_HEALTH,
}

/** Verified credential */
model Credential {
  /** Credential type (e.g., IRB_APPROVAL) */
  type: string;

  /** Credential identifier */
  id: string;

  /** Credential issuer */
  issuer: string;
}

/** Accessor identity information */
model AccessorIdentity {
  /** Accessor identifier */
  id: string;

  /** Type of accessor */
  type: AccessorType;

  /** Human-readable name */
  name: string;

  /** Organization affiliation */
  organization?: string;

  /** Verified credentials */
  credentials?: Credential[];
}

// ============================================================================
// Time Types
// ============================================================================

/** Time range for data scoping */
model TimeRange {
  /** Inclusive start time (null = no lower bound) */
  start: Timestamp | null;

  /** Inclusive end time (null = ongoing) */
  end: Timestamp | null;
}

// ============================================================================
// Error Types
// ============================================================================

/** Standard error response */
model ErrorResponse {
  /** Error code */
  code: string;

  /** Human-readable error message */
  message: string;

  /** Additional error details */
  details?: Record<unknown>;
}
