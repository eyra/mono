# 0003. Adopt device-independent mobile UI models

## Context

[ADR 0002](0002-adopt-a-hybrid-mobile-architecture.md) introduces server-driven, realtime BFF pages that need native iOS and Android rendering. Those pages need a shared product-level UI vocabulary.

The existing `Frameworks.Pixel` components are Web/HEEx implementations. They mix component semantics with HTML structure, Tailwind styling, Phoenix events, and browser-specific behaviour. They are therefore not a device-independent contract.

## Decision

Introduce JSON-serializable UI models as the shared contract for new BFF pages.

UI models express semantic components and data, not HTML, Tailwind classes, or native implementation details. They form a tree of containers and leaves:

- A container defines named regions.
- Each region contains an ordered list of UI models.
- A leaf has no regions.

The vocabulary starts with concepts required by real mobile pages and may align with selected Pixel component semantics. Native navigation and overlays remain platform-owned and outside the shared UI model.

A central model-building layer composes reusable UI models into each BFF Page model. The precise builder API and implementation conventions are deferred until implementation begins.

## Consequences

Existing `Frameworks.Pixel` components remain unchanged in the near term. There is no wholesale Pixel migration or requirement to reproduce its full component catalogue.

The UI-model vocabulary grows only when a real mobile page requires a new concept. A future Web renderer may consume UI models, but this decision does not require one.

## Design

- [BFF Pages](../design/bff-pages.md)

## Alternatives considered

### Migrate existing Pixel components into a shared model now

Rejected. This would add significant work and risk to working HEEx code before a mobile page needs the shared representation.
