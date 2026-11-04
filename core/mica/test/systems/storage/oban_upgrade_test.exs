defmodule Systems.Storage.ObanUpgradeTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Mica.Repo
  alias Systems.Storage

  defmodule LegacyObanMigration do
    use Ecto.Migration

    def up do
      # Even Oban's V01 now includes suspended, so recreate the old enum
      # explicitly before invoking its otherwise current migration helpers.
      execute("""
      CREATE TYPE "#{prefix()}".oban_job_state AS ENUM (
        'available', 'scheduled', 'executing', 'retryable',
        'completed', 'discarded', 'cancelled'
      )
      """)

      Oban.Migrations.up(version: 13, prefix: prefix())
    end
  end

  @moduletag :capture_log

  test "existing Oban databases can enqueue unique delivery jobs after application migrations" do
    prefix = "oban_upgrade_#{System.unique_integer([:positive])}"

    Sandbox.unboxed_run(Repo, fn ->
      Sandbox.mode(Repo, {:shared, self()})
      Repo.query!(~s(CREATE SCHEMA "#{prefix}"))

      try do
        :ok =
          Ecto.Migrator.up(Repo, 0, LegacyObanMigration,
            prefix: prefix,
            migration_lock: false,
            log: false
          )

        # Model an existing deployment: the historical Oban migrations already
        # ran with an older dependency. A fresh database would hide this bug.
        migrations = application_oban_migrations()

        for {version, _module} <- migrations do
          if version <= 20_220_503_160_355 do
            Repo.query!(
              ~s|INSERT INTO "#{prefix}".schema_migrations (version, inserted_at) VALUES ($1, now())|,
              [version]
            )
          end
        end

        Ecto.Migrator.run(Repo, migrations, :up,
          all: true,
          prefix: prefix,
          migration_lock: false,
          log: false
        )

        config = %{Oban.config() | prefix: prefix}
        changeset = Storage.Delivery.new(%{file_id: "upgrade-regression.json"})

        assert {:ok, %Oban.Job{id: id}} =
                 Oban.Engines.Basic.insert_job(config, changeset, retry: false)

        assert is_integer(id)

        assert {:ok, %Oban.Job{id: ^id, conflict?: true}} =
                 Oban.Engines.Basic.insert_job(config, changeset, retry: false)
      after
        Repo.query!(~s(DROP SCHEMA "#{prefix}" CASCADE))
      end
    end)
  end

  defp application_oban_migrations do
    for path <- Path.wildcard("priv/repo/migrations/*oban*.exs") do
      version = path |> Path.basename() |> String.split("_") |> hd() |> String.to_integer()
      {:defmodule, _, [{:__aliases__, _, parts}, _]} = Code.string_to_quoted!(File.read!(path))
      module = Module.concat(parts)
      unless Code.ensure_loaded?(module), do: Code.compile_file(path)
      {version, module}
    end
  end
end
