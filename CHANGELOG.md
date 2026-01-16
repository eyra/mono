# Changelog

## Types of changes

* Added - For any new features that have been added since the last version was released
* Changed - To note any changes to the software's existing functionality
* Deprecated - To note any features that were once stable but are no longer and have thus been removed
* Fixed - Any bugs or errors that have been fixed should be so noted
* Removed - This notes any features that have been deleted and removed from the software
* Security - This acts as an invitation to users who want to upgrade and avoid any software vulnerabilities

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
