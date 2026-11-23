# Resources and locations

One logical resource, a spreadsheet or a report or a codebase, routinely lives in several places at once: a local folder, its owner's Drive, a client's Drive where it was shared, a shared drive, a Git commit and a folder that Drive for Desktop keeps in sync. If agents treat each of those as a separate thing they upload duplicates, edit stale copies, lose track of which version counts, and never realise that the file shared with an accountant is the same one exported locally. Scope therefore keeps one resource with many locations, lets the owner say which location is canonical, and reports drift between copies without ever repairing anything itself. Every row is Scope's derived context; the file, the Drive object, the repository and the rights to them stay with their owners.

## A resource is one thing; its locations are many

```sql
CREATE TABLE resources (
    resource_id        VARCHAR(128) PRIMARY KEY,   -- opaque, immutable, allocated in the owner's namespace
    source_owner       VARCHAR(128) NOT NULL,
    source_namespace   VARCHAR(128) NOT NULL,
    `key`              VARCHAR(128) NOT NULL,      -- human alias; may change
    resource_type      VARCHAR(32) NOT NULL,       -- spreadsheet, document, codebase, image, pdf, presentation, data, config, folder
    project_key        VARCHAR(64),
    brand_key          VARCHAR(64),
    description        VARCHAR(512),
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    semantic_owner     VARCHAR(255) NOT NULL,
    source_record_ref  VARCHAR(1024) NOT NULL,
    source_version     VARCHAR(255) NOT NULL,
    authority_class    VARCHAR(64) NOT NULL,
    lifecycle_state    VARCHAR(64) NOT NULL,
    controller_scope   VARCHAR(128) NOT NULL,
    relationship_scope VARCHAR(128),
    classification     VARCHAR(64) NOT NULL,
    provenance_refs    JSON NOT NULL,
    observed_at        DATETIME NOT NULL,
    valid_through      DATETIME,
    revision           BIGINT NOT NULL,
    supersedes_ref     VARCHAR(1024),
    deleted_at         DATETIME,
    tombstone_ref      VARCHAR(1024),
    visibility         VARCHAR(16) NOT NULL DEFAULT 'private',   -- private, internal, client, public
    FOREIGN KEY (project_key) REFERENCES projects(`key`),
    FOREIGN KEY (brand_key) REFERENCES brands(`key`),
    UNIQUE (source_owner, source_namespace, `key`)
);

CREATE TABLE resource_relationship_grants (   -- who may see a 'client' resource
    resource_id        VARCHAR(128) NOT NULL,
    controller_scope   VARCHAR(128) NOT NULL,
    relationship_scope VARCHAR(128) NOT NULL,
    purpose_ceiling    VARCHAR(255) NOT NULL,
    source_record_ref  VARCHAR(1024) NOT NULL,
    source_version     VARCHAR(255) NOT NULL,
    revision           BIGINT NOT NULL,
    authorized_at      DATETIME NOT NULL,
    revoked_at         DATETIME,
    PRIMARY KEY (resource_id, controller_scope, relationship_scope, revision),
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id)
);

CREATE TABLE git_repos (   -- one-to-one repository subtype of a codebase resource
    resource_id             VARCHAR(128) PRIMARY KEY,
    source_owner_ref        VARCHAR(255) NOT NULL,
    source_record_ref       VARCHAR(512) NOT NULL,
    source_record_sha256    CHAR(64) NOT NULL,
    source_revision         VARCHAR(255) NOT NULL,
    source_route_ref        VARCHAR(512),               -- opaque, non-secret owner route
    admission_ref           VARCHAR(512) NOT NULL,
    admission_sha256        CHAR(64) NOT NULL,
    origin_url              VARCHAR(512),               -- owner-reported remote fact, never identity
    upstream_url            VARCHAR(512),               -- for forks
    is_fork                 BOOLEAN DEFAULT FALSE,
    default_branch          VARCHAR(128) NOT NULL DEFAULT 'main',
    working_branch          VARCHAR(128),
    parent_repo_resource_id VARCHAR(128),               -- when a submodule
    submodule_path          VARCHAR(512),               -- path inside the parent repository, not a checkout path
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id),
    FOREIGN KEY (parent_repo_resource_id) REFERENCES git_repos(resource_id)
);

CREATE TABLE resource_locations (
    location_id        VARCHAR(128) PRIMARY KEY,   -- opaque, immutable
    resource_id        VARCHAR(128) NOT NULL,
    location_type      VARCHAR(24) NOT NULL,       -- local, drive, drive_sync, git_checkout, git_worktree, git_snapshot
    link_type          VARCHAR(16) NOT NULL DEFAULT 'original',
    local_path         VARCHAR(1024),
    drive_workspace_key   VARCHAR(64),
    drive_file_id         VARCHAR(128),            -- this location's own file id
    drive_target_id       VARCHAR(128),            -- for a shortcut: the file it points to
    drive_path            VARCHAR(512),
    drive_shared_drive_id VARCHAR(128),
    drive_mime_type       VARCHAR(128),
    git_repo_resource_id VARCHAR(128),             -- typed repository identity, never a slug or path
    git_path           VARCHAR(512),
    git_branch         VARCHAR(128),
    git_commit         VARCHAR(40),
    shared_with        VARCHAR(255),
    last_verified      DATETIME,
    last_modified      DATETIME,
    content_hash       VARCHAR(64),                -- owner-produced, for drift
    source_version     VARCHAR(255),               -- native version, etag or commit
    observed_at        DATETIME NOT NULL,
    valid_through      DATETIME,
    lifecycle_state    VARCHAR(64) NOT NULL DEFAULT 'active',
    deleted_at         DATETIME,
    UNIQUE (location_id, resource_id),
    UNIQUE (location_id, git_repo_resource_id, location_type),
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id),
    FOREIGN KEY (drive_workspace_key) REFERENCES workspaces(`key`),
    FOREIGN KEY (git_repo_resource_id) REFERENCES git_repos(resource_id),
    CHECK (location_type IN ('local', 'drive', 'drive_sync', 'git_checkout', 'git_worktree', 'git_snapshot')),
    CHECK (
        (location_type IN ('git_checkout', 'git_worktree', 'git_snapshot') AND git_repo_resource_id IS NOT NULL)
        OR
        (location_type NOT IN ('git_checkout', 'git_worktree', 'git_snapshot')
         AND git_repo_resource_id IS NULL AND git_path IS NULL AND git_branch IS NULL AND git_commit IS NULL)
    ),
    CHECK (
        location_type NOT IN ('git_checkout', 'git_worktree')
        OR (resource_id = git_repo_resource_id AND local_path IS NOT NULL)
    ),
    CHECK (location_type <> 'git_snapshot' OR (git_commit IS NOT NULL AND link_type = 'git_snapshot'))
);

CREATE TABLE resource_canonical_location_heads (   -- exactly one fenced head per resource
    resource_id                VARCHAR(128) NOT NULL,
    revision                   BIGINT NOT NULL,
    expected_previous_revision BIGINT,
    previous_head_sha256       VARCHAR(64),
    canonical_location_id      VARCHAR(128) NOT NULL,
    authority_ref              VARCHAR(1024) NOT NULL,
    authority_sha256           VARCHAR(64) NOT NULL,
    source_record_ref          VARCHAR(1024) NOT NULL,
    source_version             VARCHAR(255) NOT NULL,
    canonical_head_sha256      VARCHAR(64) NOT NULL,
    committed_at               DATETIME NOT NULL,
    PRIMARY KEY (resource_id, revision),
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id),
    FOREIGN KEY (canonical_location_id, resource_id)
        REFERENCES resource_locations(location_id, resource_id)
);

CREATE INDEX idx_drive_file_id   ON resource_locations(drive_file_id);
CREATE INDEX idx_drive_target_id ON resource_locations(drive_target_id);
CREATE INDEX idx_local_path      ON resource_locations(local_path);
```

