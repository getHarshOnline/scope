# Record reference

Scope's planned records are grouped below by the operations they support. These field sketches are inputs to the future published schemas, not wire formats callers may already use. Each record still needs its exact schema, limits, canonicalisation and signature vectors, and fixtures in the owner manifest. A callable operation also needs membership in that manifest's operation inventory, admission and qualification; publishing a schema creates no command. [Contracts](contracts.md) explains each family's purpose, consumers and mode-specific signing authority; the family pages define its behavior.

Two parts of the declared contract set still lack field sketches here. The standalone service-output signer, `ScopeStandaloneOwnerSigningAuthorityV1`, has its required bindings and lifecycle on [Contracts](contracts.md). The four retrieval records have accepted meanings on [Retrieval](retrieval.md) but no final schema names or bodies. Their completion remains part of [contract publication](contracts.md#one-manifest-generated-is-the-only-inventory); this reference does not make those records callable or fill their missing shapes by implication.

Conventions in every sketch: a field ending in `?` is absent unless its state branch requires it, and `null`, empty strings and sentinel references are invalid; every `*_ref` travels with its `*_sha256`; arrays are bounded, sorted by their schema comparator and free of duplicates; every signed record's canonical digest is SHA-256 over its RFC 8785 canonical form with the digest and signature members omitted.

## Resolving context and recording its use

[Fields and conventions](records/resolving-context-and-recording-its-use.md) for context requirements, resolve requests, signed bundles, exact reads, use reports and receipts.

## Admission, trust and authority

[Fields and conventions](records/admission-trust-and-authority.md) for caller grants, trust and recovery records, revocations, checkpoints and authority mutations.

## Importing an owner snapshot

[Fields and conventions](records/importing-an-owner-snapshot.md) for delegations, import admission, profiles, staged chunks and import receipts.

## Execution episodes

[Fields and conventions](records/execution-episodes.md) for the deferred episode open, handoff binding, expiry and revision records.

## Research exports

[Fields and conventions](records/research-exports.md) for research requests and the minimised evidence Scope returns.

## Improvement proposals

[Fields and conventions](records/improvement-proposals.md) for cycle checkpoints, scoring and memory proposals, releases and equivalence evidence.

Part of [Scope engineering](README.md).
