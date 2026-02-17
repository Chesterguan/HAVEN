/**
 * Exchange Bundle Type Definitions
 *
 * The Exchange Bundle defines a standard format for transferring
 * HAVEN data between systems, enabling interoperability.
 */

import "./common.tsp";
import "./health-asset.tsp";
import "./consent.tsp";
import "./provenance.tsp";
import "./contribution.tsp";

namespace Haven.Models;

// ============================================================================
// Models
// ============================================================================

/** Additional context about the bundle */
model BundleMetadata {
  /** Why this bundle was created */
  purpose?: string;

  /** Originating system identifier */
  sourceSystem?: string;

  /** Intended recipient (if known) */
  destination?: string;

  /** If bundle is for single patient */
  patientRef?: PatientID;

  /** Bundle expiration (optional) */
  expiresAt?: Timestamp;

  /** Classification tags */
  tags?: string[];

  /** Implementation-specific extensions */
  extensions?: Record<unknown>;
}

/** Result of bundle verification */
model BundleVerificationResult {
  /** Overall validity */
  valid: boolean;

  /** Hash matches computed value */
  hashValid: boolean;

  /** Signature is valid */
  signatureValid: boolean;

  /** All assets are valid */
  assetsValid: boolean;

  /** All consents are valid */
  consentsValid: boolean;

  /** Provenance chain is intact */
  provenanceValid: boolean;

  /** Any verification errors */
  errors: string[];
}

/** Options for importing a bundle */
model ImportOptions {
  /** How to handle conflicts */
  conflictResolution?: "REJECT" | "SKIP" | "MERGE";

  /** Whether to verify signatures */
  verifySignatures?: boolean;

  /** Whether to record import in provenance */
  recordProvenance?: boolean;
}

/** Result of bundle import */
model ImportResult {
  /** Whether import succeeded */
  success: boolean;

  /** Number of assets imported */
  assetsImported: int32;

  /** Number of consents imported */
  consentsImported: int32;

  /** Number of provenance entries imported */
  provenanceImported: int32;

  /** Number of contributions imported */
  contributionsImported: int32;

  /** Number of items skipped (due to conflicts) */
  skipped: int32;

  /** Any errors during import */
  errors: string[];

  /** Provenance entry for this import */
  importProvenanceRef?: string;
}

/**
 * Exchange Bundle
 *
 * Standard format for transferring HAVEN data between systems.
 * Includes payload, integrity hash, and cryptographic signature.
 */
@doc("Standard format for transferring HAVEN data between systems")
model ExchangeBundle {
  /** Unique bundle identifier */
  bundleId: UUID;

  /** HAVEN protocol version */
  version: string;

  /** Bundle creation time */
  createdAt: Timestamp;

  /** Who created the bundle */
  createdBy: ActorIdentity;

  // Payload
  /** Health Assets included */
  assets: HealthAsset[];

  /** Related consents */
  consents: ConsentAttestation[];

  /** Provenance entries */
  provenance: ProvenanceEntry[];

  /** Contribution records */
  contributions: Contribution[];

  // Integrity
  /** Hash of payload for integrity verification */
  bundleHash: ContentHash;

  /** Creator's signature over bundle_hash */
  signature: CryptoSignature;

  // Metadata
  /** Optional additional context */
  metadata?: BundleMetadata;
}
