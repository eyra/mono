defmodule MicaSaas.SaaSTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Nova.Snapshot

  test "Self's suite runs on Self, which composes and validates" do
    assert Mica.SaaS.module() == MicaSaas.SaaS
    assert Mica.SaaS.endpoint() == MicaSaasWeb.Endpoint
    assert Mica.SaaS.router() == MicaSaasWeb.Router

    composition = Mica.SaaS.validate!(MicaSaas.SaaS)
    assert composition.systems == Mica.SaaS.systems()
  end

  # The other snapshots read the prod config or run `mix compile`; the
  # snapshot-self CI job checks them all with `mix nova.snapshot`.
  for name <- ~w(routes.exs permissions.exs) do
    test "the Self build matches its #{name} snapshot" do
      {name, rendered} =
        List.keyfind(Snapshot.render(:mica_saas, counts: false), unquote(name), 0)

      rendered = without_test_routes(name, rendered)
      path = Snapshot.path(:mica_saas, name)

      case Snapshot.compare(name, path, rendered) do
        {:differs, message} ->
          flunk("""
          #{path} differs from the Self build:
          #{message}
          If the change is intended, run `BUNDLE=self MIX_ENV=dev mix nova.snapshot --update`.
          """)

        _same_or_reordered ->
          :ok
      end
    end
  end

  # Self's snapshots come from the dev build, which has no `/test` routes
  # (MicaWeb.Live.Routes adds them in the test env only).
  defp without_test_routes("routes.exs", rendered) do
    {routes, _} = Code.eval_string(rendered)
    inspect(Enum.reject(routes, &match?({_, "/test/" <> _, _, _, _, _}, &1)), limit: :infinity)
  end

  defp without_test_routes(_name, rendered), do: rendered
end
