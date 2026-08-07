defmodule Core.Repo.Migrations.RenamePendingPayoutNextAction do
  use Ecto.Migration

  @old "Elixir.Systems.Fund.NextActions.PendingPayout"
  @new "Elixir.Systems.Assignment.NextActions.PendingContributions"

  def up do
    execute("UPDATE next_actions SET action = '#{@new}' WHERE action = '#{@old}'")
  end

  def down do
    execute("UPDATE next_actions SET action = '#{@old}' WHERE action = '#{@new}'")
  end
end
