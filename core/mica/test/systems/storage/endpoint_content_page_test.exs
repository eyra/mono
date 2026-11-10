defmodule Systems.Storage.EndpointContentPageTest do
  use MicaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Systems.Project
  alias Systems.Storage
  alias Systems.Storage.BuiltIn.LocalFS

  setup do
    initial_config = Application.get_env(:core, Systems.Storage.BuiltIn)
    Application.put_env(:core, Systems.Storage.BuiltIn, special: LocalFS)
    on_exit(fn -> Application.put_env(:core, Systems.Storage.BuiltIn, initial_config) end)
    :ok
  end

  describe "tabs" do
    setup do
      creator = Factories.insert!(:creator)

      {:ok, %{project: project, storage_setup: %{item: item}}} =
        Project.Assembly.create("Project", creator, :empty)

      %{project: project, item: item}
    end

    test "builtin storage shows Participants before Files and no Monitor", %{item: item} do
      assert tab_ids(item, item.storage_endpoint_id) == [:participants_view, :data_view]
    end

    test "external storage shows only Settings", %{item: item} do
      {:ok, yoda} =
        Storage.Public.prepare_endpoint(:yoda, %{
          url: "https://yoda.example.org",
          user: "user",
          password: "password"
        })
        |> Mica.Repo.insert()

      assert tab_ids(item, yoda.id) == [:settings_view]
    end
  end

  describe "page" do
    setup [:login_as_creator]

    test "opens on Participants without a tab in the url", %{conn: conn, user: user} do
      {:ok, %{storage_setup: %{endpoint: endpoint}}} =
        Project.Assembly.create("Project", user, :empty)

      {:ok, _view, html} = live(conn, ~p"/storage/endpoint/#{endpoint.id}/content")

      assert html =~ ~s(data-initial-tab="participants_view")
    end
  end

  defp tab_ids(%{node_id: node_id, id: item_id}, endpoint_id) do
    endpoint =
      Storage.Public.get_endpoint!(endpoint_id, Storage.EndpointModel.preload_graph(:down))

    %{tabs: tabs} =
      Storage.EndpointContentPageBuilder.view_model(endpoint, %{
        branch: %Project.Branch{node_id: node_id, item_id: item_id},
        fabric: %Fabric.Model{parent: nil, self: nil, children: nil},
        timezone: "Europe/Amsterdam"
      })

    Enum.map(tabs, & &1.id)
  end
end
