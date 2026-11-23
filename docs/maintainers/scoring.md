# Scoring

Scope's initial scoring design uses A-MAC-lite to rank items that have already passed the eligibility checks. Its four factors are a prior by content type, recency with a half-life per type, a brief novelty boost, and support from accepted caller use reports. The formula exposes each contribution so that later comparisons can test whether the score is useful.

Scoring can reorder and trim optional context, but cannot delete, supersede or tombstone an item, authorise a retrieval method, widen eligibility or suppress required context. A-MAC-lite is a local starting formula, not evidence that these factors or defaults outperform simpler scoring on Scope’s workload. The comparisons below must establish that before a successor is selected.

## Four kinds of content, each with its own prior and half-life

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ContentType {
    Legislative,   // laws, regulations, compliance rules, curated reference
    Entity,        // people, organisations, projects
    Transaction,   // email threads, documents, task outcomes
    Ephemeral,     // session context, temporary notes, drafts
}
```

| Content type | Prior | Half-life    |
| ------------ | ----- | ------------ |
| Legislative  | 1.0   | Never decays |
| Entity       | 0.8   | 90 days      |
| Transaction  | 0.5   | 30 days      |
| Ephemeral    | 0.3   | 7 days       |

These values are the canonical defaults, and the half-lives are configurable per deployment. The scorer keeps the name A-MAC-lite; Reckon's moving-average comparison arm is a different algorithm with a different name, and golden-parity tests name exactly the algorithm they match. Before reading or emitting either profile, map its serialised identifier to the producer revision, configuration and actual algorithm. A familiar token or successful decode cannot establish the behaviour that produced an old score. Preserve that version's meaning and refuse an ambiguous mapping. Distinct algorithms need distinct canonical identities. Any temporary alias needs an owner-approved same-contract mapping, specified readers and versions, one canonical write form and a removal condition supported by usage. Test a permitted legacy read, canonical write, ambiguous identifier, retired alias and a well-formed record whose familiar token names different behaviour in another producer profile. Run a distinguishing input through the actual algorithms as well as their parsers and writers.

## The formula

Source validity, revocation, classification, visibility, contradiction and the request’s freshness requirement govern eligibility before scoring. Qualify eligibility separately from the score and outcome using the controls below. An item that was accessed but has expired or been revoked stays ineligible, and access recency can only rank eligible candidates; it can never extend a valid-through time, suppress a tombstone or override an owner's revision.

```text
recency    = exp(-ln 2 * days_since_last_access / half_life)      (1.0 when the half-life is infinite)
novelty    = max(0, 1 - retrieve_count / novelty_threshold)          novelty_threshold = 5
confidence = min(1, use_receipt_count / confidence_threshold)        confidence_threshold = 10
raw_score  = prior * recency * (1 + novelty_weight * novelty)
                   * (confidence_floor + (1 - confidence_floor) * confidence)
                                                                      novelty_weight = 0.3, confidence_floor = 0.5
raw_max    = max(content_type_priors) * (1 + novelty_weight)          = 1.3 with these values
normalized = raw_score / raw_max
```

After five retrievals the novelty boost is gone. With the default configuration, the confidence multiplier rises continuously from 0.5 with no accepted use receipts to 1.0 at ten receipts; one receipt gives 0.55 and nine give 0.95. Only the consumed item references in a newly accepted [caller report](episodes-and-use.md) advance `use_receipt_count` and `last_used`. Ignored items, bundle inclusion alone and exact replay add no use credit. This confidence measures support from admitted caller reports.

Scores are normalised by the maximum for the active configuration, never clamped. Interfaces and displays use the normalised value in the unit interval; storage keeps the raw score, the maximum, every component, the formula version and the configuration hash. Neither value is a probability or a calibrated confidence. Old scores are recomputed or kept under their original formula version, never silently reinterpreted.

## The domain fails closed

Every numeric prior, half-life, weight, floor and runtime age must be finite, and age cannot be negative. A numeric half-life must be strictly positive; no decay is represented by `None`, not by a floating-point infinity. Every prior and the confidence floor lie in the unit interval. The novelty weight is not negative. Both thresholds are at least one. At least one prior is positive, so the maximum is finite and strictly positive. An unknown content type, a missing entry, an invalid configuration or input, a non-finite intermediate value or a non-positive maximum returns a typed scoring error; the scorer never panics, divides by zero, emits NaN or infinity, or clamps a bad configuration into a different one.

```rust
pub struct ScoringConfig {
    pub half_lives: HashMap<ContentType, Option<f64>>,   // None = infinite
    pub content_type_priors: HashMap<ContentType, f64>,
    pub novelty_threshold: u32,
    pub novelty_weight: f64,
    pub confidence_threshold: u32,
    pub confidence_floor: f64,
}

