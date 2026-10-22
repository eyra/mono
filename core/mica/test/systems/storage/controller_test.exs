defmodule Systems.Storage.ControllerTest do
  use CoreWeb.ConnCase, async: false

  import Mox

  alias Frameworks.Utility.PackmaticURLSource
  alias Systems.Storage
  alias Systems.Storage.BuiltIn.MockSpecial

  setup :verify_on_exit!

  setup do
    initial_config = Application.get_env(:core, Systems.Storage.BuiltIn)
    Application.put_env(:core, Systems.Storage.BuiltIn, special: MockSpecial)
    on_exit(fn -> Application.put_env(:core, Systems.Storage.BuiltIn, initial_config) end)

    {:ok, endpoint} =
      Storage.Public.prepare_endpoint(:builtin, %{key: "export_test"})
      |> Core.Repo.insert()

    %{endpoint: endpoint}
  end

  describe "export" do
    setup :login_as_member

    test "denies a member without access to the endpoint", %{conn: conn, endpoint: endpoint} do
      expect(MockSpecial, :list_files, 0, fn _folder -> [] end)

      conn = get(conn, ~p"/storage/endpoint/#{endpoint.id}/export")

      assert conn.status == 403
    end

    test "sends the zip to the endpoint owner", %{conn: conn, endpoint: endpoint} do
      :ok = Core.Authorization.assign_role(conn.assigns.current_user, endpoint, :owner)

      bypass = Bypass.open()
      Bypass.expect_once(bypass, "GET", "/donation.json", &Plug.Conn.resp(&1, 200, "{}"))
      Bypass.expect_once(bypass, "GET", "/empty.json", &Plug.Conn.resp(&1, 200, ""))

      expect(MockSpecial, :list_files, fn "export_test" ->
        [
          stored_file(bypass, "donation.json", 2),
          stored_file(bypass, "empty.json", 0)
        ]
      end)

      conn = get(conn, ~p"/storage/endpoint/#{endpoint.id}/export")

      assert conn.status == 200
      assert [disposition] = get_resp_header(conn, "content-disposition")
      assert URI.decode(disposition) =~ ~r/endpoint_#{endpoint.id}\.zip/

      {:ok, files} = :zip.unzip(conn.resp_body, [:memory])
      files = Map.new(files, fn {path, data} -> {Path.basename(to_string(path)), data} end)

      assert files == %{"donation.json" => "{}", "empty.json" => ""}
    end
  end

  # The shape S3 storage lists its files in.
  defp stored_file(%Bypass{port: port}, path, size) do
    %{
      source: {PackmaticURLSource, "http://localhost:#{port}/#{path}"},
      path: path,
      size: size,
      timestamp: DateTime.utc_now()
    }
  end
end
