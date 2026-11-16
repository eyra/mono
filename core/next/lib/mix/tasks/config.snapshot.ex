defmodule Mix.Tasks.Config.Snapshot do
  @shortdoc "Check or update the runtime config snapshots per environment"

  @moduledoc """
  Evaluates `config/runtime.exs` with the environment variables of each
  deployment (fixtures in `next/test/config/env/`) and compares the result
  with the committed snapshots in `next/test/config/snapshots/`.

      BUNDLE=next mix config.snapshot            # fail when a snapshot differs
      BUNDLE=next mix config.snapshot --update   # rewrite the snapshots

  It runs in the test env, which configures a SaaS only through BUNDLE. The
  snapshots are of Next's config, so it refuses to run without BUNDLE=next.

  The same check runs in `mix test` (`next/test/config/runtime_snapshot_test.exs`).
  A changed snapshot, above all `prod`, is a change to what that environment
  runs: review the diff before committing it.
  """

  use Mix.Task

  alias Mica.RuntimeConfig.Snapshot

  @dir "next/test/config"

  # {fixture and snapshot name, config env}
  @fixtures [
    {"prod", :prod},
    {"prod-all-oban-plugins", :prod},
    {"prod-migrate", :prod},
    {"staging", :prod},
    {"dev", :prod},
    {"local", :dev}
  ]

  def fixtures do
    Enum.map(@fixtures, fn {name, config_env} ->
      %{
        name: name,
        env_file: Path.join([@dir, "env", "#{name}.env"]),
        snapshot: Path.join([@dir, "snapshots", "#{name}.exs"]),
        config_env: config_env
      }
    end)
  end

  def render(%{env_file: env_file, config_env: config_env}) do
    "config/runtime.exs"
    |> Snapshot.evaluate(Snapshot.read_env_file(env_file), config_env)
    |> Snapshot.render()
  end

  @doc """
  Refuses a build that is not Next's: without Next's config (`next/config/config.exs`,
  which only BUNDLE=next imports in the test env) the snapshots come out wrong.
  """
  def check_saas!(Next.SaaS), do: :ok

  def check_saas!(saas) do
    Mix.raise(
      "config.snapshot renders Next's config, but this build configures #{inspect(saas)}; " <>
        "run BUNDLE=next mix config.snapshot"
    )
  end

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [update: :boolean])
    Mix.Task.run("app.config")
    check_saas!(Mica.Env.get(:saas))

    changed =
      for fixture <- fixtures(), reduce: [] do
        changed ->
          rendered = render(fixture)

          cond do
            File.read(fixture.snapshot) == {:ok, rendered} ->
              changed

            opts[:update] ->
              File.mkdir_p!(Path.dirname(fixture.snapshot))
              File.write!(fixture.snapshot, rendered)
              Mix.shell().info("updated #{fixture.snapshot}")
              changed

            true ->
              [fixture.snapshot | changed]
          end
      end

    if changed != [] do
      Mix.raise("""
      Runtime config differs from the snapshot for: #{Enum.join(Enum.reverse(changed), ", ")}
      Review the change, then run `BUNDLE=next mix config.snapshot --update` and commit the diff.
      """)
    end
  end
end
