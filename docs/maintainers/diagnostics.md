# Diagnostics

In Scope's design the diagnostic stream lets a separately owned interface show what the service is doing; nothing runs yet, because the kernel is an empty library. Scope itself stays headless. One authenticated viewer at a time receives only the state it may see, filtered before serialisation: resolves, reported context use, score projections, omissions, imports, rebuilds, errors and health. Owner-outcome events additionally depend on the deferred execution identity contract described below.

The stream is a rebuildable local projection. Durable records stay in Scope's store; ecosystem events enter its inbox by reference, and Pale observes Scope through its own event contract. An interface may render the stream inside Reckon's debugger; the backend and the isolation tests it needs are the work in front.

## The daemon exposes one stream beside its operations

```text
Scope daemon (one process)
  ├── deployment-selected local transport      native callers; authenticated
  ├── Dolt on 3309                             separate process
  └── restricted loopback HTTP and WebSocket    optional, for an admitted browser plugin only
        ├── resolve, bundle read, use report, health, operator reload
        └── /ws, the diagnostic stream
```

Viewers present Pale's short-lived admission reference when integrated, or the exact standalone grant and signed request admission; Scope never mints a principal, a credential or a general capability. Host and Origin validation and loopback binding are defence in depth, never admission. Every endpoint shares one daemon state: the graph projection, the persisted episodes, the snapshot counter and the rebuildable telemetry projection. The protocol is a snapshot on connect followed by deltas, with an epoch and sequence cursor for resume, an explicit schema version and disconnect-with-resume, and it must be built and contract-tested before any consumer relies on it.

## Every frame carries the same envelope

```typescript
interface ScopeDiagnosticEventV1 {
  type: string; // discriminator
  event_id: string; // unique within this daemon epoch
  epoch: string; // daemon boot epoch, new on every start; required for resume
  timestamp: string; // display only
  sequence: number; // monotonic; the ordering key and replay cursor
  schema_version: number; // bumped on any breaking change
}
```

The epoch and sequence together are the replay cursor, valid only within one epoch. Filtering happens before serialisation: out-of-scope nodes, edges, roles and sources can never influence visible counts, aggregate scores, error shapes, replay gaps or health fields.

## The events

**Snapshot.** Sent once after authentication: the caller-visible nodes, edges, daemon health and consumer activity, never the controller's unfiltered graph. Each node carries its key, type (legal entity, person, site-author projection, brand, project, workspace, domain, email, resource, repository, article, collection, journey), its adapter and source-provenance reference and hash, a label, its content type, and scores for this caller's scope only: the normalised and raw score, maximum, formula version, configuration hash, retrieve and use counts and last retrieved and used times. Each edge carries its key, ends, namespaced relationship type, direction, semantic owner, owner relation reference and hash, source revision, admission, validity, classification, visibility, a display label and an optional derived traversal score. A renderer may show a friendly label but never collapses an owner term such as rights held by, operated by, authored by or collection member into a generic owns, directs, stakeholder or related edge; unknown or unadmitted relation metadata hides the edge rather than guessing.

```typescript
interface ScopeDiagnosticSnapshotV1 extends ScopeDiagnosticEventV1 {
  type: "scope_diagnostic_snapshot";
  nodes: GraphNode[];
  edges: GraphEdge[];
  daemon: DaemonHealth;
  consumer_activity: ScopeConsumerActivityProjectionV1[];
}

type NodeType =
  | "legal_entity"
  | "person"
  | "website_author_projection"
  | "brand"
  | "project"
  | "workspace"
  | "domain"
  | "email"
  | "resource"
  | "git_repo"
  | "article"
  | "collection"
  | "journey";

type ContentType = "legislative" | "entity" | "transaction" | "ephemeral";

interface GraphNode {
  key: string;
  node_type: NodeType;
  source_adapter_id: string;
  source_provenance_ref: string;
  source_provenance_sha256: string;
  label: string;
  content_type: ContentType;
  score: number;
  raw_score: number;
  raw_max: number;
  formula_version: string;
  config_hash: string;
  retrieve_count: number;
  use_receipt_count: number;
  last_retrieved: string | null;
  last_used: string | null;
  metadata: Record<string, string>;
}

interface GraphEdge {
  edge_key: string;
  source_key: string;
  target_key: string;
  relationship_type_id: string;
  direction: "forward" | "inverse";
  semantic_owner_ref: string;
  owner_relation_ref: string;
  owner_relation_sha256: string;
  source_revision_ref: string;
  admission_ref: string;
  valid_from: string | null;
  valid_until: string | null;
  classification: string;
  visibility: string;
  label: string;
  traversal_score: DerivedScoreV1 | null;
}

interface DerivedScoreV1 {
  value: number;
  formula_version: string;
  evidence_ref: string;
}
```

