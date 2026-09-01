# Mobile architecture

**Status:** Draft

## Purpose

Define how the Next iOS and Android apps host and cooperate with the Phoenix LiveView application. This document covers the shared mobile architecture, not a specific partner integration.

## Scope

- Native iOS/Android shell and Phoenix LiveView boundary.
- Bridge messages, deep links, authentication continuation, external-task handoff, and return to the app.
- Behaviour when the app is started, resumed, reconnected, or opened from an invitation.

## Out of scope

- Assignment, questionnaire, or partner-specific business rules.
- Centerdata/LISS protocol details; see [`centerdata/`](centerdata/).
- Offline-first participation.

## Context

Next is a hybrid application: a thin native shell hosts a mobile-tuned Phoenix LiveView session. Product state, authorization, and authentication stay server-side. Native code exists for capabilities that require the operating system or a platform integration.

```text
Native app (iOS / Android)
  ↕ app links, lifecycle, bridge messages
Phoenix LiveView
  ↕ server-side state, authorization, integrations
Next systems
```

## Responsibility boundary

### Native app

- Open and receive universal links / Android App Links.
- Host the LiveView session and report app lifecycle changes.
- Launch external browser or app flows when LiveView requests it.
- Return the resulting URL or event to LiveView.
- Register for and receive platform push notifications.

### LiveView and Next

- Render product UI and own navigation state.
- Authorize actions and keep the session server-side.
- Interpret invitation and assignment context.
- Start and resume authentication and external-task flows.

### Bridge

- Carries explicit, versioned messages between native code and LiveView.
- Does not expose arbitrary native calls or JavaScript evaluation.
- Is the only shared contract the iOS and Android implementations must follow.

## Bridge contract

The contract needs a small set of typed messages in both directions:

| Direction | Message | Purpose |
| --- | --- | --- |
| Native → LiveView | `app_link` | Deliver a received invitation or return URL. |
| Native → LiveView | `app_lifecycle` | Report foreground/background/resume state. |
| Native → LiveView | `push_opened` | Deliver a notification tap and its context. |
| LiveView → Native | `open_external_url` | Launch an external authentication or questionnaire URL. |
| LiveView → Native | `open_app_link` | Request a platform-owned app-link transition when needed. |

Each message must have a version, a correlation ID where it starts a flow, and an explicit success/error result. The final payload schema and transport mechanism are architecture decisions still to be made.

## Navigation and invitation context

An invitation must survive these transitions without becoming client-side authority:

1. Invitation link opens the app or installation flow.
2. Native app delivers the link to LiveView.
3. LiveView stores only the minimum continuation context in the server-side flow.
4. After authentication or onboarding, LiveView resolves the user and assignment, authorizes access, and navigates to the assignment.

The link is context, not proof of access. The server always resolves and authorizes the referenced assignment.

## Authentication

Authentication remains a Next web/LiveView flow. The native shell does not implement a separate account or token model.

The architecture must define how an authentication redirect returns to the same LiveView continuation, including app reinstall and app resume cases.

## External tasks

LiveView asks the native shell to open an external questionnaire or partner flow. On return, the native shell sends the URL/event back through the bridge. LiveView verifies and records the resulting state; return navigation is not the source of truth for completion.

## Push notifications

Native code owns platform registration and delivery through APNs/FCM. Next owns notification authorization, targeting, content, and the server-side association with a device registration.

A notification payload contains only a notification ID and optional non-sensitive navigation context. When the participant opens it, native sends `push_opened` through the bridge; LiveView resolves the notification and authorizes the resulting destination. A push payload is never proof of assignment access.

The architecture must decide token lifecycle, consent UX, delivery provider, retry/expiry policy, and which events justify a notification.

## Reconnect and lifecycle behaviour

- Reconnecting LiveView restores server-side session and permitted navigation state.
- App resume re-delivers pending app-link or external-flow context once.
- Bridge messages must be idempotent or safely deduplicated by correlation ID.
- If the app cannot restore the intended continuation, show a clear route back to the authorized assignment overview.

## Security and privacy

- Do not place access tokens, assignment authorization, or private participant data in bridge payloads or deep links.
- Validate all incoming links and return URLs server-side.
- Keep platform-specific credentials in native secure storage only when strictly required by the chosen integration.
- Log flow/correlation IDs, not sensitive payloads.

## Decisions to make

1. Bridge transport: LiveView hooks, a WebView message channel, or another explicit adapter.
2. Canonical app-link URL scheme and supported route set.
3. Correlation-ID format and duplicate-delivery handling.
4. External-browser versus embedded-browser policy per flow.
5. Failure and reinstall recovery UX.
6. Push provider, device-token lifecycle, consent UX, and notification-event policy.

## Validation

The architecture is complete when one iOS and one Android proof of concept can:

1. Open an invitation link.
2. Deliver its context to LiveView.
3. Complete an authentication continuation.
4. Launch and return from an external URL.
5. Restore or safely recover the flow after app resume.
6. Receive a push notification and open its authorized destination.

## Related documentation

- [`../decisions/0001-do-not-invest-in-liveview-native.md`](../decisions/0001-do-not-invest-in-liveview-native.md) — decision not to invest in LiveView Native.
- [`centerdata/design-briefing.md`](centerdata/design-briefing.md)
- [`centerdata/integration-decisions.md`](centerdata/integration-decisions.md)
