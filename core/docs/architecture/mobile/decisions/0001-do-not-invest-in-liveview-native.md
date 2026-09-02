# 0003. Do not invest in LiveView Native

## Context

LVN is a general UI platform. Its maintainers must continuously define a common model for components, events, state updates, navigation, focus, lifecycle, and compatibility across HTML, SwiftUI, and Compose.

LiveView's normal state model fits the web well: the server owns the state, and the browser DOM is a replaceable projection of it. A reconnect or refresh can reconstruct that projection from the server.

A native app has durable client state that is not equivalent to a DOM: navigation stacks, focus and keyboard state, gestures, scroll position, animations, local interaction state, device integrations, and foreground/background/termination lifecycle. LVN can synchronise a native view with server state, but it must continuously decide which side owns each of these concerns and how they reconcile after an update or reconnect. Server authority, client continuity, and platform behaviour cannot all be reduced to one model without trade-offs.

This work has no completion point. The supported component surface must evolve with every target platform and with every new kind of application built on LVN. For each capability, LVN must either add it to the shared model, constrain it to the overlap of all renderers, or provide a platform-specific extension. Each extension reduces the value of the common model and adds compatibility work.

Mobile adds a second permanent concern: native app binaries remain installed while the server evolves. LVN must preserve the meaning of old component trees and events for long-lived iOS and Android versions. A framework can manage this, but it cannot eliminate it.

LVN has not established sufficient credible production adoption for a dependency at the centre of Next's mobile product. A mobile UI foundation needs evidence that teams operate it successfully across releases, platform changes, failures, and long-lived app versions. Project activity alone is not that evidence.

LVN also remains unfinished. Its published Phoenix package and core libraries have not reached a stable, broadly proven product state. Next would take on the risk of becoming an early maintainer of foundational infrastructure rather than a consumer of a proven product.

## Decision

Next will not invest in LiveView Native as the foundation of its mobile application.

## Consequences

Next does not accept LVN's abstraction, roadmap, and trade-offs as a central dependency of its mobile product. This decision concerns LVN only; it does not claim that server-driven native UI is impossible or undesirable.

## Alternatives considered

### Invest in LiveView Native

Rejected. The permanent cross-platform responsibility, together with LVN's unfinished state and lack of sufficient production proof, does not provide the confidence required for this strategic commitment.

## References

- LiveView Native Phoenix package releases: <https://github.com/liveview-native/live_view_native/releases>
- LiveView Native core releases: <https://github.com/liveview-native/liveview-native-core/releases>
- LiveView Native SwiftUI client: <https://github.com/liveview-native/liveview-client-swiftui>
- LiveView Native Jetpack client: <https://github.com/liveview-native/liveview-client-jetpack>