The initial stream can project admitted resolve and use records independently. Its schema omits `episode_identity`, `active_episodes` and `visible_owner_outcome_count`, and emits no owner-outcome event. The sketches below include the deferred fields for the [execution identity contract](episodes-and-use.md). An absent field means that the stream cannot report that measure. Zero is a measured count.

**Resolve.** After an admitted request returns a bundle: the request and bundle, the caller, the complete execution identity or none, the role, the project, the root of the walk, the nodes and edges traversed, the nodes returned, latency, candidate and returned counts, and the returned nodes' scores at decision time, all caller-visible only.

```typescript
interface ResolveEvent extends ScopeDiagnosticEventV1 {
  type: "resolve";
  request_id: string;
  bundle_id: string;
  caller_ref: string;
  episode_identity: EpisodeIdentity | null;
  role_ref: string;
  project_key: string | null;
  root_node_key: string;
  traversed_node_keys: string[];
  traversed_edge_keys: [string, string][];
  returned_node_keys: string[];
  latency_ms: number;
  candidate_count: number;
  returned_count: number;
  node_scores: Record<string, number>;
}
```

**Context use.** After a use receipt is accepted: the receipt, the bundle and its digest, caller, task, the complete execution identity or none (derived from the signed receipt, never from task text), role, the caller's reported consumed and ignored items, observed staleness and time. The event describes reported use. It conveys no independent model trace, correctness, outcome, credit or score change.

```typescript
interface ContextUseEvent extends ScopeDiagnosticEventV1 {
  type: "context_use";
  receipt_id: string;
  bundle_id: string;
  bundle_digest: string;
  caller_ref: string;
  task_ref: string | null;
  episode_identity: EpisodeIdentity | null;
  role_ref: string;
  consumed_item_refs: string[];
  ignored_item_refs: string[];
  observed_staleness: string[];
  used_at: string;
}
```

**Owner outcome.** After Scope admits an owner's committed terminal event or later outcome evidence: the execution identity, the owner event and digest, a terminal category (succeeded, failed, timed out, cancelled, expired), an error code and duration where known, the outcome evidence references by class (attempt terminal, verifier result, task acceptance, organiser acceptance, owner approval, goal satisfaction) and the episode disposition (closed, duplicate or evidence strengthened). The classes are independent facts, never a ranking.

```typescript
interface OwnerOutcomeEvent extends ScopeDiagnosticEventV1 {
  type: "owner_outcome";
  episode_identity: EpisodeIdentity;
  owner_event_ref: string;
  owner_event_digest: string;
  terminal_category:
    "succeeded" | "failed" | "timed_out" | "cancelled" | "expired";
  error_code: string | null;
  duration_ms: number | null;
  outcome_evidence_refs: Array<{
    evidence_class:
      | "attempt_terminal"
      | "verifier_result"
      | "task_acceptance"
      | "organiser_acceptance"
      | "owner_approval"
      | "goal_satisfaction";
    evidence_ref: string;
    evidence_sha256: string;
  }>;
  episode_disposition: "closed" | "duplicate" | "evidence_strengthened";
}
```

**Score projection.** When Scope derives or rebuilds its scoring projection from durable evidence: the projection, formula and configuration, the evidence used, each scored node's old and new score, content type and counts, and budget use.

