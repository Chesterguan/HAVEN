# HAVEN Protocol Test Vectors

**Version**: 2.0.0
**Date**: February 13, 2026

This directory contains test vectors for HAVEN Protocol conformance testing.

## Directory Structure

```
test-vectors/
├── health-asset/
│   ├── valid/           # Assets that MUST be accepted
│   └── invalid/         # Assets that MUST be rejected
├── consent/
│   ├── valid/           # Consents that MUST be accepted
│   └── invalid/         # Consents that MUST be rejected
├── provenance/
│   ├── valid/           # Entries that MUST be accepted
│   └── invalid/         # Entries that MUST be rejected
├── contribution/
│   ├── valid/           # Contributions that MUST be accepted
│   └── invalid/         # Contributions that MUST be rejected
└── exchange-bundle/
    ├── valid/           # Bundles that MUST be accepted
    └── invalid/         # Bundles that MUST be rejected
```

## Usage

### Validation Testing

For each primitive:
1. Load all files from `valid/` directory
2. Parse and validate against the specification
3. **All MUST pass validation**

4. Load all files from `invalid/` directory
5. Parse and validate against the specification
6. **All MUST fail validation** with the expected error

### Content Addressing Testing

For Health Assets in `valid/`:
1. Parse the asset
2. Remove the `asset_id` field
3. Compute the canonical hash using the algorithm in spec/001-health-asset.md
4. Verify the computed hash matches the original `asset_id`

### Chain Integrity Testing

For Provenance entries:
1. Load entries in sequence order
2. Verify `previous_hash` links correctly
3. Verify `entry_hash` is computed correctly
4. Verify signatures are valid

## File Format

All test vectors are JSON files with the following structure:

```json
{
  "_meta": {
    "description": "Test case description",
    "expected_result": "valid" | "invalid",
    "expected_error": "ERROR_CODE (if invalid)",
    "spec_reference": "Section reference in specification"
  },
  "data": {
    // The actual test data
  }
}
```

## Test Case Naming

Files are named with the pattern:
```
<category>-<description>.json
```

Examples:
- `minimal-valid.json` - Minimal valid object
- `full-valid.json` - Full object with all optional fields
- `missing-required-field.json` - Missing a required field
- `invalid-hash-format.json` - Hash doesn't match pattern

## Contributing

When adding test vectors:
1. Include comprehensive `_meta` section
2. Reference the specific spec section
3. For invalid cases, specify the expected error code
4. Test edge cases and boundary conditions
