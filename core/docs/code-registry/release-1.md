# code-registry, release 1: deploy notes and rollback

Release 1 of the code-registry data migration (`docs/nova-migration/plan.md`, step code-registry). No user-visible change: nothing reads the new columns yet.

## What the release does

Four migrations run in `predeploy`, in this order:

| Migration | What | Lock |
|---|---|---|
| `20261127090000_add_registry_refs` | adds `tool_refs.tool_type`/`tool_id` and `project_items.item_type`/`item_id`, nullable | brief ACCESS EXCLUSIVE, catalogue only; `lock_timeout` 5 s |
| `20261127090100_sync_registry_refs` | the `registry_sync` trigger on both tables, which keeps the new columns equal to the per-type columns on every write | brief |
| `20261127090200_backfill_registry_refs` | fills the new columns. It refuses to run if a row sets two per-type columns. A row that sets none gets the reserved type `none` (6 tool refs on production, 17 Nov) | row locks for the length of one `UPDATE` per table |
| `20261127090300_constrain_registry_refs` | the `*_required` checks (`NOT VALID`, then `VALIDATE`) and three unique indexes, built `CONCURRENTLY` | writes continue |

At production size (1,751 tool refs, 1,157 project items) every statement takes well under a second.

## Before the deploy

- The production-copy rehearsal has passed (`run-rehearsal.sh 1`, kept by the Nova migration project, thread t-0047).
- The release goes out at the merge moment agreed with Next.

## After the deploy

1. Run the verification query read-only on production: `core/docs/code-registry/registry-verify.sql`.
   - The four lines of the first query are `0`.
   - In the second query, `tool_type | none` is `6` (or whatever count the production shape query gave), and the other counts match.
2. To run the daily integrity check (`registry_integrity`, 03:30): add `registry_integrity` to `ENABLED_OBAN_PLUGINS` on each deployment.
   - The check only reports, as an error log when a reference doesn't hold. It never removes anything.
   - The same check by hand: `mix mica.registry.check`.

## Rollback

Two steps; in most cases the first is enough.

1. **Revert the code.** Redeploy the previous release. Nothing reads the new columns, and the trigger keeps filling them underneath, so the old behaviour is back at once.
2. **If the database must go back too,** run the downs. They go in reverse order: the checks and indexes first, then the trigger, then the columns.

   ```sh
   bin/core eval 'Mica.Release.rollback(Mica.Repo, 20261127090000)'
   ```

   `rollback` takes down every migration from that version on. If any later migration has been deployed since, roll back per version with `Ecto.Migrator.down/4` for each of these four, never with `to:`:

   ```sh
   bin/core eval '
   Application.load(:mica)
   dir = Application.app_dir(:mica, "priv/repo/migrations")

   Ecto.Migrator.with_repo(Mica.Repo, fn repo ->
     for file <- ~w(20261127090300_constrain_registry_refs 20261127090200_backfill_registry_refs
                    20261127090100_sync_registry_refs 20261127090000_add_registry_refs) do
       [{module, _}] = Code.require_file(file <> ".exs", dir)
       :ok = Ecto.Migrator.down(repo, String.to_integer(binary_part(file, 0, 14)), module)
     end
   end)'
   ```

   - The trigger is dropped before the columns: a write between the two would otherwise fail on the missing columns.
   - The backfill's down does nothing, because dropping the columns removes what it wrote.
   - All four downs were rehearsed on a copy of production-shaped data: up, down, up.
