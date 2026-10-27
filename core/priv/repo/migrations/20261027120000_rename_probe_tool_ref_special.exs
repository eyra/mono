defmodule Core.Repo.Migrations.RenameProbeToolRefSpecial do
  use Ecto.Migration

  def up do
    update(:tool_refs, :special, "cognitive_tool", "probe")
  end

  def down do
    update(:tool_refs, :special, "probe", "cognitive_tool")
  end

  def update(table, field, new_value, old_value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{new_value}' WHERE #{field} = '#{old_value}';
    """)
  end
end