A resource identifier is allocated inside the owner's source namespace and is never derived from a title, a path, a Drive filename, a repository slug or the human alias; the alias can change, and can collide across owners, without changing identity. Folders are resources too, with their own locations. A codebase becomes a repository projection only through the one-to-one `git_repos.resource_id` primary- and foreign-key join. Its project and brand associations are therefore read from the resource row and are not repeated on `git_repos`. A Git location names that same repository through `git_repo_resource_id`; checkout and worktree locations must locate the repository resource itself, while a `git_snapshot` may locate a contained resource and uses `git_path` to say where it appeared. The composite canonical-head foreign key prevents one resource from selecting another resource's location.

## Only the owner says which copy is canonical

A location never declares itself canonical. Canonicality changes only by a new, predecessor-fenced head in `resource_canonical_location_heads` whose authority and source revision can be independently resolved: revision one has no predecessor, and every successor increments by exactly one and binds the prior head's hash. Scope projects the owner's choice. It never infers canonicality from freshness, edit time, file identifier, sync state or reachability.

## The kind of link decides what a copy means

| Link type | What it is | Own file id? | Do edits reach the original? | Can it drift? |
| --- | --- | --- | --- | --- |
| `original` | The file itself, where edits happen | Yes | It is the source | No |
| `shortcut` | A Drive pointer that opens the original | Yes, its own | Opens the original | No |
| `copy` | An independent duplicate | Yes, a new one | No | Yes |
| `shared_view` | The same file seen from another user or workspace | Same as the original | Yes | No |
| `sync_mirror` | Drive for Desktop keeping a local folder and Drive in step | Same content on two surfaces | Asynchronously, not guaranteed | Yes |
| `git_snapshot` | The file frozen at a commit | Not applicable | No | Yes, behind the working tree |
| `symlink` | A local path pointing at another path | Pointer | Yes | Only if broken |

