# Contracts

Scope's contract set defines the records it exchanges and the operations callers may invoke. Publication produces one immutable manifest, generated from Scope's definitions and pinned by hash by every consumer. Pale needs that published manifest before it can bind Scope; field sketches do not supply a caller contract.

Pale, Reckon and other consumers must use those published contracts rather than reconstructing or completing them from plans, SQL tables or generated code. [Record reference](record-reference.md) keeps the field sketches needed to write the schemas.

## One manifest, generated, is the only inventory

Scope publishes one immutable owner manifest, `scope-owner-contract.v1.json`, generated from the specification's record and operation definitions rather than kept as a hand-written list; the manifest, not any page, decides which records are members and how many there are. Everything lives in one home in Scope's repository: `contracts/schemas/scope/` for the schema sources, `contracts/manifests/` for the manifest, `contracts/fixtures/canonicalization/`, `positive/` and `negative/` for the vectors, and `contracts/generated/README.md` stating that generated projections carry no authority. JSON Schema is canonical; a family that also declares Protobuf keeps it in `protos/` with cross-format equivalence fixtures, and neither Protobuf nor a Dolt table may redefine a wire contract. A changed schema means a new compatible manifest, never a silent regeneration.

The manifest separately declares the exact callable operations, their request contracts and admission variants. Daemon operations and command-line clients are generated from that inventory. A schema's presence or top-level classification creates no command, and transport routes remain adapter details. Publication declares the surface; implementation and qualification establish its availability.

Publication validates zero omissions and duplicates, schema ownership, whether each record is embedded, top-level or internal, exact references and hashes, fixtures, canonicalisation, issuer and verifier roles, and rejection of unknown majors and hash mismatches. Unknown, unpinned, wrong-owner or hash-mismatched records fail before any semantic processing. Scope signs only its own service outputs: source, resource and artifact owners' facts keep their own issuers, and Reckon's bodies stay Reckon-published and are selected by pin, never republished by Scope.

Qualify each consumer's exact manifest and schema pins against the Scope subset it selects. Scope owns manifest membership and fixtures. Each consumer proves its own runtime binding.

Transport never changes authority. The same contract may travel in-process, over a local socket, through the command line or over HTTP. Calls that come through Pale inherit Pale's common wire profile (request binding, canonicalisation, expiry and replay comparators); standalone calls use Scope's own exact grant and admission rules; neither may weaken a comparator because the transport is local.

## Every signed record is canonical JSON, hashed and signed over a domain

Each record Scope signs is canonicalised with RFC 8785 JSON canonicalisation, hashed with SHA-256, and signed over a domain prefix, a zero byte and the digest. The digest omits its own member and the signature, so no record hashes itself. Omitted optional members are absent, never `null`.

| Record | Signing domain | Signed by |
| --- | --- | --- |
| Context requirement | `SCOPE_CONTEXT_REQUIREMENT_V1` | The task's owner |
| Context bundle | `SCOPE_CONTEXT_BUNDLE_V1` | Scope |
| Context use receipt | `SCOPE_CONTEXT_USE_RECEIPT_V1` | Scope |
| Standalone caller grant | `SCOPE_STANDALONE_CALLER_GRANT_V1` | Scope's admission authority |
| Standalone request admission | `SCOPE_STANDALONE_REQUEST_ADMISSION_V1` | The granted caller |
| Authority revocation | `SCOPE_AUTHORITY_REVOCATION_V1` | The subject's issuing authority |
| Authority mutation request and receipt | `SCOPE_AUTHORITY_MUTATION_REQUEST_V1`, `SCOPE_AUTHORITY_MUTATION_RECEIPT_V1` | The operator, then Scope |
| Admission authority root | `SCOPE_ADMISSION_AUTHORITY_ROOT_V1` | Self-signed |
| Resource-owner trust record | `SCOPE_RESOURCE_OWNER_TRUST_RECORD_NEW_V1`, `..._OLD_V1` | The owner's new key, and its old key on rotation |
| Resource-owner recovery policy and proof | `SCOPE_RESOURCE_OWNER_RECOVERY_POLICY_V1`, `SCOPE_RESOURCE_OWNER_RECOVERY_PROOF_V1` | The owner's active key; the recovery signers |
| Import delegation | `SCOPE_SOURCE_SNAPSHOT_IMPORT_DELEGATION_V1` | The resource owner |
| Import admission | `SCOPE_SOURCE_SNAPSHOT_IMPORT_ADMISSION_V1` | The owner, its delegated adapter, or Pale's admission principal |
| Import profile | `SCOPE_SOURCE_SNAPSHOT_IMPORT_PROFILE_V1` | Scope's deployment or operator authority |
| Staging manifest | `SCOPE_SOURCE_SNAPSHOT_STAGING_MANIFEST_V1` | The admitted adapter |
| Import receipt | `SCOPE_SOURCE_SNAPSHOT_IMPORT_RECEIPT_V1` | Scope |
| Import audit-anchor receipt | `SCOPE_SOURCE_IMPORT_AUDIT_ANCHOR_RECEIPT_V1` | Scope |
| Episode open and handoff-bind receipts, deferred sketch | `SCOPE_EPISODE_OPEN_RECEIPT_V1`, `SCOPE_EPISODE_HANDOFF_BIND_RECEIPT_V1` | Scope |
| Episode revision, deferred sketch | `SCOPE_EPISODE_V1` | Scope |

