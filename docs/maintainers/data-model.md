# Data model

Scope's accepted state is a typed graph of owner projections, held in memory for traversal and persisted in Dolt, and every node, edge and row carries enough provenance to say exactly which owner record, at which revision, it came from. The model is deliberately conservative: nothing becomes a node or an edge because a name, an email address or a path happens to match, and the learned sense of what is useful together is kept entirely outside the graph. The in-memory graph is only ever rebuilt from accepted durable state; how that is guaranteed is on [Durability and recovery](durability-and-recovery.md).

## Nodes are source-qualified projections

The node types are legal entities, workspaces, domains, email lookup aliases, brands, projects, people, resources, Git repositories, content from Gazette's site exports (articles, collections, journeys) and the authors of that content. A site author is its own node type, never a person: an author projection connects to an existing person only when the site export carries the exact admitted identity-subject reference and its hash. Scope never synthesises a fallback person.

Every node is a projection of an owner's record, qualified by its source. The graph module's node and edge types carry an exact source-provenance reference and hash: the admitted adapter contract, the source owner, the source artifact or generation and the source record. Adapters are named in an open, versioned registry; a bare adapter string is never trusted, and the set of sources is not a closed list.

## Edges carry the owner's meaning, and a label is only display

A semantic edge is a namespaced, directional relationship owned by a named owner, carrying that owner's record reference and hash, the source revision, validity, classification, visibility, admission and provenance. The human-readable label on an edge is display only. Traversal and ranking scores are derived metadata and can never change what a relationship means. Document-link classes, an owner's business relationships, site content edges and Scope's own relations live in separate namespaces; an edge with unknown or incomplete provenance fails closed.

Organisational vocabulary (verticals, groups and trees, leadership, roles and occupancy, service and account relations, native product relations) enters only as admitted projection from the organisational-translation design Pale owns, each relation source-qualified and namespaced. Scope may derive bounded current context, contradiction, staleness and relevance over the authorised slice. It may not infer a missing tree, merge two organisations because they look alike, create a role, delegation or contract, widen disclosure, or turn its own edge into organisational truth.

## Three kinds of relation stay apart

Scope keeps three kinds of relation separate because they carry different meanings and can change under different authority. Retrieval affinity names the disposable association used for retrieval; it is not an owner-issued relationship or an admitted semantic assertion.

| Relation | What it is | How it changes |
| --- | --- | --- |
| Owner structure and genealogy | Owner-issued placement, occurrence, lineage and frontier facts, including Pale's genealogy, its append-only history of what work relied on, what changed and what followed | Only through its owner or Pale; Scope never learns or rewrites it |
| Scope's context relations | Derived assertions Scope admitted under source evidence, provenance, freshness, confidence and lifecycle | Through a Scope semantic transaction |
| Retrieval affinity | A disposable sense that two already eligible items tend to be useful together, isolated by data owner and the role, project or relationship allowed to reuse it | Changes only retrieval quality or speed; never persisted as a semantic edge |

Affinity follows the explicit-edge reuse rule on [Retrieval](retrieval.md). It may say two items are associated for a declared query or purpose profile. Without separately admitted causal evidence it may never say that retrieving one caused an outcome. Deleting it must leave the first two kinds untouched; if it does not, the implementation has built a competing truth store.

## Every item carries one envelope

Every semantic item records its semantic owner, ordered and bounded source references with versions and content digests, authority class, lifecycle namespace and state, provenance, classification, visibility, observed time and valid-through time, freshness policy, revision, supersession, contradiction links, deletion and tombstone state, and any derivation rule or model version. Scope preserves the difference between evidence, observation, inference, proposal, an owner-accepted statement, an assignment, an execution result and a verified outcome; none is silently promoted into another.

The domain tables below are payload indexes inside that envelope, not independent authorities. A physical schema joins each payload row to its envelope and rejects an orphan row.

## Email is a lookup alias, never an identity

An email address is an exact, scoped lookup alias. Matching an address, a display name, a domain, a slug, a social handle, a Git account or a local key never creates a subject and never authorises traversal. A lookup reaches another node only through an independently admitted owner relationship that the caller may see. The `is_send_as` flag on an alias is a descriptive projection of the owner's configuration and never effect authority.

## Five migrations build the store

| Migration | Tables |
| --- | --- |
| V001 core entities | `legal_entities`, `workspaces`, `domains`, `email_identities`, `brands`, `projects`, `project_domains` |
| V002 workspace projections | `workspace_projection_memberships`, a namespaced projection class with owner provenance and no provider or effect flags |
| V003 context evidence | `context_scores`, `telemetry_events`, `_daemon_meta` |
| V004 people | `people`, `people_affiliations`, `people_landmarks`, `people_projects`, `project_context`, `workspace_context` |
| V005 resources | `resources`, `resource_relationship_grants`, `git_repos`, `resource_locations`, `resource_canonical_location_heads`, `git_branches`, `git_worktrees` |

