# Why Next is not investing in LiveView Native

**Status:** Decision

## Decision

Next will not invest in LiveView Native (LVN) as the foundation of its mobile application.

## Rationale

### LVN carries permanent cross-platform pressure

LVN is a general UI platform. Its maintainers must continuously define a common model for components, events, state updates, navigation, focus, lifecycle, and compatibility across HTML, SwiftUI, and Compose.

LiveView's normal state model fits the web well: the server owns the state, and the browser DOM is a replaceable projection of it. A reconnect or refresh can reconstruct that projection from the server.

A native app has durable client state that is not equivalent to a DOM: navigation stacks, focus and keyboard state, gestures, scroll position, animations, local interaction state, device integrations, and foreground/background/termination lifecycle. LVN can synchronise a native view with server state, but it must continuously decide which side owns each of these concerns and how they reconcile after an update or reconnect. Server authority, client continuity, and platform behaviour cannot all be reduced to one model without trade-offs.

This work has no completion point. The supported component surface must evolve with every target platform and with every new kind of application built on LVN. For each capability, LVN must either add it to the shared model, constrain it to the overlap of all renderers, or provide a platform-specific extension. Each extension reduces the value of the common model and adds compatibility work.

Mobile adds a second permanent concern: native app binaries remain installed while the server evolves. LVN must preserve the meaning of old component trees and events for long-lived iOS and Android versions. A framework can manage this, but it cannot eliminate it.

This is not a criticism of the goal. It is the permanent responsibility of a general multi-renderer framework. Investing in LVN means accepting its abstraction, roadmap, and trade-offs as a central part of Next.

### LVN has not proven it can carry that responsibility

LVN has not established sufficient credible production adoption for a dependency at the centre of Next's mobile product. A mobile UI foundation needs evidence that teams operate it successfully across releases, platform changes, failures, and long-lived app versions. Project activity alone is not that evidence.

LVN also remains unfinished. Its published Phoenix package and core libraries have not reached a stable, broadly proven product state. Next would take on the risk of becoming an early maintainer of foundational infrastructure rather than a consumer of a proven product.

### The required confidence is absent

A choice to invest in LVN would be a strategic commitment to that platform and its ecosystem, not a small library choice. Its lack of production proof means we do not have the confidence required to make that commitment.

## Scope of this decision

This decision concerns investment in LVN only. It does not claim that server-driven native UI is impossible or undesirable, and it does not prescribe an alternative implementation.

## Evidence

- LiveView Native Phoenix package releases: https://github.com/liveview-native/live_view_native/releases
- LiveView Native core releases: https://github.com/liveview-native/liveview-native-core/releases
- LiveView Native SwiftUI client: https://github.com/liveview-native/liveview-client-swiftui
- LiveView Native Jetpack client: https://github.com/liveview-native/liveview-client-jetpack
