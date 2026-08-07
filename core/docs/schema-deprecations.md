# Schema Deprecations

Rolling registry of schema pieces (columns and enum values) that have
been retired in Elixir but are still present in the database. Following
the **deferred-drop pattern**: schema first, DB drop later, in a
follow-up migration once the risk of any lingering reader has passed
and any required data backfill has landed.

## How to add an entry

### Deprecated columns

When you remove a `field(...)` from an Ecto schema without also writing
the `ALTER TABLE ... DROP COLUMN` migration in the same PR, add a row
to the columns table. Include:

- **Column** — `table.column`
- **Deprecated at** — commit SHA + date
- **Safe to drop after** — a milestone, date, or condition (e.g.
  "after N successful production releases", "after 2026-Q4")
- **Reason** — one line: why the field is no longer read/written
- **Ticket** — Flux issue tracking the drop-migration follow-up

For DB-side discoverability, also add a `COMMENT ON COLUMN` in the same
PR that removes the schema field:

```elixir
execute(
  ~s|COMMENT ON COLUMN fund_rewards.rejection_reason IS 'DEPRECATED 2026-08-03 — schema field removed; column drop pending'|
)
```

### Deprecated enum values

When you stop writing an enum value (but existing rows still carry it),
add a row to the enum-values table. Unlike columns, enum-value drops
usually need a **data backfill** first — old rows must be either
converted to a surviving value or have their information migrated
elsewhere. Include:

- **Enum + value** — `table.column = :value`
- **Deprecated at** — commit SHA + date
- **Backfill required** — what has to happen to old rows before the
  enum value can be dropped (or "none" if old rows can just be ignored)
- **Reason** — one line: why nothing writes this value anymore
- **Ticket** — Flux issue tracking the backfill + drop follow-up

Remove the entry once the drop-migration lands on `develop`.

## Deprecated columns

| Column | Deprecated at | Safe to drop after | Reason | Ticket |
|---|---|---|---|---|
| `crew_tasks.accepted_at` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Task-level accept/reject retired; the reviewer's decision lives on `assignment_participation.accepted_at` | — |
| `crew_tasks.rejected_at` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Same as above; decision now on `assignment_participation.rejected_at` | — |
| `crew_tasks.rejected_category` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Categorized reject UI removed; the current decline form captures free-text only | — |
| `crew_tasks.rejected_message` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Same as above; free-text reason now on `assignment_participation.rejected_message` | — |
| `fund_rewards.rejection_reason` | `40dfa20a3` (2026-08-03) | 1 production release with Participation-driven review live | Rejection reason moved to `assignment_participation.rejected_message` — Fund only records the outcome | — |

## Deprecated enum values

| Enum + value | Deprecated at | Backfill required | Reason | Ticket |
|---|---|---|---|---|
| `crew_tasks.status = :accepted` | `40dfa20a3` (2026-08-03) | Backfill `assignment_participation.accepted_at` from the historical task row (use `crew_tasks.updated_at` or the corresponding reward's approval timestamp), then convert lingering `:accepted` task rows to `:completed`. | Task-level accept is retired; the reviewer's decision lives on `assignment_participation.accepted_at`. Old rows still surface via `Assignment.Public.status/2` and `Crew.TaskStatus.finished_states/0`. | — |
| `crew_tasks.status = :rejected` | `40dfa20a3` (2026-08-03) | Backfill `assignment_participation.rejected_at` (+ `.rejected_message` if available) from the historical task row, then convert lingering `:rejected` task rows to `:completed`. | Same as above; decision now on `assignment_participation.rejected_at`. | — |
