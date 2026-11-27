defmodule Mica.Repo.Migrations.AddRegistryRefs do
  @moduledoc """
  code-registry, release 1: a tool ref and a project item store a registered type
  name and an id (`Mica.Tool`, `Mica.ProjectItem`), next to today's one column per
  type. Nullable and without a default: adding them only changes the catalogue.

  The next migrations keep both sides equal on every write (trigger), backfill
  them, and constrain and index them. Nothing reads the new columns yet.
  """
  use Ecto.Migration

  def up do
    # A brief ACCESS EXCLUSIVE lock; fail rather than queue behind a long transaction.
    execute("SET LOCAL lock_timeout = '5s'")

    execute("ALTER TABLE tool_refs ADD COLUMN tool_type varchar(255), ADD COLUMN tool_id bigint")

    execute(
      "ALTER TABLE project_items ADD COLUMN item_type varchar(255), ADD COLUMN item_id bigint"
    )
  end

  def down do
    execute("SET LOCAL lock_timeout = '5s'")
    execute("ALTER TABLE project_items DROP COLUMN item_type, DROP COLUMN item_id")
    execute("ALTER TABLE tool_refs DROP COLUMN tool_type, DROP COLUMN tool_id")
  end
end