pub struct ScoreBreakdown {
    pub raw_score: f64, pub normalized_score: f64, pub raw_max: f64,
    pub prior: f64, pub recency: f64, pub novelty: f64, pub confidence: f64,
    pub formula_version: String, pub config_hash: String,
}

pub fn compute_score(content_type: ContentType, days_since_access: f64,
                     retrieve_count: u32, use_receipt_count: u32,
                     config: &ScoringConfig) -> Result<ScoreBreakdown, ScoringError> {
    validate_scoring_domain(&content_type, days_since_access, config)?;
    let prior = config.content_type_priors[&content_type];
    let recency = match config.half_lives[&content_type] {
        None => 1.0,
        Some(hl) => (-f64::ln(2.0) * days_since_access / hl).exp(),
    };
    let novelty = (1.0 - retrieve_count as f64 / config.novelty_threshold as f64).max(0.0);
    let confidence = (use_receipt_count as f64 / config.confidence_threshold as f64).min(1.0);
    let raw_score = prior * recency * (1.0 + config.novelty_weight * novelty)
        * (config.confidence_floor + (1.0 - config.confidence_floor) * confidence);
    let raw_max = maximum_for_config(config)?;
    ensure_finite_score(raw_score, raw_max)?;
    Ok(ScoreBreakdown { raw_score, normalized_score: raw_score / raw_max, raw_max,
        prior, recency, novelty, confidence,
        formula_version: FORMULA_VERSION.into(), config_hash: config_hash(config) })
}
```

Golden vectors cover zero thresholds, all-zero priors, missing entries, zero, negative and non-finite half-lives, negative and non-finite ages, NaN and infinity in every floating field, extreme counters, exact normalisation boundaries and every typed failure. Property tests require every admitted result to be finite and between zero and one.

## Scores are never global

A score is keyed on the full scope: principal, controller, optional relationship, evaluation scope, the exact owner-issued role reference, and the immutable role and assignment evidence. Two roles that render with the same label in different organisations, clients, purposes or assignments never share counters or learned utility, and a path with no organising owner still presents an admitted role and purpose and never invents a placeholder.

```sql
CREATE TABLE context_scores (
    node_key                   VARCHAR(128) NOT NULL,
    principal_scope            VARCHAR(128) NOT NULL,
    controller_scope           VARCHAR(128) NOT NULL,
    relationship_scope         VARCHAR(128),            -- absent when none applies; no empty sentinel
    evaluation_scope           VARCHAR(128) NOT NULL,
    role_ref                   VARCHAR(1024) NOT NULL,  -- exact owner-issued reference, never a display role
    role_evidence_ref          VARCHAR(1024) NOT NULL,
    role_evidence_sha256       VARCHAR(64) NOT NULL,
    assignment_evidence_ref    VARCHAR(1024),           -- pair absent when no assignment applies
    assignment_evidence_sha256 VARCHAR(64),
    context_score_key_sha256   VARCHAR(64) NOT NULL,    -- hash of the complete canonical scope tuple
    content_type               VARCHAR(16) NOT NULL,
    retrieve_count             INT DEFAULT 0,
    use_receipt_count          INT DEFAULT 0,
    last_retrieved             DATETIME,
    last_used                  DATETIME,
    raw_score                  DOUBLE NOT NULL,
    normalized_score           DOUBLE NOT NULL,
    component_values           JSON NOT NULL,
    formula_version            VARCHAR(32) NOT NULL,
    config_hash                VARCHAR(128) NOT NULL,
    raw_max                    DOUBLE NOT NULL,
    PRIMARY KEY (node_key, context_score_key_sha256)
);
```

The table holds Scope's own rebuildable projection, not truth and not Reckon's output.

## Telemetry records what was available, not just what was given

Telemetry starts with the first admitted scoring use, because it is the evidence every later comparison needs. It is scoped by controller, relationship and role; candidate sets include only items the request was allowed to know existed, and no cross-role maximum, total, timing or error aggregate is computed before scope filtering.

The initial telemetry records resolve, read and reported use without an execution identity. A later [episode contract](episodes-and-use.md) must bind the identity before telemetry can join an owner's outcome or store a weight and its mapping version for a declared evaluation.

```sql
CREATE TABLE telemetry_events (
    id                    BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_type            VARCHAR(24) NOT NULL,     -- resolve, context_use
    principal_scope       VARCHAR(128) NOT NULL,
    controller_scope      VARCHAR(128) NOT NULL,
    relationship_scope    VARCHAR(128),
    role_ref              VARCHAR(1024) NOT NULL,
    project_key           VARCHAR(64),
    task_ref              VARCHAR(1024) NOT NULL,
    task_feature_ref      VARCHAR(1024),  task_feature_sha256 VARCHAR(64),
    task_feature_uncertainty_json JSON,
    semantic_head_ref     VARCHAR(1024) NOT NULL,  semantic_head_sha256     VARCHAR(64) NOT NULL,
    retrieval_policy_ref  VARCHAR(1024) NOT NULL,  retrieval_policy_sha256  VARCHAR(64) NOT NULL,
    materialization_ref   VARCHAR(1024) NOT NULL,  materialization_sha256   VARCHAR(64) NOT NULL,
    permission_slice_ref  VARCHAR(1024) NOT NULL,  permission_slice_sha256  VARCHAR(64) NOT NULL,
    revocation_frontier_ref VARCHAR(1024) NOT NULL, revocation_frontier_sha256 VARCHAR(64) NOT NULL,
    retrieval_decision_ref VARCHAR(1024) NOT NULL, retrieval_decision_sha256 VARCHAR(64) NOT NULL,
    eligibility_result_json JSON NOT NULL,
    freshness_result_json   JSON NOT NULL,
    required_context_json   JSON NOT NULL,
    routes_considered_json  JSON NOT NULL,
    routes_invoked_json     JSON NOT NULL,
    routes_skipped_json     JSON NOT NULL,
    node_keys_json          JSON,       -- what the bundle returned
    candidate_nodes_json    JSON,       -- the complete eligible set within the bounded traversal
    node_scores_json        JSON,       -- raw and normalised score with provenance, per candidate
    node_features_json      JSON,       -- feature snapshot per candidate
    route_candidates_json   JSON,       -- per-route candidates, features and scores before fusion
    fused_order_json        JSON,       -- stable fused order, ties and fusion provenance
    omitted_items_json      JSON,       -- reason, budget or limitation per omitted item
    consumed_items_json     JSON,       -- admitted caller-reported use echoed by Scope
    output_reference_candidates_json JSON,   -- derived mentions in output; never proof of use
    reference_derivation_profile_ref VARCHAR(1024), reference_derivation_profile_sha256 VARCHAR(64),
    decision_stage          VARCHAR(32) NOT NULL,   -- created, bundle_read, use_recorded
    degradation_json        JSON,
    context_tokens_used     INT,
    bundle_tokens_budget    INT,        -- Scope's budget, not the model's context window
    latency_ms              INT,
    node_count              INT,
    created_at              DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

Recording what was available as well as what was selected makes the decision inspectable. If A, B and C were returned and the work went well, that alone says nothing about whether D would have helped. Keeping A through F as candidates, with their scores and the chosen set, supports replay, candidate training and later policy comparisons within admitted uses and the governed evidence window. Off-policy estimation additionally needs the logging policy to have given relevant alternatives non-zero probability; a deterministic scorer gives unchosen items zero probability, which ordinary inverse-propensity methods cannot repair. The [use receipt](episodes-and-use.md) records the admitted caller's report. Owner-derived output mentions follow the [derivation contract](improvement-and-go-live.md) and remain a separate, labelled feature.

Use receipts and owner-event inbox records are committed durably before they are acknowledged. Only the rebuildable score and diagnostic projections may be batched, under a deployment-selected interval, size and memory budget and on graceful shutdown, with one Dolt commit per batch; the batching pattern is on [Durability and recovery](durability-and-recovery.md).

## A comparison fixes its evidence and controls before scoring

Define the exact candidate population, counted unit, decision time, evidence available then, eligibility policy, formula version and outcome definition. Keep eligible, disqualified and unresolved cases separate, applying the owner’s rule when a condition cannot be checked. Retain each decision’s reason and the strongest relevant contrary evidence. Test a high-scoring candidate blocked by policy, stale or missing eligibility evidence and a case exactly at the valid boundary; inspect selection and the exported view. Different rules or evidence create a new comparison with its own population.

Fix candidate identities, case revisions, budget, environment, rubric, blocking criteria, scorer, threshold, uncertainty policy and aggregation before comparison. A mechanical checker must reject known-bad controls at the intended check. A judgment rubric needs examples separating adjacent grades and checks that style or verbosity does not dominate. Keep tuning cases out of the holdout. Report disagreement, unstable results, missing coverage, threshold sensitivity and regressions hidden by averages; an average never cancels a blocking failure. Keep screened, eligible, assigned, scored and outcome-observed counts separate, with their time window and missing or pending outcomes. Outcomes observed only for selected cases justify claims about that group, not every candidate. A score is no probability without separate calibration.

The initial comparison includes `recency * log(1 + retrieve_count)`, A-MAC-lite, Reckon's moving-average utility, shaped credit, ablation attribution and a priority rule. Reckon's moving average is `u_new = (1 - η) * u_old + η * credit * outcome`, with `η = 0.1` and a unit-interval clamp, exercised against eligible frozen vectors. Proportional and smooth-positive credit variants require published zero-total, non-finite and replay cases; existing utility feeding credit is not evidence that shaped credit beats equal credit. Ablation supports a causal claim only under a separately accepted causal-evidence profile. The priority comparator `utility + (max(ablation_delta, 0) + max(counterfactual_delta, 0)) * 0.5` ranks and never deletes.

Before running, declare eligible owner outcomes, their utility mapping, controller scope, complete resolve/use/outcome evidence, datasets, splits, seeds, tolerances, hardware, non-inferiority or improvement thresholds, information-loss and leakage limits. Keep budget omissions visible. Precision and recall are diagnostics; outcomes remain a vector of separate owner facts. Set the required evidence from diversity, support and uncertainty, not a universal row count. Prefer the simpler policy when results are materially equivalent; do not invent a margin after seeing results. [Evaluation records and release](evidence-export-and-reckon.md) preserve the comparison and the separate owner decision.

A learned scorer, budget gate, learned credit model, trajectory model or reinforcement-learning memory policy remains a research candidate requiring a measured gap in simpler methods. Future-use or outcome labels cannot be features from the same event, and an incumbent score cannot serve as its own target evidence. Use time- and controller-held-out cases, calibrated uncertainty and abstention. Unselected items are not negative examples; deterministic logs give them zero propensity and cannot support inverse-propensity estimates for unseen alternatives. Randomised exploration needs its own permission and logging. A learned budget gate cannot delete, and destructive memory operations remain owner-reviewed proposals. Eligibility, required context, privacy, source binding and strict mode never become learned choices.

## The response is filled greedily within its budget

Bundle selection is budgeted, and nothing about selection changes the graph or the sources:

1. Compute each candidate's encoded or token cost and the whole response's cost; node count alone is not a budget.
2. Apply visibility, freshness, classification and the task's required and optional context before any optimisation.
3. If eligible optional material still exceeds the budget, keep every required item and its dependencies under their explicit requirement (graph degree never creates an implicit protection floor), rank only the optional eligible items by utility per unit of cost with provenance, and omit the lowest until the response fits.
4. Record every omitted requirement or item and any resulting limitation in the bundle.
5. Optionally propose a bounded compaction under an owner-published schema; canonical and source rows stay unchanged.

This greedy selector makes no claim to be an optimal knapsack and has no authority to delete. Content from Gazette's site exports and legislative material is never physically removed by ranking; a bundle may omit it only with an explicit omission carrying the exact adapter, owner, snapshot and row provenance. Mentions derived from outputs, content hints and every other feature enter scoring only when their owner's exported schema admits them.

Part of [Scope engineering](README.md).
