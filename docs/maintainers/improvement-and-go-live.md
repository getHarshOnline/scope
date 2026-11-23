# Improvement and go-live

Scope improves offline: freeze the permitted evidence, propose a change, measure it independently, obtain the owner's decision, release the chosen bytes and activate them separately. The optimiser cannot change its own test. Scope owns changes to its scorer, retrieval policy and memory; Pale's SkillOpt owns improvements to the agent instructions for using Scope.

Scope requires the complete adaptive system and its offline rehearsal before go-live. Every learned promotion requires all three Reckon roles: evaluation, a curated case in the shared set, and preservation of the responsible owner's authenticated decision. [Evidence export and Reckon](evidence-export-and-reckon.md#reckon-evaluates-learned-changes-and-preserves-the-decision) defines those responsibilities. Ordinary deterministic work remains independent. The rehearsal includes release, simulated activation and forward rollback, and ends with the deterministic policy still active.

## Outcome evidence is several facts, and a reward is only a projection

An owner's committed event can close an episode without anyone transcribing it, but that is capture, not a correctness oracle. Process termination, a verifier's result, the task's acceptance, the organiser's acceptance, the owner's approval and goal satisfaction stay distinct references, and no transform or universal order turns one into another. A declared evaluation may map eligible evidence to the unit interval for one declared question, recording the evidence class, the mapping version and what it excluded; missing evidence stays missing, and any derived reward must be reproducible from the complete referenced evidence. It can never outrank the evidence or promote a proposal. The source-event mapping keeps the raw terminal category, normalisation happens only in a versioned projection, and no optimisation loop ever writes episode or outbox tables; they are read-only inputs.

## The scoring loop tunes exactly two artifacts

For A-MAC-lite, exactly two artifacts are tunable, both kept as configuration data on port 3309: the scoring configuration (half-lives, priors, the novelty and confidence thresholds and weights) and the feature map for terminal process categories. One cycle runs in eight steps:

1. **Snapshot.** Record the exact input roots, and optionally tag the store as `opt-{cycle}-pre`, an audit and replay reference and never a rollback mechanism.
2. **Propose** at most the edit budget's number of bounded edits.
3. **Evaluate** by replay on the held-out split. Inverse-propensity estimates are used only for rows whose logging-policy version and non-zero action propensity were durably recorded; deterministic logs support observed replay and bounded sensitivity analysis, never claims about unshown alternatives.
4. **Gate** the result against metrics and safety tests fixed in advance.
5. **Record** a versioned proposal together with every rejected candidate and its measured difference from the baseline on the held-out split.
6. **Review.** The responsible owner accepts or rejects; the evaluation cannot approve itself.
7. **Apply** an accepted proposal only through a separate, owner-authorised release.
8. **Resume** deterministically if the cycle was killed.

The edit budget and any decay rule belong to the immutable experiment policy and need measured justification. Every edit stays inside the scorer's full domain; an edit outside it is rejected as an invalid candidate, never clipped into a different one. The improvement loop's own settings (the edit budget, the gate metric, the split) are outside what it may edit. Keep rejected edits and their measured differences so [Reckon](evidence-export-and-reckon.md) can evaluate the edit lineage. As in SkillOpt's candidate comparison, that buffer keeps evidence of unsuccessful alternatives available rather than showing only the winning edit.

## Retrieval policy has its own optimiser, and SkillOpt is not it

Scope owns a bounded offline optimiser for retrieval: affinity, which optional routes to run and with what effort, and fusion and budget. It follows the same separation:

```text
frozen retrieval-decision evidence
  -> compare the deterministic incumbent and transparent affinity candidate
     alongside a memory-host candidate when selected
  -> Reckon corpus admission and independent evaluation
  -> Scope's retrieval-policy proposal
  -> the responsible owner's authenticated ruling
     -> reject or defer: retain the ruling and leave the active policy in place
     -> accept: Reckon preserves the responsible owner's authenticated decision
        -> Scope's policy release with a rollback anchor
        -> a separate activation decision
```

