defmodule Next.RenameStoredModuleNamesTest do
  # The code-rename migration rewrites the module names stored before the rename
  # (Nova step code-rename). Rows are written under the old names with the migration
  # rolled back, then migrated, inside the test's transaction.
  use Mica.DataCase, async: false
  use Mica.FeatureFlags.Test

  alias Mica.Repo
  alias Next.Systems.Announcement
  alias Systems.NextAction

  @migration Mica.Repo.Migrations.RenameStoredModuleNames
  @migration_file Path.wildcard("priv/repo/migrations/*_rename_stored_module_names.exs")
                  |> List.first()
  @version @migration_file |> Path.basename() |> String.split("_") |> hd() |> String.to_integer()

  setup_all do
    unless Code.ensure_loaded?(@migration), do: Code.compile_file(@migration_file)
    :ok
  end

  setup do
    set_feature_flag(:announcements, true)
    :ok = Ecto.Migrator.down(Repo, @version, @migration, log: false, migration_lock: false)
    %{user: Factories.insert!(:member)}
  end

  defp migrate,
    do: :ok = Ecto.Migrator.up(Repo, @version, @migration, log: false, migration_lock: false)

  test "a next action stored under its old module name is shown after the migration", %{
    user: user
  } do
    {:ok, announcement} =
      Announcement.Public.create_announcement(Factories.insert!(:admin), %{
        title: "March release",
        kind: :release_notes,
        summary: "What changed",
        body: "<div>New features</div>",
        priority: :normal
      })

    Repo.query!(
      """
      INSERT INTO next_actions (user_id, action, key, params, count, inserted_at, updated_at)
      VALUES ($1, 'Elixir.Systems.Announcement.NextActions.ReadAnnouncement', $2, $3, 1, now(), now())
      """,
      [user.id, to_string(announcement.id), %{"announcement_id" => announcement.id}]
    )

    migrate()

    next_action = Repo.get_by!(NextAction.Model, user_id: user.id)
    assert next_action.action == "Elixir.Next.Systems.Announcement.NextActions.ReadAnnouncement"

    assert %{title: "March release", action_type: Announcement.NextActions.ReadAnnouncement} =
             NextAction.Public.to_view_model(next_action)
  end

  test "a next action of a Mica system keeps its name", %{user: user} do
    action = "Elixir.Systems.Account.NextActions.CompleteProfile"

    Repo.query!(
      "INSERT INTO next_actions (user_id, action, count, inserted_at, updated_at) VALUES ($1, $2, 1, now(), now())",
      [user.id, action]
    )

    migrate()

    assert %{action: ^action} = Repo.get_by!(NextAction.Model, user_id: user.id)
  end

  test "a job that has not run gets the renamed worker; a completed one keeps its name" do
    for state <- ~w(available completed) do
      Repo.query!(
        "INSERT INTO oban_jobs (queue, worker, args, state) VALUES ('default', 'Systems.Announcement.DeliverJob', '{}', $1)",
        [state]
      )
    end

    migrate()

    assert %{rows: rows} = Repo.query!("SELECT state, worker FROM oban_jobs ORDER BY state")

    assert rows == [
             ["available", "Next.Systems.Announcement.DeliverJob"],
             ["completed", "Systems.Announcement.DeliverJob"]
           ]
  end

  test "an authentication entity of a renamed module gets the new name" do
    Repo.query!(
      "INSERT INTO authentication_entity (identifier, inserted_at, updated_at) VALUES ('Elixir.Core.Authentication.Actor:1', now(), now())"
    )

    migrate()

    assert %{rows: [["Elixir.Mica.Authentication.Actor:1"]]} =
             Repo.query!("SELECT identifier FROM authentication_entity")
  end

  test "the migration knows every Next system the rename script knows" do
    script = File.read!("scripts/rename_mica.exs")

    for attribute <- ~w(next_systems next_bundle_systems) do
      [_, names] = Regex.run(~r/@#{attribute} ~w\(([^)]*)\)/, script)
      migration = File.read!(@migration_file)
      [_, migration_names] = Regex.run(~r/@#{attribute} ~w\(([^)]*)\)/, migration)
      assert String.split(names) == String.split(migration_names)
    end
  end

  test "every rename changes the name" do
    # Loaded in setup_all, so not known at compile time.
    renames = apply(@migration, :renames, [])

    assert renames != []
    assert Enum.all?(renames, fn {from, to} -> from != to end)
  end
end
