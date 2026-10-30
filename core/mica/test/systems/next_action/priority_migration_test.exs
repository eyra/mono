defmodule Systems.NextAction.PriorityMigrationTest do
  use Core.DataCase, async: false

  alias Systems.NextAction

  @version 20_261_030_120_000
  @migration Core.Repo.Migrations.AddPriorityToNextActions
  @migration_file "priv/repo/migrations/20261030120000_add_priority_to_next_actions.exs"

  setup_all do
    unless Code.ensure_loaded?(@migration), do: Code.compile_file(@migration_file)
    {:ok, migration: @migration}
  end

  test "gives existing next actions the normal priority", %{migration: migration} do
    %{id: user_id} = Factories.insert!(:member)

    :ok = Ecto.Migrator.down(Repo, @version, migration, log: false, migration_lock: false)

    Repo.query!(
      """
      INSERT INTO next_actions (user_id, action, count, inserted_at, updated_at)
      VALUES ($1, 'Elixir.Systems.Account.NextActions.CompleteProfile', 1, now(), now())
      """,
      [user_id]
    )

    :ok = Ecto.Migrator.up(Repo, @version, migration, log: false, migration_lock: false)

    assert %{priority: :normal} = Repo.get_by!(NextAction.Model, user_id: user_id)
  end
end
