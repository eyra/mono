defmodule Systems.Storage.DonationPageTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Systems.Storage
  alias Systems.Storage.BuiltIn.LocalFS

  @result "participant=2_key=run1/cogflex/practice1.json"

  setup :login_as_member

  setup %{conn: conn} do
    initial_config = Application.get_env(:core, Systems.Storage.BuiltIn)
    Application.put_env(:core, Systems.Storage.BuiltIn, special: LocalFS)

    folder = "project_node=#{System.unique_integer([:positive])}"

    on_exit(fn ->
      Application.put_env(:core, Systems.Storage.BuiltIn, initial_config)
      File.rm_rf!(Path.join(LocalFS.get_root_path(), folder))
    end)

    json =
      ~s({"promptId":"practice1","responses":[{"trial_index":1,"rt_ms":2057},{"trial_index":2,"rt_ms":980}]})

    :ok = LocalFS.store(folder, @result, json)

    {:ok, endpoint} =
      Storage.Public.prepare_endpoint(:builtin, %{key: folder}) |> Core.Repo.insert()

    %{conn: conn, endpoint: endpoint}
  end

  defp donation_path(endpoint, file),
    do: ~p"/storage/endpoint/#{endpoint.id}/donation?#{[path: file]}"

  test "shows the owner the responses of a donation as a table", %{conn: conn, endpoint: endpoint} do
    :ok = Core.Authorization.assign_role(conn.assigns.current_user, endpoint, :owner)

    {:ok, view, _html} = live(conn, donation_path(endpoint, @result))

    assert view |> element("[data-testid='table-block']") |> render() =~ "rt_ms"
  end

  test "titles the donation with its key without the session", %{conn: conn, endpoint: endpoint} do
    :ok = Core.Authorization.assign_role(conn.assigns.current_user, endpoint, :owner)

    {:ok, view, _html} = live(conn, donation_path(endpoint, @result))

    assert view |> element("[data-testid='header-block']") |> render() =~ "cogflex / practice1"
  end

  test "does not read a path the endpoint does not list", %{conn: conn, endpoint: endpoint} do
    :ok = Core.Authorization.assign_role(conn.assigns.current_user, endpoint, :owner)

    {:ok, view, _html} = live(conn, donation_path(endpoint, "../../secret.json"))

    assert has_element?(view, "[data-testid='message-block']")
  end

  test "denies a member without access to the endpoint", %{conn: conn, endpoint: endpoint} do
    assert {:error, {_redirect, _}} = live(conn, donation_path(endpoint, @result))
  end
end
