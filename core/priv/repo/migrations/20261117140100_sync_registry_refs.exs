defmodule Mica.Repo.Migrations.SyncRegistryRefs do
  @moduledoc """
  code-registry, releases 1 to 3: a trigger keeps a row's type and id equal to its
  per-type column on every insert and update, so older and newer code can run side
  by side during a deploy and every release-2 PR can be reverted on its own.

  The side the writer changed wins:

    * older code sets a per-type column (`feldspar_tool_id`): the trigger fills
      `tool_type`/`tool_id`
    * newer code sets `tool_type`/`tool_id`: the trigger fills the per-type column,
      so its foreign key still holds and older code still finds it

  A row without a type (written before the backfill) always takes its per-type
  column, so no write can clear it. The reserved type `none` (a ref that references
  nothing, left from before 2023) is never derived: a new row that references
  nothing gets no type, which `tool_refs_tool_required` refuses.

  Release 3 drops the trigger together with the per-type columns.
  """
  use Ecto.Migration

  def up do
    execute("""
    CREATE FUNCTION registry_sync_tool_refs() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
      IF NEW.tool_type IS NULL OR (NEW.tool_id IS NULL AND NEW.tool_type <> 'none')
         OR (TG_OP = 'UPDATE' AND (NEW.alliance_tool_id, NEW.document_tool_id, NEW.feldspar_tool_id,
             NEW.graphite_tool_id, NEW.instruction_tool_id, NEW.lab_tool_id, NEW.manual_tool_id,
             NEW.zircon_screening_tool_id) IS DISTINCT FROM (OLD.alliance_tool_id, OLD.document_tool_id,
             OLD.feldspar_tool_id, OLD.graphite_tool_id, OLD.instruction_tool_id, OLD.lab_tool_id,
             OLD.manual_tool_id, OLD.zircon_screening_tool_id)) THEN
        NEW.tool_type := CASE
          WHEN NEW.alliance_tool_id IS NOT NULL THEN 'alliance'
          WHEN NEW.document_tool_id IS NOT NULL THEN 'document'
          WHEN NEW.feldspar_tool_id IS NOT NULL THEN 'feldspar'
          WHEN NEW.graphite_tool_id IS NOT NULL THEN 'graphite'
          WHEN NEW.instruction_tool_id IS NOT NULL THEN 'instruction'
          WHEN NEW.lab_tool_id IS NOT NULL THEN 'lab'
          WHEN NEW.manual_tool_id IS NOT NULL THEN 'manual'
          WHEN NEW.zircon_screening_tool_id IS NOT NULL THEN 'zircon_screening'
        END;
        NEW.tool_id := coalesce(NEW.alliance_tool_id, NEW.document_tool_id, NEW.feldspar_tool_id,
          NEW.graphite_tool_id, NEW.instruction_tool_id, NEW.lab_tool_id, NEW.manual_tool_id,
          NEW.zircon_screening_tool_id);
      ELSE
        NEW.alliance_tool_id := CASE WHEN NEW.tool_type = 'alliance' THEN NEW.tool_id END;
        NEW.document_tool_id := CASE WHEN NEW.tool_type = 'document' THEN NEW.tool_id END;
        NEW.feldspar_tool_id := CASE WHEN NEW.tool_type = 'feldspar' THEN NEW.tool_id END;
        NEW.graphite_tool_id := CASE WHEN NEW.tool_type = 'graphite' THEN NEW.tool_id END;
        NEW.instruction_tool_id := CASE WHEN NEW.tool_type = 'instruction' THEN NEW.tool_id END;
        NEW.lab_tool_id := CASE WHEN NEW.tool_type = 'lab' THEN NEW.tool_id END;
        NEW.manual_tool_id := CASE WHEN NEW.tool_type = 'manual' THEN NEW.tool_id END;
        NEW.zircon_screening_tool_id := CASE WHEN NEW.tool_type = 'zircon_screening' THEN NEW.tool_id END;
      END IF;
      RETURN NEW;
    END $$
    """)

    execute("""
    CREATE TRIGGER registry_sync BEFORE INSERT OR UPDATE ON tool_refs
      FOR EACH ROW EXECUTE FUNCTION registry_sync_tool_refs()
    """)

    execute("""
    CREATE FUNCTION registry_sync_project_items() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
      IF NEW.item_type IS NULL OR (NEW.item_id IS NULL AND NEW.item_type <> 'none')
         OR (TG_OP = 'UPDATE' AND (NEW.assignment_id, NEW.advert_id, NEW.leaderboard_id,
             NEW.storage_endpoint_id) IS DISTINCT FROM (OLD.assignment_id, OLD.advert_id,
             OLD.leaderboard_id, OLD.storage_endpoint_id)) THEN
        NEW.item_type := CASE
          WHEN NEW.assignment_id IS NOT NULL THEN 'assignment'
          WHEN NEW.advert_id IS NOT NULL THEN 'advert'
          WHEN NEW.leaderboard_id IS NOT NULL THEN 'leaderboard'
          WHEN NEW.storage_endpoint_id IS NOT NULL THEN 'storage_endpoint'
        END;
        NEW.item_id := coalesce(NEW.assignment_id, NEW.advert_id, NEW.leaderboard_id,
          NEW.storage_endpoint_id);
      ELSE
        NEW.assignment_id := CASE WHEN NEW.item_type = 'assignment' THEN NEW.item_id END;
        NEW.advert_id := CASE WHEN NEW.item_type = 'advert' THEN NEW.item_id END;
        NEW.leaderboard_id := CASE WHEN NEW.item_type = 'leaderboard' THEN NEW.item_id END;
        NEW.storage_endpoint_id := CASE WHEN NEW.item_type = 'storage_endpoint' THEN NEW.item_id END;
      END IF;
      RETURN NEW;
    END $$
    """)

    execute("""
    CREATE TRIGGER registry_sync BEFORE INSERT OR UPDATE ON project_items
      FOR EACH ROW EXECUTE FUNCTION registry_sync_project_items()
    """)
  end

  # Dropped before the columns (AddRegistryRefs.down/0 runs after this one), or the
  # next write would fail on the missing columns.
  def down do
    execute("DROP TRIGGER IF EXISTS registry_sync ON project_items")
    execute("DROP TRIGGER IF EXISTS registry_sync ON tool_refs")
    execute("DROP FUNCTION IF EXISTS registry_sync_project_items()")
    execute("DROP FUNCTION IF EXISTS registry_sync_tool_refs()")
  end
end
