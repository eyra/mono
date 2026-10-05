# Mobile delivery architecture

Throughout this documentation, mobile refers to the native iOS and Android
application shells rather than browser-based mobile web.

This document describes the product capabilities the mobile delivery architecture must support. It deliberately does not select a mobile framework, navigation bridge, rendering protocol, or BFF design. Those choices require a focused proof of concept.

## Capability tiers

A route may be delivered at one of three levels. The tiers are cumulative; they are not commitments to a particular implementation.

| Tier                  | Capability                                                                            |
| --------------------- | ------------------------------------------------------------------------------------- |
| **Web**               | The route is rendered by Phoenix LiveView in a browser or WebView.                    |
| **Native navigation** | Web-rendered routes participate in an application-owned native navigation experience. |
| **Native routes**     | The application can mix web-rendered routes with selected routes rendered natively.   |

The architecture must allow a route's delivery level to be chosen deliberately per use case. It must not require an entire product area to be permanently web or native.

## Constraints independent of implementation

- Routes, URLs, authorization, and product semantics remain stable regardless of the delivery level.
- Web and native routes must participate in one coherent user journey, including deep links, back navigation, authentication continuation, external handoff, and recovery.
- Existing LiveView routes remain a valid delivery option; native rendering is additive, not a required rewrite.
- Backend domain logic and authorization must not become coupled to a selected client technology.
- A native-rendered route may need an additional client-facing contract, but its shape, ownership, realtime behaviour, and transport are undecided.

## Proof of concept

The current PoC ([UC-SENSE-01](https://app.basecamp.com/5734045/buckets/35926565/todos/10268625296), scope approved 2026-09-03) evaluates Tier 1 routes: existing Phoenix LiveView pages rendered in WebViews behind a native tabbar. Native-rendered routes (Tier 3) are deferred; implementing one is not a requirement of this PoC.

Evaluate the shell implementation against the criteria below. Broader approaches such as a Hotwire-style native navigation model, a custom BFF for native routes, or Tauri remain possible future choices, not commitments of this PoC.

Evaluate each candidate against:

- navigation and deep-link behaviour for the existing web-rendered routes;
- LiveView compatibility and preservation of existing routes;
- native capabilities and platform lifecycle handling;
- authentication, external handoff, recovery, and error handling;
- delivery and update model, observability, testability, and developer workflow;
- implications for future native-rendered routes, without implementing or committing to them.

Record the selected approach and only the resulting commitments as ADRs after the PoC provides evidence.

## Decision records

- [0000. Adopt architecture decision records](decisions/0000-adopt-architecture-decision-records.md)
- [0001. Do not invest in LiveView Native](decisions/0001-do-not-invest-in-liveview-native.md)
- [0002. Adopt mobile delivery capability tiers](decisions/0002-adopt-mobile-delivery-capability-tiers.md)
- [0003. Require agent-driven physical-device debugging](decisions/0003-require-agent-driven-physical-device-debugging.md)

## Related documentation

- [Authentication session design](designs/authentication-session.md)
- [Centerdata integration](centerdata/design-briefing.md)
