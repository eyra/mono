defmodule Systems.Storage.EndpointParticipantsViewTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Systems.Storage
  alias Systems.Storage.BuiltIn.LocalFS

  setup do
    initial_config = Application.get_env(:core, Systems.Storage.BuiltIn)
    Application.put_env(:core, Systems.Storage.BuiltIn, special: LocalFS)

    folder = "project_node=#{System.unique_integer([:positive])}"

    on_exit(fn ->
      Application.put_env(:core, Systems.Storage.BuiltIn, initial_config)
      File.rm_rf!(Path.join(LocalFS.get_root_path(), folder))
    end)

    {:ok, endpoint} =
      Storage.Public.prepare_endpoint(:builtin, %{key: folder}) |> Core.Repo.insert()

    %{folder: folder, endpoint: endpoint}
  end

  test "shows one row per participant", %{folder: folder, endpoint: endpoint} do
    :ok = LocalFS.store(folder, "participant=p1_source=cogflex_key=run1/summary.json", "{}")
    :ok = LocalFS.store(folder, "participant=p1_source=cogflex_key=run2/summary.json", "{}")
    :ok = LocalFS.store(folder, "participant=p2_source=cogflex_key=run1/summary.json", "{}")

    html = render_view(endpoint)

    assert html =~ "p1"
    assert html =~ "p2"
    assert html =~ ~r|<span class="text-primary">\s*2\s*</span>|
  end

  test "shows the empty description without donations", %{endpoint: endpoint} do
    assert render_view(endpoint) =~ "No donations stored yet"
  end

  defp render_view(endpoint) do
    render_component(Storage.EndpointParticipantsView, %{
      id: :participants_view,
      endpoint: endpoint,
      timezone: "Europe/Amsterdam"
    })
  end
end
