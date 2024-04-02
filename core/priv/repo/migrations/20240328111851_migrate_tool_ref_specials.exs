defmodule Core.Repo.Migrations.MigrateToolRefSpecials do
  use Ecto.Migration

  def up do
    update(:tool_refs, :special, "request_manual", "request")
    update(:tool_refs, :special, "download_manual", "download")
  end

  def down do
    update(:tool_refs, :special, "request", "request_manual")
    update(:tool_refs, :special, "download", "download_manual")
  end

  def update(table, field, new_value, old_value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{new_value}' WHERE #{field} = '#{old_value}';
    """)
  end
end
