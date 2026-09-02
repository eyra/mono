# Mobile delivery architecture

**Status: exploration.** This document describes the product capabilities the mobile delivery architecture must support. It deliberately does not select a mobile framework, navigation bridge, rendering protocol, or BFF design. Those choices require a focused proof of concept.

## Capability tiers

A route may be delivered at one of three levels. The tiers are cumulative; they are not commitments to a particular implementation.

| Tier                                        | Capability                                                                            |
| ------------------------------------------- | ------------------------------------------------------------------------------------- |
| **Web**                                     | The route is rendered by Phoenix LiveView in a browser or WebView.                    |
| **Web + native navigation**                 | Web-rendered routes participate in an application-owned native navigation experience. |
| **Web + native navigation + native routes** | The application can mix web-rendered routes with selected routes rendered natively.   |

The architecture must allow a route's delivery level to be chosen deliberately per use case. It must not require an entire product area to be permanently web or native.

## Constraints independent of implementation

- Routes, URLs, authorization, and product semantics remain stable regardless of the delivery level.
- Web and native routes must participate in one coherent user journey, including deep links, back navigation, authentication continuation, external handoff, and recovery.
- Existing LiveView routes remain a valid delivery option; native rendering is additive, not a required rewrite.
- Backend domain logic and authorization must not become coupled to a selected client technology.
- A native-rendered route may need an additional client-facing contract, but its shape, ownership, realtime behaviour, and transport are undecided.

## Proof of concept

Before recording an architecture decision, build a small PoC around a representative journey that includes web navigation, a native-navigation transition, and—where feasible—a native-rendered route.

Candidate approaches may include a Hotwire-style native navigation model, a custom BFF for native routes, Tauri, or other viable options. These are options under evaluation, not architecture components.

Evaluate each candidate against:

- navigation and deep-link behaviour across web and native routes;
- LiveView compatibility and preservation of existing routes;
- native capabilities and platform lifecycle handling;
- authentication, external handoff, recovery, and error handling;
- delivery and update model, observability, testability, and developer workflow;
- cost of introducing and migrating native-rendered routes.

Record the selected approach and only the resulting commitments as ADRs after the PoC provides evidence.

## Decision records

- [0000. Adopt architecture decision records](decisions/0000-adopt-architecture-decision-records.md)
- [0001. Adopt mobile delivery capability tiers and defer implementation](decisions/0001-adopt-mobile-delivery-capability-tiers.md)
- [0002. Require agent-driven physical-device debugging](decisions/0002-require-agent-driven-physical-device-debugging.md)

## Related documentation

- [Centerdata integration](centerdata/design-briefing.md)