Within one provider namespace and one owner-issued identity map, the same Drive file identifier is evidence of one underlying file; it is never enough across providers, owners or unbound exports. A different identifier is evidence of a distinct provider object, not by itself proof that the content was copied. A shortcut carries its own identifier and an owner-reported target. A `sync_mirror` label never guarantees propagation and never authorises an edit; lag, conflict and failed propagation stay possible. Symlinks are resolved by the owner's filesystem exporter, which never follows a link outside its admitted root and reports loops and broken targets; Scope imports that projection and never crawls the filesystem or repairs a link.

Three synthetic situations show what the model must distinguish:

- A quarterly compliance sheet in its owner's Drive, shared with a client's workspace, has one `original` and one `shared_view` with the same file identifier. The owner decides whether either view is writable.
- An architecture document with a shortcut elsewhere and a stray copy in an old folder has one `original`, one `shortcut` with its own identifier and target, and one `copy` whose hash may diverge.
- A README held locally, in a Drive-synced folder and in Git has an `original`, a `sync_mirror` and a `git_snapshot`. The bundle reports which location the authority-backed head selects, the owner's declared mirror relation, the Git snapshot, and the applicable lag and freshness limits.

A finance workbook export requires the owning export contract's completed run and output evidence, exact workbook hash and owner's canonical head before it can be labelled `original`. For Means, one completed run record identifies the exact verified workbook bytes and the accompanying release; no second artifact-release receipt is required. Scope neither creates the export nor promotes a local file without that evidence.

## Drift is evidence, and repair belongs to the owner

When comparable owner-produced hashes disagree, Scope records drift. It never diagnoses a sync conflict, picks a winning replica or repairs anything. The repair flow always leaves Scope and comes back:

```text
Scope freshness or drift evidence
  -> a separately admitted effect by the resource owner
  -> the owner's effect receipt
  -> a new owner-issued projection or event
  -> Scope admission and an atomic generation replacement
```

