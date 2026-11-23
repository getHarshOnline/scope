# Admission and trust

Admission establishes who may ask Scope for context and whose source snapshots it may accept. In [integrated mode](architecture.md#scope-builds-and-signs-every-answer) Pale admits the caller and Scope verifies the bound evidence. Standalone Scope keeps its own authority store of grants, trust records and revocations, protected against rollback; provider credentials stay outside Scope in either mode.

Scope checks admission before parsing a request body or reading a snapshot, and each signed result identifies the exact authority frontier checked: the permission and revocation state used for that decision. A shared operating-system user, local socket, role string, repository slug or workspace label supplies none of that authority.

## Authority at each boundary

| Participant | Owns | Must never own |
| --- | --- | --- |
| The resource owner and its native helper | Choosing the provider account, resolving the secret, running the native command, the effect receipt | Scope's admission or derived truth |
| Pale | The integrated admission that binds the verified principal, controller, optional relationship scope and declared path | Provider secrets or source meaning |
| Scope | Validating projections, provenance, freshness, the semantic ledger, use and episode evidence, its own writer fence | An account registry, a credential reference, a shell-ready environment, a live provider command or effect |
| An orchestrator or execution owner | Its own run, attempt and worker state | Scope's records or another owner's credentials |
| Claude Code or Codex | Terminal execution inside the admitted session | Switching accounts or bypassing admission |

## No credential ever crosses into Scope

A provider secret is resolved by the resource owner or its helper, injected only into one admitted source or tool process, and never enters Scope, a bundle, a diagnostic event, an error, a log, a receipt or a proposal. What crosses is only the owner's secret-free projection, bound to its owner, record, revision, hash and admission. Scope exposes no credential lookup, token minting, environment bundle, provider command or effect endpoint; there is no `cred get`, `gws-command`, `gh-command`, upload, send, publish or schedule surface.

In integrated mode Pale admits the caller and capability, selects the declared credential reference and verifies its runtime binding. The owner or its helper resolves the secret straight into the admitted process. Pale's control records and credential identifiers stay outside Scope. In standalone mode, Scope checks retrieval under its own caller grants. For a [source import](source-imports.md#admission-comes-before-parsing), it verifies the enrolled owner's active trust and either the owner's signature or the named adapter's signature with its owner-signed delegation. The owner still authorises the source read and controls credential resolution. Federation keys and provider credentials have separate roles.

A source route reference is an optional, opaque, non-secret reference the source owner issues so that freshness and provenance can be read across successive projections. It is not an account, a credential or credential-store locator, a shell command, environment fragment or configuration path, an execution-path identity, or a scope or traversal grant. Only the owner dereferences it; Scope may compare it and return it within the projection's visibility, and cannot use it to call the provider.

Every schema is scanned for secret material. Revoking an owner's or Pale's admission binding blocks later source calls and marks dependent projections stale; it does not erase evidence of earlier lawful use. A read binding for one source can never be widened to another source, account, effect or controller.

No bootstrap, migration or Scope process may create, move, read or delete credential values in any private data folder, treat such a folder as Scope's runtime root, or infer source authority from its layout; any quarantine, rotation, migration or deletion there needs separate owner and security authorisation recorded against a secret-free inventory.

## Integrated admission: Pale's envelope binds the request

In a Pale deployment the caller's request is Pale's caller-signed common request envelope, whose body is Scope's exact request. A returned bundle binds that request's reference and hash in its Pale admission binding; a use receipt is emitted only after Scope accepts the report and binds that exact report request. For a federated request the binding also names the destination's separate federation admission, and the inner request never refers to the outer peer envelope. The standalone grant and admission records are absent in this mode.

## Standalone admission: a grant, then a signed request

Every standalone resolve, bundle read or use report arrives as an exact pair: a request admission signed by the granted caller, and the operation body it binds. The grant is issued by Scope's admission authority, is non-transferable, lasts thirty days unless renewed, and is checked against the append-only revocation head; revocation is the main ongoing control. A broad controller-private grant may be issued once within its exact declared ceiling, and every request still needs its own signed admission. Scope requires the caller, operation, role, purpose, classification and complete scope to be the same as or narrower than the grant, and the operation body's hash to match, before it parses anything. An empty relationship list admits only non-relationship scope; an empty list never means unbounded.

Standalone requests are deduplicated durably on the signer, key epoch and request identifier. Check the current caller's permission to read a saved outcome, then reconcile the original request before attempting a fresh write. An exact completed replay returns the earlier disposition even after the state advances; a pending request follows its original recovery and visibility rules. Reuse with a changed grant, operation, body, scope, times or signature fails closed. Test a lost reply followed by a later revision, changed and cross-scope reuse, concurrent attempts and revoked access to the saved result. [Source imports](source-imports.md#every-disposition-gets-exactly-one-receipt-pair) distinguishes replay from a new admission for the same committed import.

## Revocations form one chain per subject

A revocation is the only way to retire a standalone grant or an import delegation; issuance records never gain a revocation field. The first revocation for an authority, subject kind and subject has epoch one and no predecessor; each successor increments by exactly one and binds the prior reference, hash and epoch. The authority store advances one head by compare-and-swap, and two different records at the same epoch are quarantined. The revoker must be the subject's own issuing authority.

Every signed result that depends on a standalone grant or import delegation carries an authority frontier naming exactly which revocation head was checked. Epoch zero means no revocation existed and forbids the revocation fields; a positive epoch requires them, resolved to the unique accepted head. A successful result proves the subject was unrevoked at the recorded check time, and if a revocation becomes effective later, the bundle's validity cannot extend beyond it. A rejection for revocation may keep the checked frontier in its failure receipt but can never carry an accepted disposition.

## One mutation request writes the authority store

The standalone authority store (caller grants, the service-output signer, resource-owner trust, import delegations and revocations) is written only through one request and receipt pair. Each candidate record stays its issuer's signed fact; the request only asks Scope to admit that exact, ordered set. Its `candidate_set_sha256` is SHA-256 over the complete ordered `candidate_records` array under Scope's [canonicalisation contract](contracts.md). Every affected head and the authority-checkpoint head appears once in the expected heads, an absent initial head is an absent triple rather than a sentinel, and the caller never supplies the next checkpoint: Scope computes, signs and co-commits it and returns it only in the receipt. The command-line authority operations are thin clients of these operations and keep no vocabulary of their own.

| Operation | Candidate records, in order |
| --- | --- |
| Bootstrap the authority | A generation-one admission authority root |
| Admit a caller grant | One caller grant |
| Register the service-output signer | One generation-one active signer record with admission-root authorisation and fresh-key proof |
| Rotate the service-output signer | One normal-rotation signer record with admission-root authorisation, prior-key authorisation and fresh-key proof |
| Recover the service-output signer | One recovery signer record with admission-root or recovery-policy authorisation and fresh-key proof |
| Retire the service-output signer | One terminal retired record with admission-root authorisation, and the active key's authorisation where available |
| Register a resource owner | One recovery policy, then a generation-one trust record |
| Rotate a resource owner | One normal-rotation trust record |
| Recover a resource owner | One unconsumed recovery proof, then one recovery trust record |
| Update a resource owner's policy | One successor recovery policy, then one policy-update trust record |
| Revoke a resource owner | One terminal-revocation trust record |
| Admit an import delegation | One delegation |
| Revoke an authority | One revocation |

No arbitrary batch is valid: duplicate, missing, extra, reordered or incompatible candidates fail before anything changes, and a supplied checkpoint is an invalid extra record. The request, the candidates, every head advance, the new checkpoint, the disposition and the receipt commit in one transaction. `committed` requires the exact admitted record set, the transitioned heads and the checkpoint; `rejected` and `conflict` require both arrays empty and no checkpoint. Exact replay returns the byte-identical original receipt; changed reuse, stale heads, wrong issuers, incomplete support records and reference mismatches fail closed.

## Bootstrap happens once, offline, on an empty store

Bootstrap is a one-shot offline use of the same request and receipt, never a call through a running daemon and never a repair shortcut. The daemon is stopped; the store has no bootstrap marker, root, checkpoint or independent minimum; the request's signature must verify against a separately configured one-use operator key fingerprint; the candidate root is self-signed and may use a different key. One transaction commits the root, the epoch-one checkpoint Scope creates, the request's disposition, the bootstrap marker and the receipt; only then does the command advance the independent minimum, idempotently recovering that second step before the daemon opens. Exact offline replay returns the original receipt after verifying the complete state; changed reuse, partial state, an existing root or marker, a wrong operator key or an unanchored checkpoint fails closed.

The root is epoch one with a sorted, non-empty set of permitted record kinds and a valid self-signature. It is a verifier for standalone admission only: not a Pale principal, not a resource-owner key and not a credential. Rotating or recovering the root is blocked until a successor record and proof policy is defined, so the root carries no expiry until then, and reinstalling bootstrap is not a substitute. The operator's bootstrap key, the admission root and each resource owner's trust root are three different authorities.

> [!NOTE]
>
> **Proposed.** Standalone recovery would use one successor key held by the owner, preserving the order of trust records and revocations, the history linking each key to its predecessor, and existing scope limits. This remains a builders' proposal for a later owner decision as Scope approaches operation. The proposal supplies neither the missing admission-root successor contract nor permission to bypass a resource owner's recovery proof.

## A resource owner's trust has its own lineage

On an empty machine the operator bootstraps the admission root first, and may then register a resource owner only with a generation-one, self-signed trust record whose key fingerprint matches separately configured owner trust material. The operator's signature admits those bytes; it cannot sign as the owner or widen the owner's namespaces, scopes or classification. No import is admissible until the owner resolves to one active, unexpired trust head covering the exact namespace and scope.

The trust record's transitions are exact. The initial record is revision one and key epoch one, with no predecessor, recovery proof or old-key signature, and one new-key signature. A normal rotation increments both revision and key epoch once, binds the active predecessor, and is signed by both the old and the new key over the same digest. A recovery increments both, needs the new-key signature and one unconsumed threshold proof under the prior record's recovery policy, and forbids an old-key signature. A policy update increments the revision, keeps the active key, and binds the new owner-signed recovery policy. A revocation is terminal, signed by the active key, and nothing later may become active.

A recovery policy lists sorted, duplicate-free eligible signers and a threshold within bounds, and is signed by the owner's active key; policy epochs increment once and bind their predecessor, and equivocation, skipped epochs or a policy signed by any other key fail. A recovery proof binds one prior trust record, the exact next key and epoch, the policy and a nonce, and each signer signs its digest; Scope reserves that tuple atomically, so exact replay returns the earlier transition and any second or changed use conflicts. Wrong mode or signers, a stale policy, a missing configured fingerprint, a skipped epoch, widened scope, same-epoch equivocation or a reused proof all fail closed.

## Checkpoints make rollback impossible to hide

Every authority mutation creates the next hash-linked authority checkpoint in the same transaction. Its heads root is SHA-256 over the canonical sorted array of the active admission root, every grant and delegation with its revocation head, the active or final retired service-output signer, every resource-owner trust head, and every consumed recovery proof, each entry carrying its record class, scope key hash, head reference and hash, epoch or revision and disposition. Entries sort by `(record_class, scope_key_sha256)`, `covered_subject_count` equals the array's length, and the checkpoint itself is excluded. The first checkpoint is epoch one and is co-committed with bootstrap; each successor increments once and binds its predecessor.

Authority is only one domain that must not roll back. Every externally visible durable change to Scope's semantic, import, episode or use state also co-commits the next internal durable-state checkpoint, whose roots cover the writer generations, import-profile heads, source and semantic namespace heads, semantic tombstones, the import inbox, the use, episode and owner-event frontiers, the site-export generation and complete-set policy heads, and the migration head. The first durable-state checkpoint has sequence one, no predecessor, the bootstrap authority checkpoint and empty semantic/frontier roots. Each later checkpoint increments the sequence exactly once per transaction and binds its predecessor. An authority mutation co-commits both checkpoints, and the durable-state checkpoint points at the new authority frontier.

Rehearse a restore and an interruption between the database commit and the independent anchor update. Scope's two checkpoint pairs use the [anti-rollback anchor](durability-and-recovery.md#an-anchor-outside-the-backup-domain-stops-rollback), whose minimum must survive database backup, whole-machine restore and cloning independently. A co-restored copy cannot establish that minimum. Cover revoked grants, consumed proofs, deleted items and earlier site-export generations, including equal checkpoint coordinates with different bytes. Complete only a verified pending advance; a lost acknowledgement must not cause another mutation or receipt.

## Admission and trust must be proved hostile-first

For both integrated and standalone paths, trace each identity mapping to its issuer, source and target namespaces, supporting record, revision, validity and revocation state. A valid signature or familiar role label does not establish the local assignment. Before either path is callable, tests must show that a forged role, a shared-user caller, a wrong principal, controller, relationship, purpose or classification is denied before any source byte is read; that standalone grant transfer, replay, expiry and revocation fail as they should; that substituting a Pale binding or hash fails; that a projection carrying a credential reference, configuration path, shell fragment or unbound route is rejected without partial change; that a route reference swapped across owners or admissions is rejected; and that concurrency never reveals another scope's existence through content, counts, errors or timing. Reassign or revoke a binding between selection and use: earlier acts retain their attribution while the successor gains no permission by implication. Check permission to read separately from permission to act. The full list is on [Acceptance tests](acceptance-tests.md).

Part of [Scope engineering](README.md).