The score and telemetry tables are on [Scoring](scoring.md), the resource and Git tables on [Resources and locations](resources-and-locations.md), and `_daemon_meta` on [Durability and recovery](durability-and-recovery.md). [Episode revisions and heads](episodes-and-use.md) require a later migration after the execution identity and contracts are selected. Provider accounts and credentials have no table anywhere, and no empty migration may stand in for one. File, Drive and repository locations exist only in the resource model; there are no separate folder, document or filesystem-index tables.

If a separately authorised migration encounters experimental old location tables, it must account for every row as transformed, rejected, tombstoned or deliberately retained, and retain a removal receipt before retiring the tables. A silent table rename or continued dual write cannot bypass that disposition.

### V001 and V002: who and what exists

The source specification supplied only the column list for `workspace_projection_memberships`. Its SQL types below follow V001's conventions and become authoritative only when the numbered migration sets them.

```sql
CREATE TABLE legal_entities (
    `key`          VARCHAR(64) PRIMARY KEY,
    name           VARCHAR(255) NOT NULL,
    type           VARCHAR(64) NOT NULL,   -- Individual, PrivateLimited, ForeignCompany, ...
    jurisdiction   VARCHAR(16)
);

CREATE TABLE workspaces (
    `key`                 VARCHAR(64) PRIMARY KEY,
    controller_scope      VARCHAR(128) NOT NULL,
    source_owner_ref      VARCHAR(255) NOT NULL,
    source_record_ref     VARCHAR(255) NOT NULL,
    source_record_sha256  VARCHAR(64) NOT NULL,
    source_revision       VARCHAR(255) NOT NULL,
    source_route_ref      VARCHAR(512),   -- opaque, non-secret owner route; never a credential or config path
    description           TEXT,
    admission_ref         VARCHAR(255) NOT NULL,
    admission_sha256      VARCHAR(64) NOT NULL
);

CREATE TABLE workspace_projection_memberships (
    workspace_key         VARCHAR(64) NOT NULL,
    projection_class_id   VARCHAR(128) NOT NULL,   -- namespaced
    source_owner_ref      VARCHAR(255) NOT NULL,
    source_record_ref     VARCHAR(255) NOT NULL,
    source_record_sha256  VARCHAR(64) NOT NULL,
    source_revision       VARCHAR(255) NOT NULL,
    admission_ref         VARCHAR(255) NOT NULL,
    admission_sha256      VARCHAR(64) NOT NULL
);

CREATE TABLE brands (
    `key`              VARCHAR(64) PRIMARY KEY,
    legal_entity_key   VARCHAR(64) NOT NULL,
    name               VARCHAR(255) NOT NULL,
    description        TEXT,
    FOREIGN KEY (legal_entity_key) REFERENCES legal_entities(`key`)
);

CREATE TABLE domains (
    fqdn           VARCHAR(255) PRIMARY KEY,   -- getharsh.in, causality.in, ...
    workspace_key  VARCHAR(64) NOT NULL,
    brand_key      VARCHAR(64),
    is_primary     BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (workspace_key) REFERENCES workspaces(`key`),
    FOREIGN KEY (brand_key) REFERENCES brands(`key`)
);

CREATE TABLE email_identities (
    `key`                 VARCHAR(64) PRIMARY KEY,
    controller_scope      VARCHAR(128) NOT NULL,
    source_owner_ref      VARCHAR(255) NOT NULL,
    source_record_ref     VARCHAR(255) NOT NULL,
    source_record_sha256  VARCHAR(64) NOT NULL,
    normalized_address    VARCHAR(255) NOT NULL,
    domain_fqdn           VARCHAR(255) NOT NULL,
    subject_ref           VARCHAR(255),   -- optional exact admitted subject
    subject_sha256        VARCHAR(64),    -- required with subject_ref
    purpose               VARCHAR(32) NOT NULL,
    is_send_as            BOOLEAN DEFAULT FALSE,   -- descriptive only
    UNIQUE (controller_scope, source_owner_ref, normalized_address),
    FOREIGN KEY (domain_fqdn) REFERENCES domains(fqdn)
);

-- No controller_scope column: one instance serves one controller.
CREATE TABLE projects (
    `key`        VARCHAR(64) PRIMARY KEY,
    brand_key    VARCHAR(64),
    description  TEXT,
    FOREIGN KEY (brand_key) REFERENCES brands(`key`)
);

CREATE TABLE project_domains (
    project_key  VARCHAR(64) NOT NULL,
    domain_fqdn  VARCHAR(255) NOT NULL,
    PRIMARY KEY (project_key, domain_fqdn),
    FOREIGN KEY (project_key) REFERENCES projects(`key`),
    FOREIGN KEY (domain_fqdn) REFERENCES domains(fqdn)
);
```

