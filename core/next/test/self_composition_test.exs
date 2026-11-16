defmodule Next.SelfCompositionTest do
  # Self (MicaSaas.SaaS) composes some of Next's systems, but runs only its own
  # endpoint, MicaSaasWeb.Endpoint. Code of those systems that reaches
  # NextWeb.Endpoint (`~p`, `url/1`, `static_path/1`, `@endpoint`) raises in a
  # Self build. Tests build Next only, so these tests stand in for Self.

  # Not async: it replaces the composition's endpoint for every process.
  use ExUnit.Case, async: false

  alias Next.Systems.Graphite

  # The modules of the Next systems in Self's composition.
  defp self_composed_next_modules do
    namespaces =
      for system <- MicaSaas.SaaS.systems(),
          ["Next" | _] = namespace <- [Frameworks.Utility.Module.system_namespace(system)],
          do: namespace

    for module <- Application.spec(:mica, :modules),
        Enum.any?(namespaces, &List.starts_with?(Module.split(module), &1)),
        do: module
  end

  defp names?(module, atom) do
    {:ok, {^module, [atoms: atoms]}} = :beam_lib.chunks(:code.which(module), [:atoms])
    Enum.any?(atoms, fn {_index, name} -> name == atom end)
  end

  test "no module of a Next system that Self composes names NextWeb.Endpoint" do
    modules = self_composed_next_modules()
    assert Next.Systems.Graphite.Private in modules
    assert Next.Systems.Student.Pool.SubmissionPageBuilder in modules

    assert Enum.filter(modules, &names?(&1, NextWeb.Endpoint)) == []
  end

  describe "with Self's endpoint running" do
    # MicaSaasWeb.Endpoint as Self runs it, under a path prefix so that a path
    # built for it differs from one built for NextWeb.Endpoint.
    setup do
      config =
        "mica_saas/config/config.exs"
        |> Config.Reader.read!(env: :test)
        |> get_in([:mica, MicaSaasWeb.Endpoint])
        |> Keyword.merge(server: false, url: [host: "localhost", path: "/self"])

      previous_config = Application.get_env(:mica, MicaSaasWeb.Endpoint)
      Application.put_env(:mica, MicaSaasWeb.Endpoint, config)
      start_supervised!(MicaSaasWeb.Endpoint)

      previous = Mica.SaaS.put_composition(endpoint: MicaSaasWeb.Endpoint)

      on_exit(fn ->
        Mica.SaaS.put_composition(previous)

        if previous_config,
          do: Application.put_env(:mica, MicaSaasWeb.Endpoint, previous_config),
          else: Application.delete_env(:mica, MicaSaasWeb.Endpoint)
      end)
    end

    test "a Graphite leaderboard's preview link is built for Self's endpoint" do
      leaderboard = %Graphite.LeaderboardModel{id: 42}
      assert Graphite.Private.get_preview_url(leaderboard) == "/self/graphite/leaderboard/42"
    end
  end
end
