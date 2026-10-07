# 0002. Adopt mobile delivery capability tiers

## Context

Next needs an architecture that can evolve from its existing LiveView experience to native navigation and, where it provides product value, native-rendered routes. The implementation mechanism is not yet known. Choosing a framework, navigation model, WebView bridge, native rendering contract, or BFF design before testing representative flows would be premature.

## Decision

Describe mobile delivery in these cumulative capability tiers:

1. **Web** — a route is rendered by Phoenix LiveView in a browser or WebView.
2. **Native navigation** — web-rendered routes participate in an application-owned native navigation experience.
3. **Native routes** — selected routes can be rendered natively alongside web-rendered routes.

A route's tier is chosen per use case. No product area is committed wholesale to web or native rendering.

Defer decisions on specific implementations until a proof of concept evaluates a representative journey. This includes, but is not limited to, a Hotwire-style navigation model, Tauri, and a custom BFF or native rendering contract.

The current PoC ([UC-SENSE-01](https://app.basecamp.com/5734045/buckets/35926565/todos/10268625296), scope approved 2026-09-03) evaluates Tier 1 routes: existing Phoenix LiveView pages rendered in WebViews behind a native tabbar. Native-rendered routes (Tier 3) are deferred; this PoC does not require or commit to a native-rendered route.

## Consequences

The current architecture commits to the capabilities and their technology-independent constraints, not to an implementation:

- routes, URLs, authorization, and product semantics remain stable across tiers;
- web and native routes must form one coherent journey, including deep links, back navigation, authentication continuation, external handoff, and recovery;
- existing LiveView routes remain valid; native rendering is additive;
- backend domain logic and authorization must not be coupled to a chosen client technology.

Within that scope, the PoC must evaluate navigation and deep links, LiveView compatibility, native and lifecycle capabilities, authentication and recovery, delivery and update model, observability, testability, and developer workflow. Consider future migration implications without implementing native-rendered routes. Record the selected shell technology and its resulting commitments in later implementation ADRs.

## Alternatives considered

### Select an implementation now

Rejected. We lack PoC evidence for the representative flows and would turn an implementation hypothesis into an architectural commitment.

### Treat every route as native-rendered

Rejected. It would require a premature rewrite of existing LiveView routes and does not preserve the incremental delivery path.
