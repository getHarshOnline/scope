# Source imports

A new owner snapshot reaches Scope through a bounded import. The owner reads its source using its own credentials and supplies a secret-free, content-addressed set of chunks. Scope checks admission, verifies the bytes against the signed digests and stages the candidate privately. An accepted new import advances the namespace once. Readers see the new generation and its receipts only after the required commits and anchor advances. The same path serves repository manifests and Gazette site exports.

## Admission comes before parsing

Every import is admitted before its body is parsed, and the caller's intent and the verifier's admission are separate records that never hash each other. The import body's hash is SHA-256 over its exact canonical form. Who may admit it is one of three branches:

| Branch | Who signs the admission | What else must hold |
| --- | --- | --- |
| The resource owner | The owner itself | No delegation or Pale fields; in standalone mode the admission binds the owner's active trust record and the checked authority checkpoint |
| A delegated adapter | The adapter the owner named | The owner-signed delegation is present, active, unexpired, non-transitive, names that adapter and role, and covers every requested owner, namespace, scope and purpose |
| Pale's admission principal | Pale, after validating the caller's request | The same owner-signed delegation naming Pale's admission role, plus the exact accepted deployment binding, capability session grant and caller-signed request; a Pale process identity alone is never the owner's consent |

In a Pale deployment the caller first signs a common request whose body is exactly the import; after validating it and the owner's delegation, Pale's admission principal signs the import admission, binding the request, the deployment and session evidence, the delegation and the same body hash. Scope consumes the immutable triple of request, admission and body through its admitted port, and for a federated call the destination's federation admission as well. No record hashes a future container that hashes it.

Scope resolves every issuer, delegation, deployment binding, session grant, request and federation admission key and hash, and rejects anything unknown, retired, rolled back, revoked, expired, in the wrong role or out of scope. A durable admission journal records the issuer, key epoch and request identifier with the admission's canonical hash; exact replay may return the earlier disposition, and reuse with any different authority, delegation, binding, scope, body hash, times or signature fails closed. Only after canonicalisation, signature and expiry are verified does Scope parse those bytes, and then the body's source owner must equal the permitted owner, its namespace must be one of the permitted namespaces, and its principal, controller and relationship scope must match the admission and the delegation. A caller, path, repository, provider account, deployment or payload can never declare itself the owner or widen a namespace.

## A signed profile sets each deployment's limits

The deployment's operator authority issues a signed import profile for each instance, mode, deployment binding and scope. It must choose positive values no greater than these absolute ceilings, and it must also set numeric budgets for the activation transaction and its p95 and p99 latency on its pinned hardware and content store. Lower limits for a particular owner are normal; crossing any limit rejects the import before anything becomes visible.

| Limit                        | Ceiling                          |
| ---------------------------- | -------------------------------- |
| Chunks per import            | 4,096                            |
| Records per chunk            | 2,048                            |
| Uncompressed bytes per chunk | 8 MiB                            |
| Manifest size                | 4 MiB                            |
| Items per import             | 1,000,000                        |
| Tombstones per import        | 1,000,000                        |
| Total payload                | 8 GiB                            |
| One inline payload           | 64 KiB                           |
| Staging age                  | 24 hours                         |
| Validation wall time         | 30 minutes                       |
| Concurrent staging sessions  | 8 per namespace, 32 per instance |

There is one active profile head per exact tuple of instance, mode, deployment binding and scope, and the selected profile record is itself that head: its reference, canonical hash and epoch are what every manifest, body and receipt pins. Epoch one has no predecessor; each successor increments once, binds its predecessor, and either activates a replacement or retires the head. Standalone profiles bind the exact authority checkpoint and carry no deployment fields; integrated profiles bind the exact Pale deployment. The whole active-head set is rooted in the durable-state checkpoint, so a restored lookup table cannot quietly select another profile. An unknown instance, a stale head, the wrong controller, an expired or retired profile, a checkpoint rollback, or a compiler proposal racing an operator successor fails before any chunk is read; the two compete on one compare-and-swap head.

