# Working on Scope

Scope is the ecosystem's cache for context: it gives an agent the smallest useful, fresh context for its task, with sources and omissions explained, so each session can continue earlier work. It sits on Pale, Weave or both and is never the source of truth. Its design has two supported modes: integrated, through Pale, and standalone, without Pale and over Weave. Source owners supply snapshots and retain access to the originals; receiving context grants no permission to act. This repository currently contains design documentation and the dependency-free `scope-kernel` Rust crate, which has no modules yet. The complete design is in the [engineering specifications](docs/maintainers/README.md).

Start with the [README](README.md), [developer introduction](docs/index.md) and [development guide](docs/development.md). The [manifest](kernel/Cargo.toml) and [crate root](kernel/src/lib.rs) establish the current build; the manual's architecture describes the design.

## Keep context selection separate from source access

Scope's design puts the admission of owner-supplied snapshots in modules under `kernel/src/sources/`. Acquisition belongs with the source owner: credentials, provider sessions and commands that read originals stay there. Use synthetic inputs here. Operational data, personal records and database files do not belong in this repository.

The retrieval design checks permissions and freshness before ranking, keeps required context within the request's budget, and explains missing material. Strict mode excludes model-derived artifacts. Policy improvement happens separately from serving requests; reported use alone does not establish usefulness. These are the design's requirements.

The interfaces, bindings and storage each get a folder with their first operation (see the development guide); `paper/` holds a research-paper outline. Wait for published contracts before implementing a consumer. The current absence of dependencies does not settle the later MONAD budget types or optional Reckon integration.

## Build and check the kernel crate

From the repository root, with Rust and Cargo installed:

```sh
cargo build --locked --offline --manifest-path kernel/Cargo.toml
cargo test --locked --offline --manifest-path kernel/Cargo.toml
```

The current test command compiles the targets and reports zero unit and doc tests. It supplies no retrieval, permission or recovery coverage. Run behavioural checks when behaviour is added, with cases for the permissions and source changes it handles.

For documentation-only changes, check the source claims and links.

<!-- BEGIN shared repository rules -->

- Review a source file above 1,000 lines and split it by concern before 1,500.
- Keep Rust tests under `tests/`; keep Go's `_test.go` files beside their package.
- Finish a goal with the codebase the same size or smaller unless a requested feature requires growth. Preserve the behaviour, tests, cases and examples.
- Every engine must build from a fresh clone on Linux and macOS.
- Keep generated API reference and build output out of Git; change their source or generator.
- Write comments and API documentation for the code's reader. A crate or module comment first says what it is for in the system, what it builds on and what builds on it, then its purpose, inputs, results and useful edge cases, with the purpose written problem-first in the present tense: the problem it solves and what solves it today. One plain line after that opening says what is not built yet, as the problem now in front of it, and a negative appears only where a reader would expect the opposite: a limit stated as a property of what exists stays ("it runs on loopback with no caller authentication"), while a negative measured against the finished design is a hedge. Keep them self-contained, with links inside the repository.
- Push each repository as one commit whose whole message is `init`, with Harsh as author and committer under the account the folder uses and no `Co-Authored-By` or `Claude-Session` trailers; later commits stay short and plain.
- Describe the present design and research. The repository neither links nor ships lineage: earlier papers, predecessor versions, history tags and the commits behind them.
- Public repository files, including generated text, link within the repository or to public addresses their readers can open.
- A README is the repository's front door: it carries the product account for the technical reader who arrives there, opening with the product's plain name and the problem it solves, in the words its published pages use.
- Name every operation, command, tool, type, field and variable so a reader without its author's context can tell what it does, what it enables and when to use it; docstrings say the same. Keep full-field record schemas for the engine's consistency, named in plain words like everything else, and author each surface's schemas separately, one per intent, in its caller's terms: SDKs and APIs, the command line, the language server and the agent protocols (MCP, A2A, ACP) are different surfaces with different callers, and the agent protocols compose intents over the operations the others expose.
- Write each Markdown paragraph on one source line. Run the repository's formatter with `proseWrap: never` on changed Markdown.

<!-- END shared repository rules -->

Before handing back:

- Does the change carry Scope's continuity purpose while distinguishing design from implemented behaviour?
- Do source access and permissions remain with their owners, with synthetic inputs used here?
- What did the checks establish about the changed surface, and what still needs implementation or contract publication?
