# 0004. Adopt server-authoritative realtime BFF Pages

## Context

[ADR 0002](0002-adopt-a-hybrid-mobile-architecture.md) introduces BFF pages for native-rendered experiences. [ADR 0003](0003-adopt-device-independent-mobile-ui-models.md) defines the UI models that those pages render.

A BFF page needs a consistent lifecycle for opening a URL, receiving realtime updates, sending actions, recovering from reconnects, and navigating to another page.

## Decision

A BFF Page is addressed by a Next URL and has one realtime page session.

Next authorizes the current user, builds the current Page UI model, and delivers it to the native page. Each BFF Page subscribes to its relevant Observatory updates; those updates rebuild and publish the Page's complete UI-model snapshot. On reconnect, the native page receives the current authoritative snapshot.

Native actions go to the BFF Page session. Next authorizes and handles them, then delivers the resulting Page snapshot. The initial protocol sends complete snapshots, not renderer diffs or client-side patches.

### Page and embedded model boundaries

The realtime boundary follows navigation, not visual composition. A BFF Page is routed: it has a URL, authorization, a realtime session, and action handling.

UI models are embedded in that Page. They may be reusable containers or leaves, but they have no URL, session, or independent update stream. A model represents its semantic role—such as a Section, Tab, Card, Form, or List—rather than an embedded LiveView implementation.

### Action kinds

A native UI element carries one of two behaviours:

- A **link** is a server-provided navigation control. The Native Navigator follows it according to [ADR 0002](0002-adopt-a-hybrid-mobile-architecture.md).
- A **command** asks the BFF Page to perform an authorized state change, after which Next delivers the resulting Page snapshot.

A Button may present either behaviour. The distinction is behaviour, not appearance.

## Consequences

Next remains the authority for page state and actions. Native pages render the latest authorized UI model and do not need their own reconciliation or diff engine.

## Alternatives considered

### Poll for the current UI model

Rejected. Polling delays realtime updates and adds repeated requests when no state has changed.

### Send incremental renderer patches

Rejected initially. Complete snapshots make reconnect and state recovery straightforward; patches can be considered only when measured payload or rendering costs justify them.