The bundle's digest covers the complete bundle, including its admission binding, decision-evidence reference and hash, source snapshots, omissions, limitations, provenance and validity window. The deferred execution-bound branch also covers the reservation and requirement hashes in its binding. The independent schema omits execution fields. A digest over rendered Markdown or a subset of items does not conform. The visibility policy and provenance graph are referenced together with their immutable hashes, so a later policy at the same logical reference cannot rewrite what a bundle exposed or why. Bundle arrays are bounded owner schemas, never opaque JSON: snapshots sort by owner, namespace, generation and reference; items by reference; source records by reference and version; unresolved requirements by reference; limitations by code and evidence. Every set is duplicate-free, and the element shapes, orders and maximums are part of the schema hash, so an implementation cannot sign one order and normalise to another.

## A signing-authority binding says which mode issued a record

Every bundle, receipt and episode revision Scope signs carries a signing-authority binding inside its canonical digest. In the integrated mode it names the owner record signing authority active at issuance, the exact Scope deployment, the manifest reference and hash, and the schema identity and hash. In the standalone mode it names Scope's own authority root, checkpoint and revocation lineage without inventing a deployment authority. Scope alone holds and uses its private key; Pale verifies but can never sign a Scope record, and being invoked by Pale never changes the mode. Evidence from a resource owner keeps its original issuer and is never re-signed as Scope's truth.

The field sketches refer to Pale's intended integrated binding as `SigningAuthorityBindingV1`; that name does not identify a published contract today. Pale must publish the exact owner signing-authority contract before Scope can pin its schema and digest. Scope cannot manufacture that dependency from these sketches or substitute its standalone signer for an integrated authority.

The standalone signer for Scope's service outputs is separate from its admission root. Its record binds the exact instance, principal, controller and optional relationship scope, the service-output scope, the manifest and the permitted schema identities and hashes, the public key's identity, epoch and hash, issue and expiry, predecessor, rotation and recovery policy, and an immutable revocation frontier, together with the transition kind, admission-root authorisation, fresh proof that the new key is held, and the prior-key or recovery authorisation the transition needs. Its allowlist holds only Scope's service-output schemas and exact pinned external dependencies such as the Dolt adoption receipt; it cannot issue admission, trust, credential or Pale records. Until this signer and its fixtures are published, standalone outputs are blocked rather than signed by the admission root, and the verifier keeps its own generation-one anchor (manifest, schema, authority record and key pin) that the signer record cannot introduce or replace.

## Scope adopts its Dolt store through a signed receipt

Scope must qualify the Dolt release it selects and make its own adoption decision. The proposed provider format has no identified implementation owner or published schema for Scope to pin yet. Scope's manifest must wait for that exact contract; a planning name cannot substitute for it.

Scope owns the deployment descriptor and persistence use profile for `scope-dolt-3309`, its adoption decision and its ledger. In the intended receipt design, Scope's standalone signer signs the first receipt. An integrated successor requires Scope's owner record-signing authority for that deployment, bound through the published Pale authority contract, and a replacement receipt tied to the predecessor. Scope holds the signing key in either mode. Before activation, prove rejection of a wrong packet, deployment, profile or signer, and exercise retirement, supersession, replay and rollback against the single accepted head. Qualification and adoption do not make Pale a Dolt adapter or a writer of Scope's store.

## The record families