## The adapter stages content-addressed chunks

The staging manifest is signed by the exact admitted adapter: its instance, version and binding and its acquisition receipt must match the owner's delegation or the integrated admission. It binds the source, scope, mode (`full` or `delta`), requested and expected generations, the checked profile head, and the ordered list of chunks with their kind, first and last source record, record count, byte size, schema and content hash. A mutable profile, an unsigned manifest, the wrong adapter, a stale binding or an unverified acquisition receipt fails before any chunk is read.

Check required coverage and freshness for each owner scope, partition and task. Trace the source position acquisition covered through staging and activation to the exact generation Scope's readers can use; inspect that visible generation separately from the import acknowledgement. The latest source event, acquisition position, stage completion time and readable generation answer different questions. One partition's highest checkpoint cannot establish coverage for another. Keep missing, incomplete, stale and unknown data distinct from a verified empty result. A no-change result establishes freshness only for the window and scope acquisition actually checked. Test a quiet source, recent rows with incomplete coverage, a missing partition, successful processing of an old input and a reader still serving the predecessor. The adapter supplies the exact acquisition receipt. The imported records retain their source observation and validity coordinates.

Each chunk is an immutable canonical array of exactly one kind of record:

```text
item {
  source_record_ref, source_version,
  record_schema_id, record_schema_sha256,
  content_digest,
  inline_payload? | immutable_content_ref?      # exactly one
  classification, authority_class, lifecycle_state,
  provenance_evidence[] { provenance_ref, provenance_sha256 },
  observed_at, valid_through
}

tombstone {
  source_record_ref, source_version,
  tombstone_kind                                # explicit | policy_omission
  deletion_or_absence_reason,
  authority_reference, authority_reference_sha256,
  complete_set_policy_ref?, complete_set_policy_sha256?,
  first_absent_generation?, current_absent_generation?,
  absence_evidence_ref?, grace_evidence_ref?, reconciliation_evidence_ref?  # each with its hash
  observed_at
}
```

Chunk indices run contiguously from zero; manifest entries sort by kind, first record and index; ranges never overlap; and the concatenated records are globally sorted and unique by source record, with no key appearing as both an item and a tombstone. Each item names its record schema and carries exactly one bounded inline payload or an admitted immutable content reference whose bytes match its digest; a mutable path or URL is not enough.

## Two digests bind the whole snapshot

The manifest digest is the staging manifest's own canonical hash. The snapshot digest is SHA-256 over the canonical object `{digest_profile: "scope.source-snapshot.v2", manifest_digest, ordered_chunk_content_hashes}`, where the array lists each chunk's index, kind and content hash exactly as the manifest does, and each chunk's hash covers every record field and representation. Cross-language vectors cover empty, single and many chunks, full and delta imports, tombstones, inline and referenced content, and the negatives: wrong order, overlapping ranges, count or byte drift, `null`, self-inclusion, stale staging and changed content.

## Generations advance one at a time

To activate a new import, generation one requires an empty namespace and no expected predecessor. Every successor must request exactly the previous generation plus one and name that previous generation. Skipped, reused, stale, zero or ambiguous generations conflict on that path. Staging is content-addressed and idempotent: hash validation may run in parallel outside the single writer, each chunk is installed with create-or-verify semantics, and the writer records chunks in bounded transactions under a candidate generation nobody can see. Abandoned staging is deleted only after the profile's age, with no active import lease, against an exact inventory of the manifest and chunks, with an immutable cleanup receipt; a referenced or active chunk is never swept by age alone.

## Activation is short, ordered and anchored

Imports never hold one long SQL transaction. The sequence is:

