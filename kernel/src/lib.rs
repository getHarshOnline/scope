//! The kernel of Scope, the ecosystem's cache for context, which gives an agent session the
//! smallest useful, fresh context its caller may see, with its sources, age and omissions
//! explained.
//!
//! What an agent read has usually changed by the time it acts, so a task needs a fresh account
//! built from permitted sources. Scope's design holds snapshot admission, eligibility, the
//! retrieval routes, fusion and the decision evidence that its service, command line and
//! bindings build on, as `docs/maintainers/architecture.md` describes. Today the kernel holds
//! only this comment; snapshot admission, eligibility and the retrieval routes are what it has
//! yet to hold.
