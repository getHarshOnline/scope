# Scope engineering

Scope's architecture separates acquiring source material, selecting context and recording its use. Source owners supply secret-free snapshots; Scope keeps the accepted projections in its own Dolt store and answers permitted requests with bounded bundles it signs itself. Scope's design uses a Rust daemon. The [developer introduction](../index.md) explains how this context lets a new session continue the work with its history and purpose intact.

## What exists in code today

The `scope` repository contains the Rust kernel crate, an empty library that the design's modules build into. It builds without sibling checkouts. The repository's [development guide](../development.md) owns the build commands and layout, including the separate research paper. [Contracts](contracts.md) identifies what must be published before consumers can integrate.

## How the parts fit

The diagram shows the integrated import and retrieval path through Pale, outside an execution binding.

```mermaid
flowchart TB
  subgraph Owners["Source owners"]
    O1[repositories]
    O2[Google Workspace]
    O4["site owner signs the export of Gazette's compiled knowledge"]
    O5[Gas Town]
    O6[owner-native research]
  end
  O1 & O2 & O4 & O5 & O6 -->|secret-free snapshots, through Pale| IMP[import: admit, stage, verify, swap one generation]
  IMP --> LED[(Scope's accepted state in Dolt, port 3309)]
  LED --> COMP[off-path compiler]
  COMP --> SNAP[frozen snapshot]
  REQ[request admitted by Pale] --> WALL[eligibility wall]
  SNAP --> WALL
  WALL --> ROUTES[exact, keyword, graph, optional vector] --> FUSE[fusion and budget] --> DEC[decision evidence] --> BUN[signed bundle]
  BUN --> READ[exact signed bundle read-back]
  BUN --> USE[caller's use report and Scope's receipt]
```

An owner's helper reads its source with its own credentials and hands over a secret-free snapshot. Scope admits it and swaps the namespace to one new generation. Away from live traffic the compiler freezes the accepted state, released policy and permission slice into one snapshot. An admitted request pins that snapshot, passes eligibility and runs the permitted routes. Scope fuses and trims the results to budget, records its decision and signs the bundle.

Means performs calculations from owner-held facts; the owner's workspace selects permitted inputs and retains the run records. An owner-selected reference or projection from those runs enters through that owner's snapshot contract, as [Contracts](contracts.md#who-may-consume-scope) explains. Means keeps no store of its own for Scope to import.

Resolving, reading and reporting use each have independent contracts. An [execution-bound handoff](episodes-and-use.md#an-episode-is-opened-before-resolve-and-bound-once-to-its-handoff) opens its episode before resolve and requires a separate binding to the execution owner's evidence. That path waits on the episode issuer. [Offline improvement](improvement-and-go-live.md) uses evidence admitted for the experiment and follows its own ruling and release gates.

## Which page answers which question

**How it is put together.** [Architecture](architecture.md) holds the boundary, the three paths, the crates and modules, storage and transports. [Data model](data-model.md) holds the graph, the item envelope and every table. [Resources and locations](resources-and-locations.md) covers one file living in many places.

**What it exchanges.** [Contracts](contracts.md) covers publication, signing and the record families, [Record reference](record-reference.md) the available field sketches and remaining gaps, and [Admission and trust](admission-and-trust.md) who may call and whose snapshots count. [Source imports](source-imports.md) explains how a snapshot becomes visible and what each source adapter accepts.

**How it answers.** [Retrieval](retrieval.md) covers the order of checks, the routes, the frozen snapshot and the falsifiers, and [Scoring](scoring.md) A-MAC-lite and telemetry. [Episodes and use](episodes-and-use.md) covers exact bundle read-back, reports of use and the deferred execution-bound path.

**How it stays honest.** [Durability and recovery](durability-and-recovery.md) covers crashes, fences, the anti-rollback anchor, startup and migrations. [Improvement and go-live](improvement-and-go-live.md) covers how anything may improve and the go-live rehearsal. [Evidence export and Reckon](evidence-export-and-reckon.md) covers research exports and Reckon's roles, [Diagnostics](diagnostics.md) the local diagnostic stream, and [Acceptance tests](acceptance-tests.md) everything that must be proved.

**Where to contribute.** [Development](../development.md) connects each kind of change to its implementation home and checks.

## How Scope meets its siblings

[Architecture](architecture.md) explains the integrated and standalone routes and their division of work. [Contracts](contracts.md) specifies what each consumer may exchange; Counsel's memory host owns its independent permission and failure checks. [Retrieval](retrieval.md) explains how Scope uses the host's artifacts. [Improvement and go-live](improvement-and-go-live.md) keeps the full rehearsal requirements, including Reckon's three roles and the memory-host loss case.

Part of [Scope](../index.md).