1. Install and verify the immutable chunks under the signed profile.
2. Validate the complete staging manifest and the candidate semantic root while the previous generation stays visible.
3. Take the namespace's generation head and Scope's writer fence.
4. In one short transaction, compare and swap the expected generation, install the validated root and persist the signed import receipt, the `sql_activated` journal entry, the gated receipt outbox and the first durable-state checkpoint covering the new frontiers.
5. With every receipt and the new generation still hidden and admission still gated, advance the anti-rollback anchor to that checkpoint.
6. Create and verify the exact Dolt commit.
7. Sign the audit-anchor receipt over that commit and semantic root. Persist it and its successor checkpoint together, then create and verify the Dolt commit containing them. Advance the independent anchor to the successor checkpoint.
8. Verify the two advances in order before revealing the receipt pair or new generation and reopening admission.

The SQL commit and the Dolt commit are separate durable boundaries and are never described as one atomic operation. The append-only journal moves through `prepared`, `chunks_staged`, `manifest_validated`, `sql_activated`, `dolt_anchored`, `anchor_receipt_committed` and `receipt_visible`, with terminal `rejected`, `conflict` or `abandoned` branches only where their rules allow. Restart resumes exactly:

| Last durable state | What restart does |
| --- | --- |
| `prepared` or `chunks_staged` | Verify the immutable chunks and continue, or abandon under the cleanup policy; the previous generation stays visible |
| `manifest_validated` | Recheck the generation head and run the one activation compare-and-swap; a stale head conflicts |
| `sql_activated` | Keep admission closed. Verify the stored semantic root, receipt bytes and first checkpoint. Complete or read back that exact anchor advance before creating or verifying the first Dolt commit. |
| `dolt_anchored` | Verify the first advance and its Dolt commit. Use the stored identifiers, times, root and commit to recover the exact audit-anchor receipt and successor checkpoint. |
| `anchor_receipt_committed` | Verify the stored audit-anchor receipt, its successor checkpoint and their Dolt commit. Complete or read back the second anchor advance before exposing the generation and receipt pair. |
| `receipt_visible` | Exact replay returns the original receipt pair |
| Changed bytes, an impossible jump, a wrong commit or root, a competing head | Quarantine and fail closed; never synthesise success |

A lost anchor acknowledgement is reconciled against the exact checkpoint reference and hash. The expected predecessor permits the pending advance. The exact successor confirms it already happened. A conflicting pair goes to recovery under [Durability and recovery](durability-and-recovery.md). A staged import leaves the previous generation queryable until the activation swap. After that swap, admission stays closed while the journal finishes. Performance fixtures measure validation and ingestion separately from activation, at p50, p95 and p99, across contention, independent namespaces, staging ceilings and each crash boundary.

Apply the exact commit recovery procedure to each Dolt commit and its Scope checkpoint. Independent namespaces can share a physical table, and the branch can contain staged changes from other tables. The writer fence must protect the checkpoint's full change set while it is staged and through the commit. Bind that set and its expected predecessor before committing. Read back the pinned commit and verify its changes against the checkpoint before opening admission. A mismatch keeps admission closed. Exercise the [import commit scope fixture](acceptance-tests.md).

If the commit reply is lost before the hash is recorded, identify the candidate in the branch history using the checkpoint's expected parent and change set. A unique exact match permits only the outstanding recovery step, under its own guards. If history is ambiguous or the candidate cannot be established, keep admission closed and apply the original recovery guards before any retry.

## Omission never deletes

Apply the snapshot admission method to the owner's coverage and removal evidence. Scope applies exactly the manifest-bound items and authorised tombstones at the activation swap. Omitted records keep their disposition. A delta requires a source contract that defines ordered delta semantics.

Only the site export can submit policy-derived removals, through its own separately versioned, owner-signed policy and policy-head types. A new source must publish its own policy, head schema, adapter and fixtures. When a policy is present all three head fields are required. The signer must be the resource owner, the policy must cover the import, and the signed head must be the selected, non-rolled-back active head for the same scope. Recheck that head at activation, under the same guard that protects the generation swap, and retain its reference, hash and epoch in the receipt. Every `policy_omission` tombstone must be inside a tombstone chunk bound by the manifest and both digests. It carries the policy, absence, grace and reconciliation fields, and its authority reference resolves the deterministic tombstone contract. An `explicit` tombstone omits those fields.

