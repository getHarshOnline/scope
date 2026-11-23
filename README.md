# Scope

Scope is the ecosystem's cache for context, the part of RawThoughts' one system that brings the context a task needs. It sits on Pale, Weave or both, because what an agent read has usually changed by the time it acts and a task needs the smallest fresh account of what matters. It gives agent sessions the context to continue earlier work, connecting the immediate task to its project's longer purpose and decisions. Like any cache it is optional and never the source of truth. Its design has two supported modes: integrated, through Pale, and standalone, without Pale and over Weave. With Pale it reranks as genealogy updates arrive and writes a pointer to the context it gave each agent into Pale's genealogy, and it never writes Weave's state. Each source owner supplies a secret-free snapshot and keeps access to the original. Scope selects a bundle of fresh context the caller may see, kept within the request's size limit, with its sources, age and omissions. The caller retains its own authority to act. This repository holds Scope's Rust code and developer documentation.

## What is here

The [development guide](docs/development.md) says where each kind of change belongs: the Rust kernel, source adapters, service, command line, contracts and bindings. It also distinguishes the research paper in `paper/` from the service design.

The build produces the `scope-kernel` library only, and today that kernel holds only a crate comment; snapshot admission, eligibility and the retrieval routes are what it has yet to hold. The context service, resolver, command line and integration contracts are designed in the specification, and the test command runs no tests yet.

## Building

[Build the Rust library and check its test targets](docs/development.md#building-the-library). The development guide gives the commands, test coverage and contribution instructions.

## Documentation

The [product guide](https://rawthoughts.in/scope/context-for-a-task/) follows context through a task. The [developer introduction](docs/index.md) leads into the [architecture](docs/concepts.md) and [development guide](docs/development.md).

The [full engineering specification](docs/maintainers/README.md) is part of Scope's developer documentation. It explains the contracts, data model, retrieval, recovery and acceptance cases in detail for implementation and review.

## Data and secrets

No operational data, personal data or credentials belong in this repository. The ignore rules exclude database files, encrypted stores and credential files. Source credentials stay with the source owners. Scope's service signer proves the origin of its own bundles and grants no source access.

## Licence

Scope's kernel, design documents and paper use [AGPL-3.0-or-later](LICENSE). Third-party material keeps its own terms and required notices.

Commercial use is permitted under the applicable licence. Alternative terms require a separate written agreement with RawThoughts Enterprises Private Limited, which can grant them only for material it is entitled to relicense; this repository grants none. See [NOTICE](NOTICE) for ownership, [CITATION.cff](CITATION.cff) for citation and [CONTRIBUTING.md](CONTRIBUTING.md) for contribution requirements. Outside contributions remain closed pending review of the [draft agreement](CLA.md) and a way to record acceptance. Licensing enquiries go to info@rawthoughts.in, or open a GitHub issue with the label `commercial-license`.