The optimiser cannot edit eligibility, required context, source facts, freshness or revocation, privacy or model-use limits, the evidence policy or split, hard budgets, the evaluator, the owner's decision interface or its own acceptance criteria. Every candidate binds its exact base policy, snapshot and evidence, including its rejected alternatives. A newly fetched paper, model or repository revision may suggest a candidate; compilation and evaluation use only the immutable inputs admitted for that run. Changed inputs require a separately identified run. Each owner supplies the outcome facts it controls. For the same question, an owner's observed outcome takes precedence over a labelled proxy such as reported use, follow-up or model judgment; different outcome questions remain separate. Counterfactual claims need the exact eligible set and propensity evidence.

SkillOpt is Pale's mechanism for evolving packages and Skills. It may consume minimised Scope evidence through Pale for a package or Skill target and never trains, selects, releases or activates Scope's retrieval policy. Scope does not call SkillOpt, CodeGraph or Reckon directly, none of them writes Scope, and a SkillOpt run in Pale's integrated flow receives only minimised semantic and use lineage through Pale's evaluation manifest. None of these loops may train or emit a model; a model-training hypothesis leaves only through the research export on [Evidence export and Reckon](evidence-export-and-reckon.md).

For Pale's own coordination, Scope keeps two proposal channels apart: quantitative changes to declared numeric policy settings, and qualitative changes to doctrine, manifests, relationships or plans. Both use immutable evidence and an evaluator policy the learner cannot edit; the owner decides first; the artifact's own owner commits and releases; and Scope records only the ruling reference and the release lineage. Scope is never the owner of Pale's policy or of any artifact it did not make.

## Every accepted change is released forward and can be rolled back forward

Restoring a retained policy requires a new decision, release record, cycle checkpoint and anchor advance. Recheck the old artifact against current permissions, scope, dependencies and compatibility; its historical digest alone cannot make it eligible. Stage it away from the active path, bind the recovery decision to the expected predecessor and activate under a new identity and fence. Preserve the failed generation, its outcomes, current revocations and committed history. Existing pinned work finishes only while its permissions and required inputs remain valid. Test permitted reuse, a changed predecessor, invalidated permission or dependency, interrupted activation and an ambiguous reply reconciled before retry. The optimiser never mutates live configuration, weights or memory items. Proposals and releases are separate immutable records, and Reckon preserves the owner's decision independently under the promotion rule.

> [!NOTE]
>
> **Record design remains implementation work.** The [field sketches](record-reference.md) must be consolidated before publication while preserving the information required by this chain. Scope needs a cycle checkpoint, its scoring and memory proposals, a release and any required equivalence evidence. The checkpoint advances through snapshotted, candidate generated, evaluated, proposals persisted and complete; restart resumes the first incomplete stage without regenerating identities or timestamps. Scope's own proposals map to their releases as follows:
>
> | Proposal | What it changes | Base it binds | How it is released |
> | --- | --- | --- | --- |
> | Scoring proposal | The scoring configuration or the category feature map | The exact base artifact and version | Scope commits the bytes and the release record atomically |
> | Memory proposal | Compaction, merge, supersession or tombstone of memory items | The sorted complete set of source items and their versions | Scope commits atomically after the semantic owner accepts |
>
> A release must carry byte-identical candidate bytes, or an owner-signed equivalence record proving a declared deterministic transformation; changed, unevaluated bytes need a new proposal, and base drift conflicts rather than rebasing. A proposal whose evaluation did not pass cannot receive an accepting decision; one proposal takes at most one accepting decision and one decision at most one release. Proposal identity is unique over the cycle, its checkpoint and input roots, the proposal identifier and the proposer's key epoch. An edit-history export for Reckon distinguishes a proposal, a decision with its preserved record, and a release. The final names and signing domains belong to the published contract definitions.

## Compaction is a proposal, never a deletion

Compaction produces a derived proposal and never destroys source lineage. Omitting or deleting an accepted item needs an owner-reviewed tombstone that keeps the minimum lineage needed for supersession, stale-use rejection and invalidating dependents; no score or model can approve that tombstone, and canonical Skills, owner statements, rulings, assignments and effect receipts are never rewritten automatically. Deletion is asymmetric: deleting a source, tombstoning an item, revoking a permission or invalidating freshness invalidates every dependent snapshot, embedding, affinity feature and cache, while deleting a snapshot or affinity creates no tombstone and changes no truth.