A Weave schedule through Pale, or a standalone operator, may invoke Scope's read-only drift check; the owner's own process performs the drift read under its own identity and credentials, emits bounded versions and hashes as an admitted projection, and Scope compares them with the pinned canonical version and records an observation or proposal. Any repair or work item is requested separately from its owner.

| Location type | The evidence the owner's exporter supplies |
| --- | --- |
| Local | SHA-256 over the admitted bytes, plus the source revision |
| Drive | The provider object identifier and version, plus the provider checksum where one exists |
| Git | The commit and object identity, optionally a SHA-256 over normalised bytes |
| Drive sync | Separate evidence for each copy, plus the owner's mirror relation and observation time |

A provider's modified time is a freshness observation. For native Google formats, the source owner selects any normalised export profile. For a workbook, that comparison identifies each source revision, exporter, options, exact output and receipt, intended reader and calculation engine. Agree the interpretation before computing a normalised digest, including date basis, locale, time zone, precision and calculation behaviour. A filename, timestamp or provider checksum supplies neither the source revision nor an equivalence mapping.

Check file identity separately from the workbook model, saved results and recalculated output. Compare the complete file digest with its receipt; compare required sheets, order, visibility, typed cells, formulas, formats, resolved names and relationships, chart inputs and validation; read saved caches, errors, blanks and zero separately; and recalculate a disposable copy in the intended engine when the claim needs its values or display. Repacking can preserve the model while changing bytes. Test an equivalent repack, a changed formula with a plausible cached result, changed input with stale or missing output, and a date serial interpreted under a different date basis. If a required source revision, feature or reader check is missing, leave that comparison unavailable rather than claiming equivalence.

For receipt-bound append intervals, inventory every package part by path, type and digest and compare adjacent retained exports. Check intended cell, table-range and filter-range changes; if an intermediate export is missing, bound the change to the verified interval without attributing it to one append. Resolve relationship IDs with their referring attributes, owning part, type, target mode and target before accepting renumbering. Compare changed style or conditional-format rules, ranges, priorities, formulas and referenced styles separately from their observed display. Give every changed part a disposition; test harmless renumbering, the same ID with a different target and a formatting change beside a valid append. Scope records the owner's reported comparison, coverage and unresolved checks; neither equal bytes nor equivalent output changes the canonical location chosen by the owner's head.

Every change to the resource map is one expected-revision Scope transaction carrying source, provenance, supersession and tombstone state. Dolt commits or tags are made only at declared, reviewed snapshot, release, audit or rollback boundaries; ordinary mutations are not individual commits.

## Visibility is a ceiling on what a bundle may contain

The `visibility` field decides what may enter a caller's bundle. It is not permission to share anything outside Scope, which stays a decision for the resource owner and Pale.

| Visibility | Scope may return it to | Scope withholds it from |
| --- | --- | --- |
| `private` | Exactly the permitted controller scope, relationship scope and purpose | Every other scope |
| `internal` | Admitted scopes inside the owning controller | Client and foreign scopes |
| `client` | Exactly the relationships the owner granted, within the grant's purpose ceiling | Every relationship not granted |
| `public` | Public retrieval, within purpose, size and freshness limits | Deleted, revoked or otherwise restricted items |

Widening visibility needs a new owner-authorised source revision; no agent, model, score or transport event can widen it. Protective narrowing takes effect immediately, fails closed, and becomes an explicit owner update or proposal rather than a silent rewrite of the owner's policy. Visibility is enforced while the graph is being walked, not filtered afterwards, because an agent cannot un-see context once it is in its prompt; filtered nodes never enter items, diagnostics, counts, timing classes or aggregate scores.

