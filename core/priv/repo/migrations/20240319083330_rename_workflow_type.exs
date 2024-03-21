defmodule Core.Repo.Migrations.RenameWorkflowType do
  use Ecto.Migration

  def up do
    update(:workflows, :type, "single_task", "many_optional")
  end

  def down do
    update(:workflows, :type, "many_optional", "single_task")
  end

  def update(table, field, new_value, old_value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{new_value}' WHERE #{field} = '#{old_value}';
    """)
  end
end