## Output mentions are a labelled feature, and transcripts are redacted first

Mentions in an agent's output are an optional derived feature. An [accepted use receipt](episodes-and-use.md) records the admitted caller's report, and independent execution evidence is needed to establish model-visible input. Scope never scrapes another owner's transcripts. An owner-native exporter may provide a redacted, versioned derivation joined to the full episode identity. Only the subset supported by that derivation, its exact profile reference and hash, and the source digest may populate the output-reference candidates. If either that evidence or the admitted join is missing, the field stays empty; Scope never guesses. Redaction is mandatory and fails closed: it runs before any transcript is parsed, a redaction failure aborts that transcript entirely, and no raw transcript text ever reaches Scope's store, only item references and derived features. Any learned-credit experiment must test whether mentions are a valid feature at all.

<a name="scope-instruction-improvement"></a>

## The agent instructions improve through Pale's SkillOpt

SkillOpt improves Packages and Skills; Scope's optimiser improves retrieval. The Package teaching an agent to request context, read the exact bundle and report use belongs to Pale's Package improvement path. It may use permitted, minimised Scope evidence, with redaction and a complete run identity where applicable. Pattern mining, replay, staged edits, held-out comparison and owner adoption belong to that path, including the package owner's release and the checks before an agent receives it. Scope neither stages the package nor claims an atomic change across the two stores.

## Validation is necessary and never sufficient

Every proposed artifact passes measured validation before the responsible owner reviews it, and passing never decides for that owner. Killing proposal generation before or after it appends to the ledger changes no live state and resumes deterministically; rejected, expired and superseded proposals cannot be replayed as accepted; base drift invalidates a proposal rather than rebasing it; compaction proposals keep source digests, information-loss reports and lineage; evaluation fixtures span controllers, organisations, relationships and task classes without leaking hidden scope through metrics; and deleted payload cannot be rebuilt from proposal caches, transcript derivations or diagnostics unless retention allows it. Ungated optimisation is not allowed at all.

## One command runs the offline cycle, and one owner schedules it

The offline scoring and retrieval cycle is a Scope capability, with `scope optimize` as its intended command. Weave holds its schedule at a cadence the operator selects; away-work follows Weave → Pale → execution, with Pale governing and supervising execution. Standalone Scope keeps an explicit operator command. There is no default nightly run or competing cron, launchd or systemd entry. The operator may launch the go-live rehearsal explicitly; a later schedule needs its own declared capability and permission and does not approve or activate its result.

Freeze the comparison's exact case snapshot, method, workflow, model settings, validator, output schema and execution mode. Keep the assigned path, observed provider calls, fallback, raw output and evaluation result distinct, with failures and retries included in cost and coverage. Stage replay holds upstream outputs fixed; end-to-end replay regenerates them under the candidate without live effects. Scope supplies the pinned retrieval policy and snapshot, the requested mode, and the receipt for a permitted strict fallback or a refusal when full mode is required. [Evaluation evidence](evidence-export-and-reckon.md#reckon-evaluates-learned-changes-and-preserves-the-decision), the rehearsal and the certificate govern acceptance.

Before starting or resuming a bounded offline optimisation, establish the target state, permitted observations and actions, and why another iteration can use new evidence. Inspect the actual process or session handle; an old record or timeout does not prove that it is still running. Give attempts, time, cost, rate, concurrency, stored state and effects separate budgets, with a no-progress rule, stale-work check, intervention owner, safe ending and recovery point. Reconcile an uncertain earlier effect before repeating it. Stop on lost permission, exhausted budget, an unreconciled effect or repeated failure from the same cause. Test progress, duplicate work, safe replay and shared errors between generation and judgment. Scope owns the run and its evidence. Scheduling and proposal adoption follow their separate gates.

## Go-live is a full rehearsal through rollback, done offline

