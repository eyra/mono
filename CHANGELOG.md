# Changelog

## Types of changes

* Added - For any new features that have been added since the last version was released
* Changed - To note any changes to the software's existing functionality
* Deprecated - To note any features that were once stable but are no longer and have thus been removed
* Fixed - Any bugs or errors that have been fixed should be so noted
* Removed - This notes any features that have been deleted and removed from the software
* Security - This acts as an invitation to users who want to upgrade and avoid any software vulnerabilities

## \#25.1 2026-06-14
* Fixed - Affiliate URLs with `?p=null` or `?p=undefined` now return 403 instead of silently creating ghost affiliate users (came from external panels coercing an empty JS variable to the string "null")
* Fixed - 403 page and other status pages showed raw msgids ("page.title" / "403.body") instead of translated text on DE / ES / IT / LT / RO

## \#25 2026-06-10
* Fixed - "Participants waiting for pay out" banner on the Participants tab was lost in the milestone 23 refactor; restored with correct copy
* Fixed - Pay-out modal translations (payout.*) were wiped in the SURFconext-auth merge; EN and NL strings restored
* Added - Pay-out Overview tab now shows a list of completed payouts instead of the "coming soon" placeholder
* Changed - Updated PaNL onboarding copy

## \#24 Unreleased
* Changed - SURFconext userinfo (name, email, affiliation) is now stored as a raw JSON map; individual parsed columns removed from the database
* Fixed - Auth signup page (/user/auth/:provider) had no side margins on mobile
* Fixed - Sign-in button incorrectly appeared in the navbar on dedicated provider auth pages
* Fixed - Org member/owner list crashed when an auth principal had no linked user (orphaned principals are now silently skipped)
* Added - SURFconext-based authentication for creators: a provider-agnostic signup page at /user/auth/:provider (SURFconext, Google, Apple, and a new Mock provider for dev/test); name, logo, and auth path are derived from the provider key
* Added - Terms-and-privacy onboarding step shown to first-time SSO users; folds into the existing /user/onboarding flow
* Added - Mock auth provider for local/dev/test environments only, with a /user/auth/mock/reset utility for clean test runs
* Added - Researcher reward approval flow on the Participants tab: Pay-out modal with Waiting + Overview tabs, per-row decline with rejection reason, bulk "Pay out all"
* Added - Reward state machine (reserved → approved/rejected) with compare-and-swap transitions to prevent double-apply under concurrency
* Added - Pay-out NextAction CTA on the home page for researchers with pending approvals
* Added - Rewards summary card on the participant home page
* Changed - Auth provider routes standardised to /auth/:provider and /auth/:provider/callback (SURFconext IdP dashboard updated to match)
* Changed - SSO users are activated when they accept the terms-and-privacy onboarding step (sets confirmed_at) rather than being auto-activated on registration
* Fixed - Free studies were excluded from the marketplace visibility check on milestone 23 — now treated as visible