```python
def visible_to_context(resource_id, request_scope) -> bool:
    resource = load_resource(resource_id)
    if resource.visibility == "private":
        return request_scope.matches_private_owner(resource)
    if resource.visibility == "internal":
        return request_scope.controller_scope == resource.controller_scope
    if resource.visibility == "client":
        grant = latest_grant(resource_id, request_scope.controller_scope,
                             request_scope.relationship_scope)
        return (grant is not None and grant.revoked_at is None
                and purpose_ceiling_allows(grant.purpose_ceiling, request_scope.purpose))
    if resource.visibility == "public":
        return not resource.deleted_at and request_scope.within_purpose_ceiling()
    return False
```

Content from Gazette's site exports is never physically deleted by ranking; a bundle may omit it only with an explicit omission, while an owner's deletion or revocation still propagates as a tombstone.

## Repositories are first-class resources

```sql
CREATE TABLE git_branches (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    repo_resource_id   VARCHAR(128) NOT NULL,
    branch_name        VARCHAR(128) NOT NULL,
    branch_type        VARCHAR(16) NOT NULL DEFAULT 'feature',   -- default, working, feature, upstream, release, protected
    tracks_remote      VARCHAR(255),
    last_commit        VARCHAR(40),
    last_commit_date   DATETIME,
    ahead_of_default   INT,
    behind_default     INT,
    pr_number          INT,
    pr_state           VARCHAR(16),                  -- open, merged, closed
    pr_url             VARCHAR(512),
    FOREIGN KEY (repo_resource_id) REFERENCES git_repos(resource_id),
    UNIQUE (repo_resource_id, branch_name)
);

CREATE TABLE git_worktrees (
    id                   INT AUTO_INCREMENT PRIMARY KEY,
    repo_resource_id     VARCHAR(128) NOT NULL,
    location_id          VARCHAR(128) NOT NULL UNIQUE,
    location_type        VARCHAR(24) NOT NULL DEFAULT 'git_worktree',
    branch_name          VARCHAR(128) NOT NULL,
    reported_creator_ref VARCHAR(255),               -- owner-issued actor reference, optional
    owner_event_ref      VARCHAR(512) NOT NULL,
    owner_event_sha256   CHAR(64) NOT NULL,
    created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active            BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (repo_resource_id) REFERENCES git_repos(resource_id),
    FOREIGN KEY (location_id, repo_resource_id, location_type)
        REFERENCES resource_locations(location_id, git_repo_resource_id, location_type),
    CHECK (location_type = 'git_worktree')
);
```

The fixed `git_worktrees.location_type` value is only a foreign-key discriminator: its check and composite reference prove that `location_id` names a `git_worktree` location for the same repository. It is not a second location record and carries no path, lifecycle or canonicality.

Repository identity comes only from a fresh owner-issued snapshot carrying its observation time, source version, immutable resource identity, declared remotes, branch roles and any owner-reported checkouts and worktrees. A local path, remote URL, branch label, repository name or planned rename never becomes an identity or an alias; Scope never runs `git` or `gh`, never checks `gh auth status`, never fetches and never infers a rename. A repository rename changes the mutable human alias on `resources`, not `resource_id`. Every clone or checkout is its own `git_checkout` location row; every worktree is a `git_worktree` location row referenced by `git_worktrees`; and the only physical path is `resource_locations.local_path`. Moving a checkout retires or supersedes the old location and admits a new location under the same repository resource. Neither the move nor an additional clone changes the canonical head: only a fresh owner-authorised successor head may select the new location. The remote URLs and `submodule_path` remain owner-reported repository facts, not local locations or canonicality.

Scope can answer only what the fresh snapshot supports: the repository's identity and declared fork relationship, branch roles and ahead-behind counts at observation time, owner-reported checkout and worktree activity, and which owner route produced the projection. A stale snapshot cannot rename a resource, add or retire a location, move the canonical head or replace a newer generation. Scope cannot answer which account or credential to use, and it has no universal staleness threshold for worktrees; freshness is judged against the owner's published policy.

Part of [Scope engineering](README.md).
