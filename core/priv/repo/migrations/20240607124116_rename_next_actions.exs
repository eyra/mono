defmodule Core.Repo.Migrations.RenameNextActions do
  use Ecto.Migration

  def change do
    migrate_next_actions()
  end

  def migrate_next_actions() do
    update(
      :next_actions,
      :action,
      "Elixir.Core.Accounts.NextActions.CompleteProfile",
      "Elixir.Systems.Account.NextActions.CompleteProfile"
    )
  end

  defp update(table, field, from, to) do
    execute("""
    UPDATE #{table} SET #{field} = '#{to}' WHERE #{field} = '#{from}';
    """)
  end
end
