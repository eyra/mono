defmodule Systems.Storage.EndpointSettingsViewTest do
  # Mocks the URL check.
  use MicaWeb.ConnCase, async: false

  import Mock
  import Phoenix.LiveViewTest

  alias Frameworks.Utility.OutboundUrl
  alias Mica.Factories
  alias Mica.Repo
  alias Systems.Storage

  @moduletag :capture_log

  @form "form[id$='_yoda_endpoint_form']"

  setup :login_as_creator

  setup %{user: user} do
    %{root: root} = Factories.insert!(:project, %{name: "Project"})

    {:ok, endpoint} = Storage.Public.prepare_endpoint(:yoda, %{}) |> Repo.insert()

    Factories.insert!(:project_item, %{
      name: "Yoda",
      project_path: [],
      node_id: root.id,
      storage_endpoint_id: endpoint.id
    })

    :ok = Mica.Authorization.assign_role(user, endpoint, :owner)

    %{endpoint: endpoint}
  end

  describe "the owner saving the Yoda folder url" do
    test "is refused for a private address", %{conn: conn, endpoint: endpoint} do
      {:ok, view, _html} = live(conn, ~p"/storage/endpoint/#{endpoint.id}/content")

      html = view |> element(@form) |> render_submit(params("https://10.1.2.3/folder"))

      assert html =~ "Please use an address that exists on the public internet"
      assert %{url: nil} = Repo.get!(Storage.Yoda.EndpointModel, endpoint.yoda_id)
    end

    test "is refused for a plain http address", %{conn: conn, endpoint: endpoint} do
      {:ok, view, _html} = live(conn, ~p"/storage/endpoint/#{endpoint.id}/content")

      html = view |> element(@form) |> render_submit(params("http://1.1.1.1/folder"))

      assert html =~ "Please use an address that starts with https://"
      assert %{url: nil} = Repo.get!(Storage.Yoda.EndpointModel, endpoint.yoda_id)
    end

    test "is saved for a public address", %{conn: conn, endpoint: endpoint} do
      with_mock OutboundUrl, [:passthrough], request: fn _, _, _, _, _ -> {:ok, 200, []} end do
        {:ok, view, _html} = live(conn, ~p"/storage/endpoint/#{endpoint.id}/content")

        view |> element(@form) |> render_submit(params("https://1.1.1.1/folder"))

        assert %{url: "https://1.1.1.1/folder"} =
                 Repo.get!(Storage.Yoda.EndpointModel, endpoint.yoda_id)
      end
    end
  end

  defp params(url) do
    %{"endpoint_model" => %{"url" => url, "user" => "researcher", "password" => "secret"}}
  end
end