```typescript
interface ScoreProjectionEvent extends ScopeDiagnosticEventV1 {
  type: "score_projection";
  projection_ref: string;
  formula_version: string;
  config_hash: string;
  evidence_refs: string[];
  scored_nodes: Array<{
    key: string;
    old_score: number;
    new_score: number;
    content_type: ContentType;
    retrieve_count: number;
    use_receipt_count: number;
  }>;
  budget_usage: BudgetUsage;
}

interface BudgetUsage {
  slot_count: number;
  max_slots: number;
  slot_utilization: number;
}
```

**Bundle omission** and **optimisation proposal recorded** are separate events, because selecting a bundle and creating a proposal are different facts and neither proves a deletion.

```typescript
interface BundleOmissionEvent extends ScopeDiagnosticEventV1 {
  type: "bundle_omission";
  reason: string;
  omitted_node_refs: string[];
  budget_usage: BudgetUsage;
}

interface OptimisationProposalRecordedEvent extends ScopeDiagnosticEventV1 {
  type: "optimisation_proposal_recorded";
  proposal_ref: string;
  proposal_sha256: string;
  lifecycle_state: "proposal";
}
```

**Source import** and **projection rebuild.** When an import generation is accepted or rejected: the adapter, owner, snapshot, import and receipt, the disposition, the previous and committed generation, nodes and edges added, removed and updated, hydration time, and the caller-visible counts afterwards. A rebuild reports its trigger (startup replay, operator reload, accepted generation change), the generation, the projection and its hash, the time taken and whether it rebuilt, was unchanged or failed.

```typescript
interface SourceImportDiagnosticEvent extends ScopeDiagnosticEventV1 {
  type: "source_import";
  source_adapter_id: string;
  source_owner_ref: string;
  source_owner_sha256: string;
  source_snapshot_ref: string;
  source_snapshot_sha256: string;
  trigger: "owner_import";
  import_id: string;
  import_receipt_ref: string;
  disposition: "committed" | "duplicate" | "conflict" | "rejected";
  previous_generation: number | null;
  committed_generation: number | null;
  nodes_added: number;
  nodes_removed: number;
  nodes_updated: number;
  edges_added: number;
  edges_removed: number;
  hydration_ms: number;
  visible_node_count: number;
  visible_edge_count: number;
  generation: number;
}

interface ProjectionRebuildDiagnosticEvent extends ScopeDiagnosticEventV1 {
  type: "projection_rebuild";
  trigger: "startup_replay" | "operator_reload" | "accepted_generation_change";
  generation: number;
  projection_ref: string;
  projection_sha256: string;
  rebuild_ms: number;
  disposition: "rebuilt" | "unchanged" | "failed";
}
```

**Error.** Non-fatal errors only, since a fatal one ends the daemon: severity (operational or degraded), category (Dolt connection or query, invalid admission, stale source, projection write, cache check), a message, the caller where safely visible, and whether the daemon continues.

```typescript
interface ErrorEvent extends ScopeDiagnosticEventV1 {
  type: "error";
  severity: "operational" | "degraded";
  category:
    | "dolt_connection"
    | "dolt_query"
    | "admission_invalid"
    | "source_stale"
    | "projection_write"
    | "cache_check";
  message: string;
  caller_ref: string | null;
  recoverable: boolean;
}
```

**Daemon health.** On connect and at a deployment-selected cadence: visible node and edge counts and the generation, whether Dolt is connected and its latency, whether the site projection is loaded and its generation and article count, a bounded caller-safe class for telemetry buffer depth, visible telemetry totals and last flush, uptime, visible open episodes, and within a declared window the visible resolve, use and outcome counts and resolve p50 and p99, plus dropped-connection and lag counters. The buffer class never exposes the daemon's raw shared queue depth.