## \#23 2026-05-22
* Added - Organisations: org owner role, admin pages per org, owners modal, archive modal, org node/admin views, members search & filter
* Added - Onboarding journey nested under /user/onboarding/*: await-confirmation, confirm-token, post-signup activation
* Added - Paid participant slots block on the Participants tab: subject count + reward, budget transactions, "Pay to add participants" button, payment-resume flow
* Added - mix e2e task with Playwright + per-environment feature-flag-driven setup
* Added - Live refresh of NextAction banners on Desktop and Admin Organisations
* Changed - Locale rule simplified to a single check: signed-in researchers see English, everyone else (signed-in participants + anonymous visitors) follows their browser language. Removes the previous per-role / per-path patchwork.
* Changed - Confirmation email link URL moved to /user/onboarding/confirm/...
* Changed - The Participants tab no longer has a separate post-launch view; pre-launch shows only the recruit URL, post-launch adds the advert + pay-for-slots panels (driven by template flags)
* Changed - Privacy / terms acceptance is now a step of the onboarding flow instead of a separate page
* Changed - Org owners are granted the :admin role; /org/node/{id} authorises per-org rather than via a global :admin
* Fixed - Activation, sign-in and profile pages had no mobile side-margins
* Fixed - /user/profile and other authenticated pages rendered in English even with the browser set to a different language
* Fixed - Confirmation, password-reset and other transactional emails were not being delivered from Fly environments (Mailgun adapter pointed at the wrong domain)
* Fixed - Profile tab and Panl tab on /user/profile had inconsistent top margins
* Fixed - First pay-in skipping the paid path due to stale BudgetForm assignment
* Fixed - NextAction-banner staying visible on Desktop after an admin role was revoked
* Fixed - /org/node/{id} remained accessible to ex-admins after their role was revoked
* Fixed - "Add domain members" action could be triggered by stale LiveView sessions whose owner role had been revoked
* Fixed - Translations across LT / DE / ES / IT / RO for sign-in, sign-up, password-reset, onboarding, SURFconext, SSO errors, helpdesk form, "Complete your profile" prompt, and the post-signup success flash
* Fixed - "Reward is set to …" line on the Participants tab only shows once at least one transaction exists; empty-state copy rephrased

## \#22.2 2026-05-07
* Added - Recruit URL (/r/:code) for organic participant recruitment with rate limiting (5/min/IP)
* Added - Recruit participants panel in CMS for questionnaire studies
* Added - /api/e2e/features endpoint for E2E feature flag introspection
* Changed - Policy URLs (terms/privacy) moved to compile-time config
* Fixed - Privacy and terms link translations being removed by gettext extract

## \#22.1 2026-04-23
* Fixed - Panl capitalization normalized across all translations
* Changed - Dutch copy from formal (u/uw) to informal (je/jouw)
* Added - Terms and privacy link translations for sign-up page

## \#22 2026-04-17
* Added - Panl pre-launch email capture flow for participant onboarding
* Added - Email validation via UserCheck API (disposable, role account, MX checks)
* Added - AppSignal custom metrics for Feldspar donate and log endpoints
* Added - Pool and Affiliate filters on admin users page
* Added - Idempotent seed infrastructure for deploy environments
* Changed - Questionnaire opens in same tab instead of new tab (fixes mobile popup blocker)
* Changed - Panl post-launch features gated behind separate feature flag
* Fixed - Modal navigation buttons leaking between workflow steps
* Fixed - x_square.svg platform logo missing
* Fixed - Admin user page performance for large user counts

## \#21 2026-02-28
* Fixed - Google Sign In callback to show error message instead of 500
* Fixed - SSO duplicate email handling across all providers
* Fixed - OAuth2 missing session state handling in SSO callbacks
* Fixed - Race condition in workflow item deletion causing StaleEntryError
* Fixed - File upload controller to handle invalid filenames and missing files
* Fixed - GreenLight authorization NoResultsError
* Fixed - Show 404 for deleted assignments instead of Access Denied
* Fixed - CaseClauseError in NodePageEmptyDataView for Ecto.Multi errors
* Fixed - Invalidate participant URL when data donation item is deleted
* Fixed - Trix editor disconnect when modal appears
* Fixed - Double spacing issue in tabbed navigation
* Added - Onboard-first signup flow for PaNL participants
* Added - Auto-confirmation for affiliate users
* Added - Panl feature flags to guard PaNL-specific functionality
* Added - Profile menu visibility for unconfirmed internal users
* Added - Missing translations for sign up screen terms and privacy
* Added - WaitGroup to ensure data donations complete before exit
* Added - Feldspar client debug logging for production visibility
* Added - Fly.io deployment infrastructure
* Added - Staging option for Fly.io deployment workflow
* Changed - Branding from "Eyra" to "Next" in terms/privacy agreement text
* Changed - Improved Feldspar controller logging with uploadContext

## \#20.3 2026-02-12
* Fixed - Race condition in affiliate user creation
* Fixed - Race condition in crew member and role assignment creation
* Added - Service login API endpoint with SERVICE_LOGIN_KEY security
* Added - E2E tests (Playwright) and load tests (Artillery) infrastructure
* Added - Fly.io deployment infrastructure with auto-suspend support
* Added - JSON error responses for API endpoints
* Changed - Increase HTTP body limit from 200MB to 210MB for data donations

## \#20.2 2026-01-27
* Fixed - FunctionClauseError in embedded LiveViews for flash messages
* Fixed - File upload controller to handle invalid filenames and missing files
* Fixed - Ecto.NoResultsError in GreenLight authorization context
* Fixed - BadMapError in UserState when parsing conflicting paths
* Fixed - Files donated without participant identifier due to timing bug
* Fixed - Panel info retrieval for external panel participant IDs
* Changed - Update Prism UI to 0.1.5 with spinner centering fix

## \#20 2026-01-14
* Added - Romanian (RO) and Lithuanian (LT) language support
* Changed - Font from Finador to Nunito / Nunito Sans
* Added - Prism UI framework integration
* Changed - Restructured icons and logos folders

## \#19 2026-01-03
* Added - Privacy policy acceptance with clickable links during signup (Next platform)
* Added - UserState framework for managing client-side state (timezone, language)
* Added - LiveContext framework for passing context through LiveView hierarchy
* Added - Custom end-of-workflow screen text for panel integration
* Added - Hide Panl tab for non-Panl participants
* Added - State machine support in Crew Page
* Added - Multi-language translations (EN, NL, DE, ES, IT) for panel integration workflow
* Changed - Complete refactor of CrewPage hierarchy to LiveNest
* Changed - Improved participant copy and translations
* Changed - Updated modal view component
* Changed - Enhanced toolbar component

## \#18 2025-10-22
* Added: Annotation Recipes (WIP)
* Added:Ontology + Annotation + Criteria Live View (WIP)
* Added: support for LiveView tabs
* Added: Base LiveNest integration including LiveNest Modals
* Added: Core.Seeder module
* Added: git worktree scripts
* Added: Connected Criteria Library items to Annotation/Ontology data
* Added: Draft version of the Annotation/Ontology systems with a simple Onyx Browser
* Added: Add banner to prompt participant to fill in characteristics
* Added: Panl onboarding flow: add participants to Panl from sign-up/in
* Added: Panl onboarding flow: implement add_to_panl functionality for google signin
* Added: Logged in landing page with available advertisements
* Added: tab-bar to the profile page
* Added: Show privacy policy agreement checkbox based on add_to_panl parameter
* Added: Support for test IDs to improve end-to-end testing
* Changed: Improved error handling stream setup in Content.LocalFS and Content.S3
* Changed: Fix search logic from OR to AND across all ViewBuilders
* Changed: Refactor Zircon system with enhanced Annotation/Ontology integration
* Changed: Update sorting and preloading for Annotation/Ontology systems

## \#17.1 2025-10-15
* Fixed: High CPU usage when viewing PDF

## \#17 2025-10-01
* Fixed: PDF viewer no longer refreshes when pressing Done button
* Fixed: Changing number of participants no longer causes page refresh
* Fixed: Helpdesk form type switching no longer causes immediate submit
* Fixed: Cannot change Next profile picture
* Removed: Alpine.js completely removed from codebase
* Updated: Phoenix LiveView to 1.1.11
* Updated: Major dependency updates for improved stability
* Updated: Moved number of participants and participant language to participant tab

## \#16.1 2025-06-25
* Fixed: Export progress report pre-affiliate participant links
* Fixed: Rendering pre-affiliate participant links on pre-affiliate Data Donation assignments

## \#16 2025-06-18
* Added: Affiliate system for panel company integration
* Added: Support for end-of-flow redirect to Affiliates
* Added: Support for sending events to Affiliates
* Added: Integration tab in Assignment CMS for data donations (using Affiliate system)
* Added: Participant tab in Assignment CMS for data donations (using Affiliate system)
* Added Spanish to Assignment settings
* Fixed: Several issues on the Landing Page
* Fixed: Flaky tests due to strange on_mount error
* Security: Bump Erlang/OTP due to security risk

## \#15.2 2025-05-31
* Fixed: Realtime updates interfering participant flows
* Added: Support for sending realtime updates to pages targeted to specific users

## \#15.1 2025-05-08
* Fixed: When a participant returns from a questionnaire back to Next, a popup is shown and the participant must click  'close'.

## \#15 2025-05-07
* Changed: Next Landing page
* Fixed: Account activated successfully message low contrast
* Added: Manual builder to workflow library for Panl studies

## \#14 2025-04-26
* Fixed: Next compatability with feldspar version 4 (loading issue)

## \#13 2025-04-25
* Changed: Refinement of the instruction manual builder based on feedback
* Fixed: Mobile friendly header title for participant flow

## \#12 2025-04-19
* Maintenance release

## \#11 2025-04-09

* Added: Participant Task List Mobile
* Changed: Participant Task List Desktop replaced Master-Detail with Task List centered view just like Mobile.

## \#10 2025-03-26

* Added: Manual Participant Mobile (Beta)
* Fixed: Breadcrumbs on project page

## \#9 2025-03-19

* Added: Manual Researcher CMS (Beta)
* Added: Manual Participant Desktop (Beta)

## \#8 2025-02-28

* Fixed: PDF not readable on mobile device
* Added: Support for Italian in assignments (participants)
* Changed: Use of authorization module to speed up compile time
* Added: Ask for permission before removing yourself from a project
* Added: Overview and Files tab in project. The Files tab replaces the data card.
* Changed: Auto-connect Next storage
* Changed: Updated German copy data donation participant flow

## \#7.1 2025-01-09

* Fixed: Resolved an issue where Feldspar apps were not preloaded in certain edge cases, resulting in excessive user wait times.
* Added: Support for multiple modal views, including background preloading for improved performance.

## \#7 2025-01-07

* Changed: Bump erlang to 27.1.2
* Changed: Bump elixir to 1.17.0
* Fixed: Support for running the app locally in Docker
* Changed: Github release workflow uses Docker
* Changed: Using Debian on production
* Added: Support for sending logging to AppSignal

## \#6.2 2024-11-28

* Added: AppSignal support
* Added: Support for Onyx RIS upload (behind feature flag)

## \#6.2 2024-11-28

* Added: AppSignal support

## \#6.1 2024-11-19

* Fixed: Memory issues by temporary removing Sentry support

## \#6 2024-11-15

* Added: Support for activating assignment embedded mode by url query param.
* Changed: Prevent the tool modal view from closing during assignment when in embedded mode with a single task.

## \#5 2024-11-11

* Fixed: Add/Remove people working on a project.

## \#4 2024-11-06

* Added: Open links in new tab.
* Added: Manually activate user account (Admin feature)  .
* Changed: Improve closing of PDF reader.

## \#3 2024-10-24

* Added: Sentry support for crash management
* Added: Snapchat support for assignment tasks
* Added: Confirmation dialog when skipping content pages or consent pages in assignment configuration.

## \#2 2024-10-04

* Added: Possibility to close assignment tasks before completion.
* Added: Project breadcrumbs for easy navigation and hierarchy overview.
* Changed: Format of the filenames in Storages. Also no folders used anymore. This has impact on Data Donation studies.
* Changed: Assignment does not have a Storage association anymore. Projects can have one Storage that is shared between all the project items.
* Added: Storage project item (BuiltIn and Yoda)
* Added: Support for German language in assignments

## \#1 2024-06-12

Initial version
