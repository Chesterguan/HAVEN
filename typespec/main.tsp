/**
 * HAVEN Protocol - Type Definitions
 *
 * Health Asset Value & Exchange Network
 * Version 2.0.0 | January 28, 2026
 *
 * This is the source of truth for HAVEN Protocol types.
 * Generated outputs: JSON Schema, OpenAPI
 */

import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";
import "@typespec/json-schema";

import "./models/common.tsp";
import "./models/health-asset.tsp";
import "./models/consent.tsp";
import "./models/provenance.tsp";
import "./models/contribution.tsp";
import "./models/exchange-bundle.tsp";
import "./operations/haven-api.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using TypeSpec.OpenAPI;

@service({
  title: "HAVEN Protocol API",
  version: "2.0.0",
})
@server("https://api.haven.example.com", "HAVEN API Server")
@doc("HAVEN Protocol - Patient-Sovereign Health Data Infrastructure")
namespace Haven;