```typescript
interface DaemonHealthEvent extends ScopeDiagnosticEventV1 {
  type: "daemon_health";
  health: DaemonHealth;
}

interface DaemonHealth {
  visible_node_count: number;
  visible_edge_count: number;
  generation: number;
  dolt_connected: boolean;
  dolt_latency_ms: number;
  website_projection_loaded: boolean;
  website_export_generation: number | null;
  website_article_count: number;
  telemetry_buffer_depth: number; // Caller-safe bounded diagnostic class; values remain to be published.
  visible_telemetry_events_total: number;
  last_telemetry_flush: string | null;
  uptime_seconds: number;
  active_episodes: number;
  diagnostic_window_seconds: number;
  visible_resolve_count: number;
  visible_context_use_count: number;
  visible_owner_outcome_count: number;
  resolve_p50_ms: number;
  resolve_p99_ms: number;
  dropped_connection_count: number;
  lag_disconnect_count: number;
}
```

**Consumer activity.** When an admitted consumer resolves or reports use: the consumer, role, Pale's execution evidence as opaque reference and hash pairs (never enumerated or parsed into paths), the execution identity or none, an activity class (recent resolve, recent use, recent error, outside the window) with the window, last resolve and use, last project, and counts. It never claims that a person, harness, agent, worker or session is active, idle, leased, healthy or finished; those are the owners' facts.

To investigate a consumer run, identify one case from the execution owner's native evidence: the request, route, objective, permissions, input and configuration revisions, context, tools, budgets, events, results, saved state and external effects. Mark observations, reconstructions, inferences and unavailable evidence separately. Scope carries references and digests within the viewer's existing scope; a telemetry observation cannot establish the executor's state.

Trace the case from request interpretation through context selection, tool input, execution, result interpretation, rendering and continuity. Find the earliest unsupported transition and the last checked state, distinguishing missing input, denial, timeout, malformed data, provider failure, stale evidence, policy rejection, partial effects and unknown outcomes. Compare a small set of causes with fixed-input replay or one changed variable; an unrepeatable case establishes a risk, not its cause. If one missing observation would distinguish the causes, name its owner and what each result would establish. Leave the transition unresolved when its evidence cannot be read.

Before retrying an uncertain effect, inspect the provider's record for the original attempt; a missing local receipt does not establish failure. Limit retry to a permitted idempotent path with a known temporary fault. Correct input, use an equivalent permitted provider, reconcile partial state or seek the responsible owner's decision as the evidence requires. Report the trace, first divergence, supported cause and uncertainty, containment, correction, affected-case recovery and the check that could disprove the fix. Stop when identities or evidence are missing, inputs keep changing, replay could repeat harm or recovery exceeds permission.

```typescript
interface ConsumerActivityEvent extends ScopeDiagnosticEventV1 {
  type: "consumer_activity";
  activity: ScopeConsumerActivityProjectionV1;
}

interface ScopeConsumerActivityProjectionV1 {
  consumer_ref: string;
  role_ref: string;
  pale_execution_evidence: {
    execution_path_evidence: EvidencePointer;
    delegation_evidence: EvidencePointer[];
    terminal_leaf_evidence: EvidencePointer | null;
  } | null;
  episode_identity: EpisodeIdentity | null;
  activity_class:
    "recent_resolve" | "recent_use" | "recent_error" | "outside_window";
  diagnostic_window_seconds: number;
  last_resolve: string | null;
  last_context_use: string | null;
  last_project_ref: string | null;
  resolve_count: number;
  context_use_count: number;
  error_count: number;
}

interface EvidencePointer {
  record_ref: string;
  record_sha256: string;
}
```

## Authentication comes before any data

1. Before the browser connects, its trusted plugin worker opens the stream through the admitted path: a caller-signed Pale common request bound to the exact stream-open body, or the standalone admission and body pair. An opaque reference alone is never authentication.
2. Having verified that, Scope may mint a short-lived, one-use stream handle. It is a derivative of the session, not new authority, and binds a server challenge, the admission references and hashes, the immutable scope, the stream, the allowed Origin, the epoch and the exact requested resume cursor.
3. The browser connects and the server sends nothing. Within a bounded timeout the browser sends an auth frame with the handle, its challenge response and an optional resume cursor; otherwise the server closes with 4401.
4. The server validates the handle's signature and state, one-use status, expiry, the challenge, Origin and Host, scope, stream and resume binding, and rechecks the underlying admission frontier. A reused, partial, expired, revoked or mismatched handle closes with 4403. The operator's reload capability is never a browser scope.
5. Only then does the server send a claims-scoped snapshot or the admitted resumed deltas. Nothing outside the bound principal, controller and relationship scope, purpose, classification ceiling and exact consumer and path references is ever serialised; execution identifiers and roles may narrow a view but never replace those scopes.

