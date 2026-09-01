# Mobile architecture

This directory records the architecture of the Next mobile application. Architecture decisions are the source of truth; this README is their current index and identifies concepts that still need design.

## Decision records

- [0000. Adopt architecture decision records](decisions/0000-adopt-architecture-decision-records.md)
- [0001. Do not invest in LiveView Native](decisions/0001-do-not-invest-in-liveview-native.md)
- [0002. Adopt a hybrid mobile architecture](decisions/0002-adopt-a-hybrid-mobile-architecture.md)
- [0003. Adopt device-independent mobile UI models](decisions/0003-adopt-device-independent-mobile-ui-models.md)
- [0004. Define the realtime BFF page protocol](decisions/0004-define-the-realtime-bff-page-protocol.md)

## Concepts to address

### WebView bridge

Define the bridge between LiveView pages and the Native Navigator, including navigation-control interception and native-to-web communication.

### Authentication and session lifecycle

Define authentication continuation, session recovery, app resume, and reinstall behaviour.

### Invitations and app links

Define how invitation context opens the app and survives authentication and onboarding.

### External task handoff

Define how the app opens external questionnaires or partner flows and handles a return to Next.

### Push notifications

Define device registration, consent, notification content, and notification-open behaviour.

### UI-model contract

Define the JSON Schema, validation, fixtures, compatibility, and renderer conformance for the UI models in ADR 0003.

## Related documentation

- [Centerdata integration](centerdata/design-briefing.md)
- [Centerdata integration decisions](centerdata/integration-decisions.md)
