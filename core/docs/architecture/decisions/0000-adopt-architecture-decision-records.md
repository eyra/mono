# 0000. Adopt architecture decision records

**Status:** Accepted
**Date:** 2026-09-01

## Context

Next architecture decisions need a durable, discoverable record of their context, decision, and consequences. Decisions often change over time; the record must preserve what was decided and why.

## Decision

Store Architecture Decision Records (ADRs) in `core/docs/architecture/decisions/`.

- Name records with an immutable four-digit sequence and a short kebab-case title: `0001-short-title.md`.
- Use the headings: **Context**, **Decision**, **Consequences**, and **Alternatives considered** when alternatives materially informed the decision.
- Include **Status** (`Proposed`, `Accepted`, `Superseded`, or `Deprecated`) and **Date**.
- Do not rewrite an accepted decision to reflect a later choice. Create a later ADR that supersedes it and link the two records.

## Consequences

Architecture decisions become easy to find and review. Maintaining the decision record is part of making an architectural change.