The V001 entity rows deliberately carry no filesystem, Drive or repository location. A project is a semantic project projection and a domain is an owner-issued domain projection; neither becomes a path registry. A project's documents, codebase and data folders are `resources` associated through `project_key` or `brand_key`. In V005, a repository projection is the one-to-one subtype whose primary and foreign key is that codebase resource's immutable `resource_id`; its remotes and owner snapshot facts live in `git_repos`, while every checkout, clone, worktree and Git snapshot is a typed `resource_locations` row. Checkout and worktree tables refer to those location rows and carry no path of their own. Only an authority-backed `resource_canonical_location_heads` successor can select a location, so a repository rename, path move or additional clone changes neither resource identity nor canonicality by observation alone. The optional `source_route_ref` on a workspace is an opaque route back to the owner's admitted snapshot, not a filesystem or configuration path. The historical `website_repo`, `github_org`, `github_repo`, `repo_path`, `plan_dir` and `data_dir` columns are therefore not carried into the target migrations, and no compatibility alias replaces them.

Every `*_ref` and `*_sha256` pair is present together or absent together. Initial legal-entity context is imported only from the original legal or corporate authority, or through an owner-selected finance projection that keeps those exact source references. A calculation result or its signature establishes neither the underlying legal identity nor a contract, bank or filing status; [Means run projections](source-imports.md#each-source-reaches-scope-through-its-owner) keep those original authorities distinct.

### V004: the private mental model

These tables hold an owner's private understanding of people, projects and working environments. Communication preferences help shape a draft; project purpose, priority and energy help explain what needs attention; an environment's decision and confidentiality practices help interpret the work. These descriptions grant no permission to send, share, schedule, spend or assign work. Actual authority remains a reference and hash to the responsible owner's policy, never an editable preference flag.

For example, an agent may draft a short decision update for one stakeholder and technical detail for another, while following the same confidentiality policy. Sending each note needs separate admission. A candidate ordering of projects may account for priority and available energy, but it does not assign a deadline, budget or accepted priority. Affiliations remain separate sourced relationships with their own periods; no person has one global relationship.

Real notes and relationships stay in the controller's private runtime data, outside Git, public configuration and source fixtures. They reach a processor only for an authorised purpose within the controller, relationship and classification boundary, with disclosure recorded. Enforce visibility before reading bytes and during traversal. Free notes never become a client's accepted fact. Compaction may propose a leaner view but cannot erase accepted entries or provenance; a Dolt revision establishes a change, while attribution requires its signed issuer or owner audit reference.

```sql
CREATE TABLE people (
    `key`                  VARCHAR(64) PRIMARY KEY,
    subject_owner_ref      VARCHAR(255) NOT NULL,   -- every person binds one admitted subject
    subject_record_ref     VARCHAR(255) NOT NULL,
    subject_record_sha256  VARCHAR(64) NOT NULL,
    name                   VARCHAR(255) NOT NULL,
    primary_email_identity_key VARCHAR(64),         -- optional lookup alias, not authority
    formality          VARCHAR(16) DEFAULT 'normal',   -- formal, normal, casual
    preferred_channel  VARCHAR(32),                    -- email, chat, call, ...
    language_style     VARCHAR(64),                    -- "concise bullets", "hindi-english mix"
    response_time      VARCHAR(32),                    -- "expects quick", "async ok"
    trust_level        VARCHAR(16) DEFAULT 'medium',   -- descriptive only
    communication_policy_ref    VARCHAR(255),  communication_policy_sha256 VARCHAR(64),
    sharing_policy_ref          VARCHAR(255),  sharing_policy_sha256       VARCHAR(64),
    scheduling_policy_ref       VARCHAR(255),  scheduling_policy_sha256    VARCHAR(64),
    notes              TEXT                            -- private context, never a client fact
);

CREATE TABLE people_affiliations (
    `key`                      VARCHAR(64) PRIMARY KEY,
    person_key                 VARCHAR(64) NOT NULL,
    affiliation_subject_type   VARCHAR(64) NOT NULL,   -- legal entity, brand, project, team, body, client, informal
    affiliation_subject_ref    VARCHAR(255) NOT NULL,
    affiliation_subject_sha256 VARCHAR(64) NOT NULL,
    relationship_type_id       VARCHAR(128) NOT NULL,  -- namespaced owner term
    owner_relation_ref         VARCHAR(255) NOT NULL,
    owner_relation_sha256      VARCHAR(64) NOT NULL,
    valid_from                 TIMESTAMP NULL,
    valid_until                TIMESTAMP NULL,
    membership_kind            VARCHAR(64),            -- display only
    role                       VARCHAR(255),           -- role in this affiliation only
    FOREIGN KEY (person_key) REFERENCES people(`key`)
);

CREATE TABLE people_landmarks (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    person_key     VARCHAR(64) NOT NULL,
    date           DATE NOT NULL,
    summary        TEXT NOT NULL,                  -- "first meeting, discussed architecture"
    significance   VARCHAR(16) DEFAULT 'normal',   -- high, normal, low
    FOREIGN KEY (person_key) REFERENCES people(`key`)
);

CREATE TABLE people_projects (
    person_key              VARCHAR(64) NOT NULL,
    project_key             VARCHAR(64) NOT NULL,
    relationship_type_id    VARCHAR(128) NOT NULL,
    owner_relation_ref      VARCHAR(255) NOT NULL,
    owner_relation_sha256   VARCHAR(64) NOT NULL,
    role_in_project         VARCHAR(128),           -- display only
    PRIMARY KEY (person_key, project_key),
    FOREIGN KEY (person_key) REFERENCES people(`key`),
    FOREIGN KEY (project_key) REFERENCES projects(`key`)
);

CREATE TABLE project_context (
    project_key        VARCHAR(64) PRIMARY KEY,
    priority           VARCHAR(16) NOT NULL,   -- critical, high, medium, low, parked
    category           VARCHAR(32) NOT NULL,   -- revenue, product, research, infra, personal, client_delivery
    engagement_type    VARCHAR(32),            -- founder, consultant, employee, advisor, maintainer, contributor
    commercial_context_ref     VARCHAR(255),
    commercial_context_sha256  VARCHAR(64),
    commercial_context_summary TEXT,           -- classified projection; the owner keeps the facts
    long_game          TEXT,                   -- what this project is ultimately for
    status_summary     TEXT,                   -- sourced projection, never ledger authority
    energy             VARCHAR(16) DEFAULT 'normal',   -- high, normal, low, drained
    agent_guidance_ref     VARCHAR(255),
    agent_guidance_sha256  VARCHAR(64),
    agent_guidance_summary TEXT,
    sensitivity        VARCHAR(16) DEFAULT 'normal',   -- high, normal, internal-only
    FOREIGN KEY (project_key) REFERENCES projects(`key`)
);

CREATE TABLE workspace_context (
    workspace_key      VARCHAR(64) PRIMARY KEY,
    your_role          VARCHAR(128),   -- "CTO consultant", "founder", "team lead"
    engagement_terms   VARCHAR(64),    -- consultant, employee, advisor, founder
    culture_formality  VARCHAR(16) DEFAULT 'normal',
    decision_style     VARCHAR(32),    -- "founder decides", "consensus"
    communication_norm VARCHAR(32),    -- "async first", "weekly syncs"
    confidentiality_policy_ref    VARCHAR(255),
    confidentiality_policy_sha256 VARCHAR(64),
    boundary_summary   TEXT,           -- explanatory; the policy reference enforces
    sensitivity        VARCHAR(16) DEFAULT 'normal',
    notes              TEXT,
    FOREIGN KEY (workspace_key) REFERENCES workspaces(`key`)
);
```

A person has no single global relationship; each affiliation carries its own qualified, owner-sourced relation, and a legal-entity affiliation may point at the matching `legal_entities` node while any other kind of organisation stays its own subject class. Priority, status, energy, commercial and communication-preference projections must carry an explicit valid-through time; when it passes they drop out of normal resolution until a new admitted revision arrives. Free-form notes and guidance summaries are untrusted data, never instructions an agent should execute. Only synthetic fixtures or exactly admitted person subjects and project contexts may seed these tables; a site author, email, display name, domain or account is a planted negative fixture that must never produce a person.

## Dolt must be proved to support the shapes Scope uses

The five migration shapes use auto-increment keys, composite primary keys, foreign keys with cascade, check constraints, the native JSON type and datetime timestamps, all of which Dolt supports. They never use partial indexes, which Dolt does not support. That is a design-level reading, not a compatibility proof. Compatibility counts as verified only when the exact numbered SQL files run against the pinned Dolt version, their catalogue and hashes are inspected, rollback and replay tests pass, and immutable receipts are recorded. The migration runner that does this is on [Durability and recovery](durability-and-recovery.md).

Part of [Scope engineering](README.md).
