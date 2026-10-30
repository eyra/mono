defmodule Systems.Storage.BuiltIn.LocalFSTest do
  use MicaWeb.ConnCase, async: false

  alias Systems.Storage
  alias Systems.Storage.BuiltIn.LocalFS

  setup do
    initial_config = Application.get_env(:mica, Systems.Storage.BuiltIn)
    Application.put_env(:mica, Systems.Storage.BuiltIn, special: LocalFS)

    folder = "project_node=#{System.unique_integer([:positive])}"

    on_exit(fn ->
      Application.put_env(:mica, Systems.Storage.BuiltIn, initial_config)
      File.rm_rf!(Path.join(LocalFS.get_root_path(), folder))
    end)

    :ok = LocalFS.store(folder, "participant=1.json", ~s({"donation":true}))

    {:ok, endpoint} =
      Storage.Public.prepare_endpoint(:builtin, %{key: folder}) |> Mica.Repo.insert()

    %{folder: folder, endpoint: endpoint}
  end

  test "stores donations outside the statically served upload path", %{folder: folder} do
    upload_path = Path.expand(Mica.Env.get(:upload_path))
    file_path = Path.join([LocalFS.get_root_path(), folder, "participant=1.json"])

    assert File.exists?(file_path)
    refute String.starts_with?(Path.expand(file_path), upload_path <> "/")
  end

  test "does not serve donations at /uploads or /feldspar/apps", %{conn: conn, folder: folder} do
    for prefix <- ["/uploads", "/feldspar/apps"] do
      conn = get(conn, "#{prefix}/#{folder}/participant=1.json")
      assert conn.status == 404
      refute conn.resp_body =~ "donation"
    end
  end

  test "lists files relative to the folder with a file source", %{folder: folder} do
    file_path = Path.join([LocalFS.get_root_path(), folder, "participant=1.json"])

    assert [%{path: "participant=1.json", size: 17, source: {:file, ^file_path}}] =
             LocalFS.list_files(folder)
  end

  describe "export" do
    setup :login_as_member

    test "denies a member without access to the endpoint", %{conn: conn, endpoint: endpoint} do
      conn = get(conn, ~p"/storage/endpoint/#{endpoint.id}/export")

      assert conn.status == 403
      refute conn.resp_body =~ "donation"
    end

    test "sends the donations to the endpoint owner", %{conn: conn, endpoint: endpoint} do
      :ok = Mica.Authorization.assign_role(conn.assigns.current_user, endpoint, :owner)

      conn = get(conn, ~p"/storage/endpoint/#{endpoint.id}/export")

      assert conn.status == 200
      {:ok, [{path, content}]} = :zip.unzip(conn.resp_body, [:memory])
      assert to_string(path) =~ ~r|endpoint_#{endpoint.id}/participant=1\.json$|
      assert content == ~s({"donation":true})
    end
  end
end