## Every disposition gets exactly one receipt pair

Apply the command replay procedure after Scope’s admission and scope checks. Scope resolves the original admission and the import’s semantic identity before checking the generation for a new activation.

1. An exact replay of an admission and request returns its original visible receipt and audit-anchor receipt, even after the head advances. If the disposition is still pending, recover it through the journal. The replay never creates a second pair or starts a second activation. Changed reuse of an admission identity fails closed.
2. For a new admission, the semantic uniqueness key is the source owner, namespace, principal, controller and relationship scope, mode, requested and expected generations, profile hash, staging manifest hash, manifest digest and snapshot digest. Reusing an import identifier or that key with a changed body conflicts. An exact semantic match to an import with a visible committed receipt pair produces a `duplicate` pair under the new admission, referencing both original receipts, even if the head has since advanced. A pending match remains subject to the original import's visibility gate.
3. A request that still needs a new activation conflicts if its expected generation is stale. Compare and swap the head under the writer fence before installing a new generation.

A committed receipt carries the profile and manifest references and hashes, both digests, the chunk and byte totals, the committed generation, the accepted counts and the commit time. A duplicate echoes those original fields. Its top-level admission fields bind the new admission, whose disposition is journaled and anchored without applying any items or tombstones or advancing the generation. Conflict and rejection receipts carry no committed generation, zero accepted counts and a bounded reason. The receipt's evidence depends on the branch: an owner admission forbids delegation and Pale hashes; a delegated admission requires the delegation's reference and hash; a Pale admission requires the delegation plus the deployment binding, session grant and caller request, and the federation admission when federated. Every terminal receipt needs its audit-anchor receipt before it is complete, and the anchor names a generation only when the import committed or duplicated one.

## Each source reaches Scope through its owner

**Repositories.** The repository owner's process produces a pinned manifest or event projection: identity, declared remotes, branch roles, ahead-behind counts and owner-reported worktrees at an observation time. Scope never discovers credentials through `gh auth status` or runs `git` or `gh`. The resulting tables are on [Resources and locations](resources-and-locations.md).