| Family | Records | What they are for | Rules |
| --- | --- | --- | --- |
| Resolving and using context | `ContextRequirementV1`, `ResolveRequestV1`, `ContextBundleV1`, `ContextBundleReadRequestV1`, `ContextUseReportV1`, `ContextUseReceiptV1` | The task owner's requirement, the caller's request, Scope's signed answer, reading the bound bytes back, and the use report with its receipt | [Episodes and use](episodes-and-use.md) |
| Importing owner snapshots | `SourceSnapshotImportProfileV1`, `SourceSnapshotStagingManifestV1`, `SourceSnapshotImportV1`, `SourceSnapshotImportReceiptV1`, `ScopeSourceImportAuditAnchorReceiptV1`, `SourceSnapshotImportDelegationV1`, `SourceSnapshotImportAdmissionV1` | Turning an owner's snapshot into exactly one new visible generation | [Source imports](source-imports.md) |
| Execution episodes, deferred | `EpisodeOpenRequestV1`, `EpisodeOpenReceiptV1`, `EpisodeHandoffBindRequestV1`, `EpisodeHandoffBindReceiptV1`, `EpisodeExpiryRequestV1`, `EpisodeV1` are predecessor sketches | Tying a bundle and its use to one run of work and its outcome facts | [Episodes and use](episodes-and-use.md) |
| Admission and trust | `ScopeAdmissionAuthorityRootV1`, `ScopeStandaloneCallerGrantV1`, `ScopeStandaloneRequestAdmissionV1`, `ScopeAuthorityRevocationV1`, `ScopeAuthorityCheckpointV1`, `ScopeAuthorityMutationRequestV1`, `ScopeAuthorityMutationReceiptV1`, `ScopeResourceOwnerTrustRecordV1`, `ScopeResourceOwnerRecoveryPolicyV1`, `ScopeResourceOwnerRecoveryProofV1`, `ScopeStandaloneOwnerSigningAuthorityV1`, `ScopeAuthorityFrontierV1` | Who may call a standalone Scope, whose snapshots it trusts, and the anti-rollback chain | [Admission and trust](admission-and-trust.md) |
| Research export | `ResearchEvidenceExportRequestV1`, `ResearchEvidenceExportV1` | Minimised evidence for an admitted research purpose | [Evidence export and Reckon](evidence-export-and-reckon.md) |
| Retrieval | a retrieval-policy release, a materialization manifest, an activation receipt, retrieval-decision evidence | The released behaviour, the frozen snapshot's identity, its activation, and what each request saw | [Retrieval](retrieval.md) |
| Improvement proposals | proposed; see [Record reference](record-reference.md) | Evidence, proposal and release lineage for Scope's own artifacts | [Improvement and go-live](improvement-and-go-live.md) |

The first independent checkpoint excludes the deferred episode family and the execution-bound branches of resolve, bundle, read, report and receipt. Resolve, exact read, use receipts without an execution binding, and separately admitted research export keep their own publication gates. An independent schema rejects a supplied execution binding rather than accepting it as an optional hint.

The four retrieval records have accepted meanings and no final schema names or bodies yet; they are published once their fields, maximums, compatibility, issuer and verifier roles and unknown-major behaviour are frozen, and Pale may reserve and pin only the published bodies. Before the first public version, the context bundle gains two fields, `retrieval_decision_ref` and `retrieval_decision_sha256`: the bundle carries the reference and digest of its decision evidence, never the candidate set, model features or snapshot bytes. A read or use check resolves the exact decision digest when policy requires and never substitutes a newer decision at the same logical reference.

Three structures stay internal and are never caller-issued or published as top-level records: the durable-state checkpoint, the source-provenance structure embedded in graph nodes, and the migration receipt.

## Who may consume Scope

[Architecture](architecture.md) owns the integrated and standalone routes. Integrated calls supply the common envelope, integrated authority evidence and references to the events and causal record; standalone calls supply Scope's own [grant and signed request](admission-and-trust.md). Every consumer pins the published subset it uses. Credentials remain with their owners.

**Reckon** may receive proposed corpus cases, authorised corpus use, requests for offline scoring comparisons, Scope's edit-lineage projection when both owners select it, and verification of a custodied ruling reference. Reckon never writes Scope's ledger, episodes, scores or releases, and Scope never runs Reckon's code in its hot path. Scope's half of the boundary is on [Evidence export and Reckon](evidence-export-and-reckon.md); Reckon owns its corpus admission, evaluation, custody of decisions and record-store contracts.

**Site exports compiled by Gazette** must be complete, versioned, owner-signed post-build exports supplied by the site owner. Gazette's store and release journal are not Scope's source. [Source imports](source-imports.md) owns the mapping.

**Owner projections** from repositories, Google Workspace, Gas Town and creative work arrive only as owner-issued snapshots through the import contract. Source owners retain the original financial records. Means is the calculation engine beside Pale; each owner's workspace selects permitted sources, grants and Packs and retains the run snapshot, results and run record. Pale Packages supply the reusable methods. Means keeps no store or service of its own for Scope to import. Any projection selected from a retained run still needs its data owner's permission and snapshot contract.

**Weave** reaches Scope only through Pale, for the requests Weave's own work makes; Weave itself never calls Scope. In the other direction Scope reads Weave through Weave's port, with Pale or without it, and without Pale Scope is how an agent reads Weave, as [architecture](architecture.md#scope-sits-on-pale-weave-or-both) explains. What Weave work may ask of Scope through that path remains an open contract question. Weave's own search is not Scope retrieval.

Part of [Scope engineering](README.md).
