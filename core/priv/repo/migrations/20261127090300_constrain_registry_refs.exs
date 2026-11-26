defmodule Mica.Repo.Migrations.ConstrainRegistryRefs do
  @moduledoc """
  code-registry, release 1: every tool ref and project item references something,
  one ref per tool, one item per target, and one storage item per project node.

  - `tool_refs_tool_required`, `project_items_item_required`: a type, and an id for
    every type except the reserved `none`. They replace the `must_have_at_least_one_*`
    checks, which never fire (`x <> NULL`), and let release 2 set NOT NULL without a
    scan. The trigger fills type and id before a check runs, so older code passes.
  - Unique `(tool_type, tool_id)` and `(item_type, item_id)`.
  - Unique `(node_id) WHERE item_type = 'storage_endpoint'`: a project's storage item
    is the storage-endpoint item of its node (mono#1984's "Data" item), with no
    name match. A project may have none.

  Not transactional, so each step commits on its own: `NOT VALID` takes a brief lock
  without a scan, `VALIDATE` scans while writes continue, and the indexes are built
  concurrently.
  """
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute("""
    ALTER TABLE tool_refs ADD CONSTRAINT tool_refs_tool_required
      CHECK (tool_type IS NOT NULL AND (tool_id IS NOT NULL OR tool_type = 'none')) NOT VALID
    """)

    execute("ALTER TABLE tool_refs VALIDATE CONSTRAINT tool_refs_tool_required")

    execute("""
    ALTER TABLE project_items ADD CONSTRAINT project_items_item_required
      CHECK (item_type IS NOT NULL AND (item_id IS NOT NULL OR item_type = 'none')) NOT VALID
    """)

    execute("ALTER TABLE project_items VALIDATE CONSTRAINT project_items_item_required")

    create_if_not_exists(
      unique_index(:tool_refs, [:tool_type, :tool_id],
        name: :tool_refs_tool_type_tool_id_index,
        concurrently: true
      )
    )

    create_if_not_exists(
      unique_index(:project_items, [:item_type, :item_id],
        name: :project_items_item_type_item_id_index,
        concurrently: true
      )
    )

    create_if_not_exists(
      unique_index(:project_items, [:node_id],
        name: :project_items_storage_per_node_index,
        where: "item_type = 'storage_endpoint'",
        concurrently: true
      )
    )
  end

  def down do
    drop_if_exists(
      index(:project_items, [:node_id],
        name: :project_items_storage_per_node_index,
        concurrently: true
      )
    )

    drop_if_exists(
      index(:project_items, [:item_type, :item_id],
        name: :project_items_item_type_item_id_index,
        concurrently: true
      )
    )

    drop_if_exists(
      index(:tool_refs, [:tool_type, :tool_id],
        name: :tool_refs_tool_type_tool_id_index,
        concurrently: true
      )
    )

    execute("ALTER TABLE project_items DROP CONSTRAINT IF EXISTS project_items_item_required")
    execute("ALTER TABLE tool_refs DROP CONSTRAINT IF EXISTS tool_refs_tool_required")
  end
end
