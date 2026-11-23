# Scope

Scope is the ecosystem's cache for context: it sits on Pale, Weave or both, because what an agent read has usually changed by the time it acts. It gives each agent session the context to continue earlier work without asking the person to reconstruct its history. It connects the immediate task to the project's longer purpose, selecting the relevant facts, decisions and reasons without handing the agent every record.

Like any cache it is optional and never the source of truth. With Pale it reranks as genealogy updates arrive and writes a pointer to the context it gave each agent into Pale's genealogy, and it never writes Weave's state; without Pale it runs standalone, over Weave, and is how an agent reads Weave. Today the kernel is an empty library: the design below is the work in front of it.

Source owners supply copies and retain access to the originals. Scope's answer names the records it used, their revisions and the gaps that matter to the task.

## Choose your starting point

::::card-group

:::card

[Build the library](./development.md)

Compile the crate and check where to add a source adapter or change retrieval.

:::

:::card

[Understand the architecture](./concepts.md)

Follow a source update from the owner's copy to the agent's answer.

:::

::::

The [product guide's equipment-order example](https://rawthoughts.in/scope/context-for-a-task/) follows an author returning to an order after a few days away. The approved order, a delivery report and a missing arrival estimate show what the next session needs to pick up the work.

<a id="the-implementation-boundary"></a>

## What the architecture separates

In Scope's architecture, the source adapter uses the owner's tools to read the original and sends Scope a snapshot without secrets. Scope stores verified revisions and builds a separate search index before answering requests. Each request reads one prepared snapshot so its records and access rules agree.

The separation lets developers rebuild the search index without rewriting source records. A new ranking rule may change what a caller sees first, within the same access rules.

The architecture keeps [context offered, context reported used and evidence that it helped](./concepts.md#nothing-improves-itself) separate when comparing retrieval policies.

On the integrated path, Pale checks the request and passes along Scope's signed bundle byte for byte. Standalone Scope, without Pale and over Weave, uses its own signed caller grants. Strict retrieval must work without model-generated summaries, embeddings or links. In standalone full mode, Scope's design links Pale's Counsel port library and calls its configured memory host without a Pale daemon; on the integrated path Pale invokes the host. Either way, the host checks processing permission separately. The [architecture chapter](./concepts.md) explains these connections and what can make a request fail.

To contribute now, [build the library](./development.md#building-the-library) and follow the architecture for the part you plan to change. Client integrations need the published caller API and import formats; wait for those contracts before writing a consumer.
