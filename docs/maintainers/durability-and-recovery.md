# Durability and recovery

Scope's recovery design starts from the state it has durably accepted. The in-memory graph, frozen snapshots, indexes and diagnostic stream are copies that can be rebuilt. Recovery trusts the accepted head in Dolt together with a small anchor kept outside the database's failure and restore domain. Changes must commit before they become visible, every write must prove that its writer still holds the current lease, and each import becomes visible in one step. A restored backup must not quietly undo a revocation or deletion.

## Accept first, then project

A SQL statement, an owner transaction, a staged import generation, a head compare-and-swap, a Dolt audit anchor and an externally visible receipt are different events, and none stands in for another. An ordinary semantic change commits its complete transaction before the in-memory graph moves. An import first stages and verifies its whole content-addressed generation, then advances the accepted head in one step under the import journal and anti-rollback rules. Rows being written make nothing visible. Only the accepted durable frontier hydrates the graph.

| Where the crash happens | What recovery sees |
| --- | --- |
| Before the transaction or the head swap | No new accepted context is visible |
| After staging or row writes, before acceptance | The incomplete generation is resumed or quarantined; the old head stays live |
| After acceptance, before the graph updated | Startup rebuilds the graph from the accepted frontier |
| After both | Graph and frontier already agree |

Retrieval snapshots follow the same order after the semantic head exists. Seal the inputs, build and validate off-path, then verify owner release and compatibility before the active head and fence advance together. New requests pin the successor. Old readers drain subject to the [disclosure check](retrieval.md#freshness-is-checked-at-request-time). Rollback forward-activates an eligible retained snapshot under a later fence and leaves the shared store at its current frontier. Decision evidence is durable. Indexes, affinity and caches are rebuildable projections.

## Dolt's boundaries must be proved, not assumed

Statement completion, transaction commit, a working-set change, `DOLT_COMMIT`, a ref update and replication are different durability events, and no assumption about how Dolt journals or flushes to disk counts as a guarantee. For each pinned Dolt version, integration tests kill the server or process before and after every durable boundary and check the accepted state, the semantic revision, the inbox and outbox records and the rebuild result. Qualification binds the exact source, built runtime, configuration, Scope store and Dolt profile; its release plan names compatible versions, migration order, readiness, stop conditions, the operator and recovery for in-flight or partially written state. Read back the selected deployment before widening use. Scope fixes its transaction and commit boundaries only after the tests show the required recovery behaviour and the owner records [adoption](contracts.md#scope-adopts-its-dolt-store-through-a-signed-receipt).

## Three identities are easily confused and never merged

The **writer fence** is a controller-scoped lease that every mutation carries, so a stale writer fails even while its process is alive:

```sql
BEGIN;
SELECT generation FROM scope_writer_lease WHERE controller_scope = ? FOR UPDATE;
UPDATE scope_writer_lease
   SET generation = generation + 1, owner_instance_id = ?, lease_expires_at = ?
 WHERE controller_scope = ? AND generation = ?;
COMMIT;
```

Every mutation carries the acquired generation, the caller's admission evidence, the expected revision or head, a stable idempotency identity and the conflict domain it affects. Independent conflict domains may commit concurrently. Mutations competing for the same authority, classification, provenance, lifecycle, replacement or deletion state either compare-and-swap or create an explicit conflict or proposal record; last write wins and blind retries are forbidden, and a retry of a SQL lock error may not replay a changed or no-longer-authorised operation. Agents never write Scope's tables; Dolt's multi-version concurrency is a storage primitive, not admission, idempotency or conflict resolution. A pidfile only prevents an accidental duplicate start.

The **snapshot counter** in `_daemon_meta` makes accepted offline maintenance visible so that the daemon rebuilds before serving dependent context:

```sql
CREATE TABLE _daemon_meta (
    `key`  VARCHAR(64) PRIMARY KEY,
    value  VARCHAR(255) NOT NULL
);
INSERT INTO _daemon_meta VALUES ('generation', '0');
```

The daemon reads the counter at startup; normal mutations co-commit the next value with their transaction; an offline maintenance command requires a stopped daemon, takes the same fence and co-commits its bump; the daemon compares the durable value at admitted read boundaries and after reload notices, and rebuilds if it changed. No command or library offers an unfenced direct write, and the cost of the check is measured under contention, cold and warm caches, recovery and failure. An operator-only reload operation, `ReloadProjection(expected_generation)`, verifies the durable frontier, rebuilds the graph and returns the generation, the visible node and edge counts and the rebuild time; it is never a browser capability.

The **snapshot content identity** of a retrieval snapshot binds the semantic head, released policy, permission, revocation and freshness coordinates and exact build inputs, and has its own activation fence. None of these three is Pale's compiled generation, a source revision or a causal frontier; changing `_daemon_meta`, receiving a watcher wake or building component bytes activates nothing.

| Writer | What it writes | Where | When |
| --- | --- | --- | --- |
| The daemon | Semantic ledger, source snapshots, scores, the owner-event inbox, use receipts, episodes, Scope's publication records | Scope's store on 3309 | Normal operation, under the fence |
| `scope migrate` | Schema migrations and the co-committed counter bump | 3309 | Only with the daemon stopped and the same fence held |
| `scope seed` | Synthetic clean-room fixtures and bootstrap metadata only | 3309 | Test and bootstrap, under the fence |
| Gas Town | Its own execution and audit records | Its own store | Scope receives only a bounded [owner projection](source-imports.md) |

## An anchor outside the backup domain stops rollback

Restoring an old backup must never bring back a revoked grant, a consumed recovery proof, a deleted item or an earlier site-export policy. Scope therefore keeps one constant-size paired minimum outside the failure and restore domain of its database backup and signing keys: the control incarnation, the authority principal, the authority checkpoint's epoch, reference and hash, and the durable-state checkpoint's sequence, reference and hash. Its compare-and-swap accepts only the exact next state checkpoint whose authority tuple is unchanged or advances to the co-committed authority successor. Rehearse database backup, whole-machine restore and cloning to prove that none rolls back the anchor with the protected state. A co-restored copy or a timestamp cannot establish an independent minimum. Interrupt both halves of the database-to-anchor advance and inspect the committed pair before recovery. The chosen implementation and its threat assumptions are pinned in the deployment lock.

Scope reports no visible change and admits no dependent request until the database transaction is durable and the anchor has advanced to the signed pair. A crash between the two idempotently completes the verified database chain before any new admission.

| What startup or restore finds | What Scope does |
| --- | --- |
| Neither database nor anchor | A one-time empty bootstrap may begin |
| The database ahead by one or more exact, contiguous, signed checkpoints | Recompute every root, advance the anchor in order, return the original result |
| Checkpoints, roots, predecessor chains and anchor all match | Normal startup |
| The anchor ahead, the same epoch or sequence with a different hash, a mismatched pair, a missing checkpoint, a broken predecessor, a root mismatch, an unknown signer or profile, a partial mutation | Fail closed into owner recovery; never reset the anchor or rerun bootstrap |

If the anchor itself is lost, Scope does not trust a restored database. The old store is kept as quarantined evidence, and recovery first tries to rebuild forward from independently verified owner records, source snapshots, receipts, tombstones, policy heads and migration manifests into a new control incarnation, under the affected scope owner's explicit authorisation. If exact reconstruction is impossible, a new authority scope starts with a new admission principal and key, every resource owner and caller registers again, and sources are reimported through normal imports; nothing from the old scope is silently reactivated. The checkpoints themselves are described on [Admission and trust](admission-and-trust.md).

## Startup follows a fixed order

1. Connect to the approved Dolt binding for Scope's store and read the independent anchor.
2. Verify the paired authority and durable-state checkpoints against that anchor. For an import that has crossed its SQL swap, reconcile its [ordered checkpoint and Dolt boundaries](source-imports.md) before rebuilding or admitting dependent work. Complete only exact contiguous successors and fail closed on any mismatch.
3. Take the controller's writer fence.
4. Read the snapshot counter.
5. Rebuild the deterministic graph from accepted state: the core tables, the score projection for the selected head, the accepted import generations, and never another owner's database.
6. Resolve and validate the active retrieval snapshot against the current head, policy, permission, revocation and freshness coordinates, component digests and activation journal; if it is missing or invalid, build a successor off-path, enter a permitted strict degraded mode, or fail readiness. A partial or mismatched snapshot is never served.
7. Start the local transport, and the restricted loopback adapter only when an admitted browser plugin needs it.
8. Replay unacknowledged owner-event inbox records and unprojected use receipts.
9. Start the rebuildable projection batching.
10. Log a redacted readiness record with the writer fence, semantic head, policy and snapshot identity and source freshness.

Every transaction that advances the writer generation or any externally visible source, semantic, use, episode, inbox, outbox, site-policy or migration state co-commits the next durable-state checkpoint; a pidfile or a live process cannot stand in for the checkpoint and anchor pair.

## Accepted evidence is durable before it is acknowledged

A use receipt, an owner-event inbox item or an episode's terminal reference is durable before it is acknowledged. Projection work is a replayable cursor over that ledger, not a second queue: a bounded single-consumer projector drains a bounded batch without holding a lock across database input and output, and checkpoints the last projected identity in the same transaction as the projection. Queue saturation records lag and coalesces wake-ups; it never drops accepted evidence or blocks its durable commit indefinitely. Shutdown may ask for a bounded drain, but correctness rests on replay from the durable cursor, not on a graceful exit. Batch size, interval, memory ceiling and back-pressure threshold belong to the measured deployment profile.

## Owner events enter through a durable inbox

Scope may consume a committed owner event only as a reference delivered through Pale's event contract. Delivery is at least once. Scope persists the inbox row before acknowledging and applies admitted events idempotently. The initial inbox stores the delivery and disposition. An applied episode reference requires the later execution contract. Acknowledgement proves receipt, while application and its result have separate evidence.

| Field | Meaning |
| --- | --- |
| `inbox_id` | Scope's immutable identifier |
| `origin_principal_id`, `producer_epoch`, `event_id` | The canonical delivery identity, matching Pale's event contract |
| `source_owner` | The owner's namespace |
| `event_reference_ref`, `event_reference_sha256` | The exact admitted event reference |
| `canonical_event_sha256` | Digest of the complete canonical reference bytes for this delivery |
| `owner_event_ref`, `owner_event_digest` | The owner's committed event and the version Scope evaluated |
| `event_schema_id`, `event_schema_sha256` | The exact event schema and its hash |
| Episode identity, when the family is published | The complete admitted execution coordinate from the selected issuer. The independent inbox has no episode key. [Episodes and use](episodes-and-use.md) |
| `received_at`, `apply_state` | When it arrived; `received`, `applied`, `rejected` or `quarantined` |
| `applied_revision`, `applied_episode_ref`, `applied_episode_sha256` | The resulting episode revision and its evidence, only in the deferred episode branch |
| `error_category` | A bounded, non-secret failure category |

The delivery uniqueness key is the origin principal, producer epoch and event identifier. A separate key, the owner, owner event and its digest, stops the same owner version being applied twice under different deliveries, and a changed digest for one immutable owner reference is quarantined. Reuse of a delivery key with a different canonical digest, reference or schema is quarantined before duplicate handling and is never an exact replay. Unknown schema versions, scope mismatches and missing owner records are quarantined and never become facts. The diagnostic stream is a rebuildable local projection, never a durable cross-system journal.

## Errors fall into three kinds

```rust
#[derive(thiserror::Error, Debug)]
pub enum MemoryError {
    #[error("fatal: {0}")]                                           Fatal(String),
    #[error("dolt connection failed: {0}")]                          DoltConnection(#[from] mysql_async::Error),
    #[error("dolt query failed: {0}")]                               DoltQuery(String),
    #[error("source projection unavailable: {0}")]                   SourceProjectionUnavailable(String),
    #[error("website publication-context projection unavailable: {0}")] WebsiteProjectionUnavailable(String),
    #[error("telemetry write failed (non-fatal): {0}")]              TelemetryWriteFailed(String),
    #[error("required source is stale or unavailable: {0}")]         RequiredContextUnavailable(String),
}
```

| Kind | Example | What happens |
| --- | --- | --- |
| Fatal | The writer fence is unavailable; the store cannot recover | Log a safe diagnostic and exit non-zero |
| Operational | Invalid schema or scope, a source timeout, a conflict | Return a stable typed error; no hidden retry or effect |
| Degraded | An optional source is unavailable; a rebuildable projection lags | Return explicit limitations, only for task classes that allow it |

How each class of task degrades is on [Episodes and use](episodes-and-use.md).

## Migrations run through their own journaled runner

```text
schema/
  V001_core_entities.sql
  V002_workspace_projection_memberships.sql
  V003_context_evidence.sql
  V004_people.sql
  V005_resources.sql
```

The runner takes the writer fence, stops normal writes, hashes every migration file and reads the exact authoritative branch head and the migrations table; free-form `dolt_log` messages are diagnostic only. Each migration's identity is its version and file hash, and its manifest also binds the filename, the exact expected prior migration, head and schema digest, the target schema digest, the minimum and maximum Dolt versions and the rollback class; the same version with changed bytes or a mismatched prior state conflicts. The runner creates or resumes the deterministic branch `__scope_migration/V###-<file_hash_prefix>` from the expected prior head, and its append-only journal records `prepared`, `sql_committed`, `dolt_committed` and `verified`, each binding its predecessor. `prepared` commits first; the file runs in one SQL transaction on the branch and appends `sql_committed` with the measured schema digest; `DOLT_COMMIT` creates the candidate, the runner resolves the exact ref, commit and tree and appends `dolt_committed`, verifies schema and data invariants, appends `verified` and commits; then the authoritative branch advances from the expected prior head to the verified candidate by compare-and-swap or fast-forward. A moved head, an unrelated dirty working set, an unknown ref or a changed file fails closed.

| State on restart | What happens |
| --- | --- |
| No journal or branch, and the prior head matches | Create `prepared` |
| `prepared`, no SQL change | Execute once |
| `sql_committed` with the matching dirty working set | Verify and commit those bytes; never rerun the DDL |
| Candidate commit exists, authoritative head still prior | Verify the commit, then compare-and-swap or fast-forward |
| Authoritative head equals the verified candidate | Exact replay returns the original migration receipt |
| Any hash, schema or ref divergence, or a partial journal | Quarantine and require operator recovery |

On failure only the migration transaction rolls back or the candidate branch is quarantined; unrelated accepted state is never hard-reset, and if the pinned Dolt version cannot prove the branch, working-set, transaction and swap semantics, migration stays disabled. The migration receipt binds the version and file hash, manifest hash, expected prior head and schema, every journal transition, the candidate commit and tree, the measured schema, the prior and new authoritative heads, the runner's fence and the activation time; it is emitted only after the authoritative ref advances, exact replay returns the same bytes, and it stays an internal record. Tests crash the runner before and after every transition, SQL commit, Dolt commit, verification and ref advance, and cover changed-file reuse, skipped versions, a wrong prior schema, an unrelated dirty working set, concurrent runners and exact replay. Source imports never reuse this runner; they have their own journal on [Source imports](source-imports.md).

## Performance limits come from measurement

Each deployment sets its limits only after measuring the exact Scope and Dolt versions, schema, corpus, controller isolation, hardware and concurrency. At minimum it benchmarks warm and cold resolves, durable use and episode admission, import activation, compiler and whole-snapshot build and validation, each route and fusion, atomic activation, old-reader drain, strict and full degradation, full projection rebuild, liveness, readiness and explicit reload, recording p50, p95 and p99 latency, throughput, resident and peak memory, queue depth, and timeout and cancellation behaviour under normal load, contention, degraded dependencies, restart and recovery. Promotion needs headroom above what was observed; meeting a median with no margin in the tail or in memory is a failure, and no figure, such as a sub-millisecond graph walk or a fifty-millisecond resolve, is a threshold until measured and approved. Liveness proves only that the process answers without a dependency read; readiness separately checks the admitted authority and checkpoint, the writer fence, storage and required source frontiers. Structured spans record the operation, profile and exact revisions without secrets, and alerts compare against the admitted profile. Scope makes no model call on its base path, but no model cost is not no cost: latency, CPU, memory, storage and failure amplification are measured where they are owned, and the whole machine's margin is measured idle and loaded with every store and daemon running.

## Recovery must be proved before this is called built

For an issued bundle or use receipt that depends on exact historical bytes, retain its immutable revision and digest under the owner's retention rules. Resolve it after a mutable view changes and after its storage location moves. Recovery either reads preserved bytes or rebuilds from the exact saved inputs, configuration and tool revision; compare the result with the original digest and distinguish those routes from different bytes or no result. If exact rebuilding is impossible, retain the original while policy permits and the claim depends on it. Otherwise leave the claim unproved. A digest match establishes content identity; custody, rights and permission to use the restored state need separate checks. Scope determines which revisions remain reconstructible under its accepted frontier and deletion rules.

For an exact serialized bundle, preserve the expected digest and byte count, original carrier, selected members and their order, the selector rule and original key mappings. Distinguish an order recorded at issuance from one recovered later. Reject missing, duplicate or ambiguous selections while retaining legitimate repeated members at their separate positions. Fix the serializer and every byte-affecting option: encoding, escaping, indentation, separators, newline conversion and final newline. Rebuild in isolation using the original sequence rather than filesystem traversal; compare digest and byte count. Test changed order, changed options and missing members. Equal parsed values with different bytes do not prove exact recovery. Where only a checksum is needed and reading is permitted, stream into the digest calculation; keep any inspection copy within the owner's retention and disclosure rules.

Equal bytes shared by several receipts remain separate records. Preserve each occurrence's identity, original locator, revision, digest, length, custody, retention or hold, access scope and captured metadata, including file kind, mode and timestamp precision when needed. Distinguish restored metadata from an observation retained about it, and do not count equal captures as independent evidence. Check permission through the requested occurrence before opening or revealing a shared body or alias. Reconstruct each authorised occurrence separately and compare its bytes and required metadata. Test equal bytes at two locators with different metadata, changed bytes under a familiar locator, forbidden lookup and loss of the shared body. Removing one route must deny that route while preserving independently required retention. Keep storage separate if holds, erasure or recovery promises cannot be honoured independently; retiring a redundant copy needs its owner's decision after all affected recovery routes pass.

Tests must show that killing the process before or after every import, inbox apply, use receipt and episode close leaves either the old revision or the complete new one; that stale writer generations and duplicate owner events change nothing; that losing the graph, the replay ring or the score projections is recovered from accepted records without inventing evidence; that a replaced source keeps the previous generation until the new one validates atomically; that deletion removes only policy-authorised payload, keeps required identity, lineage and tombstones, invalidates dependent bundles and never resurrects on replay; that an unauthorised principal cannot infer hidden nodes through counts, scores, timing, errors, replay gaps, health data or aggregate changes; that optional degradation is visible and critical failure fails closed; that a crash around snapshot publication and activation leaves exactly one active head with pinned readers finishing and rollback reactivating the prior bytes; that deletion, revocation and freshness invalidation reach every dependent snapshot, embedding, affinity feature and cache while deleting only affinity changes no truth; that strict mode loads no model-made artifact and an unavailable route is never an empty success; that vector output, traversal influence and observable isolation meet the declared level; and that governed deletion leaves decisions marked unreconstructible where their inputs are gone. The complete list is on [Acceptance tests](acceptance-tests.md).

Part of [Scope engineering](README.md).
