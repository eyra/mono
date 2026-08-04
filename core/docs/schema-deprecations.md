# Schema Deprecations

Rolling registry of database columns that have been dropped from Elixir
schemas but are still present in the database. Following the
**deferred-drop pattern**: schema first, DB column drop later, in a
follow-up migration once the risk of any lingering reader has passed.

## How to add an entry

When you remove a `field(...)` from an Ecto schema without also writing
the `ALTER TABLE ... DROP COLUMN` migration in the same PR, add a row
below. Include:

- **Column** — `table.column`
- **Deprecated at** — commit SHA + date
- **Safe to drop after** — a milestone, date, or condition (e.g.
  "after N successful production releases", "after 2026-Q4")
- **Reason** — one line: why the field is no longer read/written
- **Ticket** — Flux issue tracking the drop-migration follow-up

Remove the entry once the drop-migration lands on `develop`.

For DB-side discoverability, also add a `COMMENT ON COLUMN` in the same
PR that removes the schema field:

```elixir
execute(
  ~s|COMMENT ON COLUMN fund_rewards.rejection_reason IS 'DEPRECATED 2026-08-03 — schema field removed; column drop pending'|
)
```

## Deprecated columns

| Column | Deprecated at | Safe to drop after | Reason | Ticket |
|---|---|---|---|---|
| `crew_tasks.accepted_at` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Task-level accept/reject retired; the reviewer's decision lives on `assignment_participation.accepted_at` | — |
| `crew_tasks.rejected_at` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Same as above; decision now on `assignment_participation.rejected_at` | — |
| `crew_tasks.rejected_category` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Categorized reject UI removed; the current decline form captures free-text only | — |
| `crew_tasks.rejected_message` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Same as above; free-text reason now on `assignment_participation.rejected_message` | — |
| `fund_rewards.rejection_reason` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Rejection reason moved to `assignment_participation.rejected_message` — Fund only records the outcome | — |