**Google Workspace.** Where an owner uses the `gws` command-line tool, its own admitted helper selects the owner-managed configuration, performs the read and produces a bounded, versioned, secret-free export or event projection: email threads and Drive documents as references with source versions, classification, provenance and freshness. Account selection and credentials stay inside that helper's process, and any account isolation it uses is applied and tested there. Scope stores the projection, provenance and any opaque route needed to read freshness; it never selects an account, switches global authentication, exports that environment or calls `gws`. Weave holds export-production schedules, and away-work follows Weave → Pale → execution. The owner retains source credentials, export ownership and authority for admitted manual exports; Scope has no provider polling loop. Scope commits each accepted derived revision with its own outbox entry. Owner publications qualify separately for [Pale's direct route](architecture.md#three-paths-touch-scope-and-none-stands-in-for-another).

**Means runs.** Means reads owner-supplied facts under the grants declared by the owner's workspace. That workspace retains the owner's run snapshot, results and run record; Means keeps no store or service of its own. An owner may select a retained run reference or projection for Scope's snapshot contract, keeping immutable references to the original legal, corporate, banking, ledger and filing records. A Means result does not replace those original authorities. The adapter must map the selected projection into Scope's snapshot contract and preserve the run's identity and source references. Scope resolves only the admitted reference or projection and never changes the source records or saved calculation. Retained inputs stay within their owners' access and retention limits; a correction creates a later run, and a retained result needs current permission before new use.

**Weave.** Weave's changing organisational state reaches Scope through Pale by the [changing-source path](architecture.md#three-paths-touch-scope-and-none-stands-in-for-another), with Weave's own helper keeping its credentials and admission. It is never a direct Weave-to-Scope integration. That holds for what Weave's own work sends: Weave itself never calls Scope. In the other direction Scope reads Weave through Weave's port, with Pale or without it; without Pale, Scope is how an agent reads Weave, as [Architecture](architecture.md#scope-sits-on-pale-weave-or-both) explains. The separate question of what Weave work may ask Scope to retrieve remains on [Contracts](contracts.md#who-may-consume-scope).

**Gas Town.** Gas Town may export bounded execution-history snapshots or event references. Its owner's helper reads back native records through `gt` or `bd` as needed. Scope receives the bounded projection under its own admission contract.

**Creative work.** Once the creative owners publish an export contract, an adapter admits only an owner-issued classified manifest, native run and review receipts, and explicitly approved asset reference and hash pairs; raw prompts, asset bytes, provider credentials, mutable workflow state and whole-workspace crawls are rejected.

**Research knowledge and history.** Current accepted findings belong to the readable owner pages; necessary original research and ruling evidence stays with its owner. Weave's Radar manages research directions and findings; Scope consumes only the export the owner selects, not a registry assumed to be a live resolver. The adapter defaults to current accepted owner knowledge and includes proposals or historical records only on an explicit bounded request. It preserves source, decision, version and historical/proposal status, never sweeps across subjects, returns unresolved conflicts rather than merging them, enforces confidentiality, and never promotes a finding, applies a ruling or changes a policy or model. A market-context bundle may carry source identities, the owner's accepted policy and worldview references, references to retained Means runs, or explicitly requested candidate-review context, never holdings in an unbounded prompt and never an allocation or trade instruction. Reading an old accepted-state projection does not establish that it is today's authority.

## The site export arrives through Pale, never from Gazette directly

In Scope's design the import consumes a complete, versioned, content-addressed post-build export under Gazette's artifact and signing contract. When the import is selected, Pale invokes Scope with the owner's delegation, its common request and the separate import admission bound to the body hash. Scope applies admitted records to its own `website_*` tables in the store at port 3309. The kernel is an empty library today, so the website module has yet to be written. Scope's input is the export, with no access to Gazette's build, SQLite store or release journal. The publisher's release policy governs approval to publish.

The complete export must validate against its exact schema before the generation swap. Staged chunks remain private while that validation runs. Every owner key, relation key, source reference and hash, generation, visibility and deletion marker is preserved. Nodes and edges come only from owner-declared records or an owner-signed deterministic transformation; unknown or ambiguous members fail admission, and Scope never repairs them by matching paths, URLs, domains, names, handles or email addresses. Author projections stay source-qualified. Build caches and rendering artifacts are excluded unless the manifest admits them, and a generated rendering such as `graph.json` or JSON-LD never fills a missing record. Every derived item binds the admitted adapter contract, owner, snapshot, generation and exact source record. Fixtures cover canonical and aliased content, index pages, nested content, wrong or missing keys, ambiguous relations, scope denial, stale or revoked generations and deletion propagation.

A publication agent asking about a research site gets bounded publication context from owner-declared records, with exact provenance, omissions, freshness and visibility limits. A technical agent resolving a private client project does not reach site nodes at all when no admitted edge connects them; private nodes never become reachable from public ones merely because a relationship exists outside the graph, and the publisher's rules can still forbid traversal or export. Reachability is necessary, never sufficient, for publication. Site content is never physically deleted by ranking, the hop budget, scoring, owner-published property filters and a per-source budget bound what one response carries, and content hints stay disabled until the export schema or a signed transformation defines them. Scope's `website_export_generation` means the last site generation Scope committed; making an export does not advance it, a failed import leaves the previous generation intact, and a task that required the rejected generation fails. Import and rebuild are benchmarked against the export fixture before promotion.

Part of [Scope engineering](README.md).