Scope's compiler and one immutable, request-pinned snapshot are required for go-live, along with an offline rehearsal of the adaptive machinery. Compare the deterministic incumbent with a transparent evidence-weighted affinity and planner candidate. Include a memory-host-assisted candidate if selected and permitted by the evidence rights. Freeze the controller-, purpose- and rights-bounded evidence set, apply the same hard budgets, splits and fixtures, and keep every rejected alternative. The adaptive rehearsal then exercises Reckon's corpus admission and use, independent evaluation, Scope's proposal, the responsible owner's authenticated ruling, custody, Scope's policy release, the compatibility and readiness handshake with Pale, simulated activation and forward rollback. Prove that a Reckon outage holds up a new learned promotion while ordinary deterministic work continues, that the baseline runs without packages or packs, and that Scope and Pale release and activate independently.

Certification also requires the integrated full retrieval path with Counsel's memory host and its declared degradation, even when the policy comparison uses only model-free candidates. Standalone strict mode has its own proof without a Pale daemon. Standalone full mode links Pale's Counsel port library and calls the host selected in Scope's configuration; it must pass the host's independent processing-permission and failure checks. [Architecture](architecture.md#scope-builds-and-signs-every-answer) fixes those two routes, and [Retrieval](retrieval.md) governs artifact eligibility and fallback.

The handshake identifies both owners, deployments, immutable releases, contracts, required capabilities, scope and permitted degradation. Each owner still authorises and verifies its own activation. Bind a request to one current permitted pair through completion; a new head cannot silently replace half that pair. Test both activation orders, an old handshake reused for a new pair, activation between acceptance and reply, revocation or outage during a request, and a response from the wrong deployment or generation. Check the actual pair and separately tested standalone operation after an integration failure.

Read back the release from each intended target, checking the active identity and served bytes or behaviour separately from build status and dispatch acknowledgement. Retain the accepted starting state, intended release, attempt and independent inspection. Test a lost reply after an update, a reachable endpoint serving the predecessor and a partially inspected target set. Reconcile the original attempt before retry or rollback; a currently old state does not erase earlier success or uncertainty. Report missing targets and keep wider activation pending when required inspection is absent. The certificate below defines the evidence Scope requires.

The certificate requires deterministic rebuilds with one pinned snapshot per request; every route with stable fusion; a useful strict mode and a declared memory-host degradation; freshness and revocation fencing with no mixed heads; complete eligible-set evidence for the governed window; isolation by controller, relationship, purpose and model use; lawful deletion and explicit loss of reconstructibility; native release, handshake, independent activation and rollback; corpus admission, independent evaluation, an authenticated ruling preserved by Reckon, with no self-promotion; and the standalone and direct-owner paths intact. The learned policy stays switched off at the end, unless a later, separately authorised release and activation select it.

A single canonical, authenticated owner-ruling contract may be reached through several admitted interfaces, such as Reckon presenting the review packet or an explicit action in Buzz. Ordinary chat, task completion, a parent task being accepted and a merge in Gas Town are never rulings. Every enabled interface needs positive, negative and replay proofs, and disabled interfaces keep their fixtures so that turning one on later cannot invent semantics.

Safe endings are a deterministic bundle, an explicit no-context answer, a policy-permitted limited retrieval result with visible limitations, a refusal where context is required, a demand for a rebuild, a rejected successor, a rejected or expired proposal, a candidate waiting for Reckon, a release left switched off, a completed rollback and a decision marked unreconstructible after lawful deletion. A partial build, mixed generations, unknown authority, stale required context, a missing candidate preimage, unproved vector isolation or changed unevaluated bytes is never a successful ending. The shortcuts that stay forbidden are reading source stores or credentials from Scope; making Scope a bus, keyring, provider router, scheduler or genealogy store; ranking before eligibility or treating relevance as permission; compiling truth out of affinity or model output; treating packages, packs, SkillOpt, Reckon, Counsel or Pale as the owner of Scope's retrieval; treating a webhook, poll, Nostr delivery, watcher or cache age as truth; treating use, evaluation, a merge, a release or an event acknowledgement as settlement or activation; and claiming implementation from planning prose, filenames, research or a rehearsal.

Part of [Scope engineering](README.md).