Browser connections are checked against an explicit Origin allowlist and the Host header at upgrade time, because cross-origin rules do not govern WebSockets. Socket-side consumers use the same admitted scope, and peer credentials are defence in depth that cannot tell apart agents sharing one operating-system user. If the admission expires or is revoked mid-connection, the server closes with 4403, and reconnecting needs a fresh admission from its owner.

## Viewers can narrow what they see, never widen it

The default subscription is the full claims scope and nothing more. A client may `subscribe` with filters that narrow within the claims, `unsubscribe` back to the full claims scope, `request_snapshot` for a fresh scoped snapshot, and answer liveness with `pong`. A filter naming any scope, purpose, classification or execution reference outside the claims is rejected with an error frame and never partially applied.

```typescript
interface EventFilters {
  principal_scope?: string[];
  controller_scope?: string[];
  relationship_scope?: string[];
  purposes?: string[];
  classification_ceiling?: string;
  execution_refs?: EvidencePointer[];
  source_adapter_ids?: string[];
  content_types?: ContentType[];
  roles?: string[];
  node_keys?: string[];
  event_types?: string[];
}

type ClientControlFrame =
  | { type: "subscribe"; filters: EventFilters }
  | { type: "unsubscribe" }
  | { type: "request_snapshot" }
  | { type: "pong" };
```

## Slow viewers are disconnected, never silently degraded

A bounded in-memory replay ring, sized from the deployment's measured event rate, reconnect window, memory ceiling and snapshot cost, backs resume. On reconnect in the same epoch with a cursor still in the ring, the server replays the missed claims-filtered deltas; a different epoch or an evicted cursor gets a fresh scoped snapshot. There is no durable event log: the snapshot is the whole recovery path. When a viewer's send buffer fills or it lags the broadcast, the server closes with 4408 and the last delivered sequence, and the viewer resumes from the ring or a snapshot; frames are never dropped on a live connection, because that would silently break ordering.

Before acceptance, identify the stream producer, viewer, embedded-panel host, exact schema and snapshot, scope and permitted purpose. Providing a display slot gives a host neither credentials nor authority over the data. Any action available from the view needs a separately admitted route and inspection of its actual result.

Compare overview, counts, legends, details and accessible status against the same assertion identity and source revision. Preserve relationship endpoints, direction, kind and evidence; a node score, observed pair and inferred relation are different facts. Matching labels or one shared endpoint do not establish a pair, and repeated delivery adds no evidence. Distinguish verified empty, missing, unmeasured, stale, disconnected and denied states. A gap must not appear empty or successful, and an unsupported action stays unavailable. A failed embedded panel must leave separately owned host views working.

Exercise two viewer scopes, a shared identifier, a hidden assertion and a mismatched pair observation. Test duplicate and reordered frames, gaps, expired cursors, restart, ring eviction, lag disconnect and scope changes with the configured limits. Recheck admission on resume and after mid-stream revocation; when exact replay is impossible, require an explicit reset or newly permitted snapshot. Prove isolation across controller and relationship scopes, including scores, timing, sequence gaps and health. Neither a late update nor replay or a fresh snapshot may resurrect a deletion, tombstone or revoked access.

Test the authenticated live stream, action results and any scale claim separately from renderer fixtures, with fixed fixtures, target environment, load and budgets. Compare displayed and accessible results with the owning records, then remove or disconnect the panel. Keep repeatable cases in the view's tests and report mismatches, checked coverage and the owner of each remaining check.

Part of [Scope engineering](README.md).
