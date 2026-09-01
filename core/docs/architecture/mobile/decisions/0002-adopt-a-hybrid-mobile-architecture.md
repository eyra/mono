# 0002. Adopt a hybrid mobile architecture

## Context

Next needs native application capabilities while retaining the existing LiveView product and introducing native-rendered experiences where they provide value.

No single renderer should own every mobile page. Native application structure, embedded web pages, and native-rendered pages have different responsibilities.

## Decision

Adopt a hybrid mobile architecture with three rendering layers:

- A native application base structure that owns the mobile route stack, navigation transitions, and platform lifecycle.
- Phoenix LiveView pages hosted in one shared embedded WebView.
- Server-driven, realtime BFF pages for experiences that need native rendering.

The Native Navigator owns the route stack across LiveView and BFF pages. Next provides navigation controls on the server; the Native Navigator applies their route policy and selects the shared WebView or a BFF page.

[Hotwire Native](https://native.hotwired.dev/overview/basic-navigation) is the reference example for the shared-WebView native-navigation pattern. Next does not adopt it as a dependency.

## Consequences

A mobile page uses the rendering layer that matches its needs. The shared WebView is never duplicated per route, while native navigation provides a single stack for all page types.

This is a narrow Next application implementation, not a general navigation library. It creates the need for device-independent UI models for BFF pages, addressed by [ADR 0003](0003-adopt-device-independent-mobile-ui-models.md).

## Alternatives considered

### Use LiveView Native as the shared mobile renderer

Rejected by [ADR 0001](0001-do-not-invest-in-liveview-native.md).

### Use Capacitor Native Navigation

Rejected. [Capacitor Native Navigation](https://capgo.app/docs/plugins/native-navigation/) retains route and content ownership in a JavaScript WebView. It does not provide the native route stack required by this decision.

### Resolve each destination through a Next route-resolution endpoint

Rejected. Navigation controls belong to the server-provided page representation; a separate lookup adds an unnecessary request before navigation.
