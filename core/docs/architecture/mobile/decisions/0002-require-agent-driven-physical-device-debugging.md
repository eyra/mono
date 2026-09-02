# 0002. Require agent-driven physical-device debugging

## Context

Mobile behaviour must be verified on real devices from the start. Simulators do not reproduce all browser, WebView, keyboard, lifecycle, network, and device-integration behaviour. AI coding agents also need a feedback loop that lets them observe and reproduce failures on the same physical devices used for development.

The mobile delivery implementation is still under evaluation. A debugging tool must therefore not be mistaken for a decision to adopt a particular mobile framework, navigation model, or renderer.

## Decision

Every mobile delivery proof of concept must evaluate an approved way for an AI coding agent to remotely inspect and control a running application on physical iOS and Android devices. The path must work when the agent and device are on different hosts, using an authenticated, access-controlled connection.

The required capability is implementation-specific: each candidate must demonstrate the debugging path appropriate to its renderer. The chosen remote device-debugging implementation, MCP server, and any framework-specific adapters are implementation details. Appium is the initial candidate remote device-debugging implementation to evaluate, not an architectural component or an adopted implementation.

The minimum demonstration is:

1. Open the running application on a physical iPhone and Android device.
2. Inspect the current rendered UI and capture a screenshot.
3. Find and interact with controls, including text entry and navigation.
4. Capture actionable failure evidence from the device or browser/WebView.
5. Reproduce a representative journey, including a reconnect or recovery path where the renderer supports one.

For the Web tier, this means the real LiveView application in Safari on iOS and Chrome on Android. For hybrid or native-route tiers, the demonstration must cover the native UI as well as any embedded WebView context.

UI controls used in the representative journeys must expose stable, accessible names, roles, and identifiers suitable for automation. Do not add a separate agent-only UI or production debugging endpoint.

## Consequences

Physical-device debugging must be evaluated in every PoC and documented as part of the implementation decision. A candidate's limitations, mitigation, and cost must be explicit before selection.

The debugging setup may use local, trusted development devices and test accounts only. It must not expose device control or sensitive diagnostic data through the production application.

Later implementation ADRs must name the selected tooling, setup, supported platforms, access controls, and any limitations that affect these rules.

## Alternatives considered

### Verify only with simulators or emulators

Rejected. This leaves physical-device behaviour untested and prevents agents from investigating device-specific failures.
