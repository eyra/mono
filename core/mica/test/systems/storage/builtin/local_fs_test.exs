defmodule Systems.Storage.BuiltIn.LocalFSTest do
  use CoreWeb.ConnCase, async: false

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

    :ok = LocalFS.store(folder, "participant=1.json", ~s({"donation":true}))

    {:ok, endpoint} =
      Storage.Public.prepare_endpoint(:builtin, %{key: folder}) |> Core.Repo.insert()

    %{folder: folder, endpoint: endpoint}
  end

  test "stores donations outside the statically served upload path", %{folder: folder} do
    upload_path = Path.expand(Core.Env.get(:upload_path))
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

  test "stores and lists a donation whose key contains slashes", %{folder: folder} do
    filename = "participant=2_key=run1/cogflex/practice2/0.json"

    assert :ok = LocalFS.store(folder, filename, "{}")

    file_path = Path.join([LocalFS.get_root_path(), folder, filename])

    assert %{path: ^filename, size: 2, source: {:file, ^file_path}} =
             Enum.find(LocalFS.list_files(folder), &(&1.path == filename))
  end

  test "refuses a key that climbs out of the endpoint folder", %{folder: folder} do
    filename = "participant=2_key=run1/../../../escaped.json"

    assert {:error, :unsafe_filename} = LocalFS.store(folder, filename, "{}")
    refute File.exists?(Path.join(Path.dirname(LocalFS.get_root_path()), "escaped.json"))
  end

  describe "export" do
    setup :login_as_member

    test "denies a member without access to the endpoint", %{conn: conn, endpoint: endpoint} do
      conn = get(conn, ~p"/storage/endpoint/#{endpoint.id}/export")

      assert conn.status == 403
      refute conn.resp_body =~ "donation"
    end

    test "sends the donations to the endpoint owner", %{conn: conn, endpoint: endpoint} do
      :ok = Core.Authorization.assign_role(conn.assigns.current_user, endpoint, :owner)

      conn = get(conn, ~p"/storage/endpoint/#{endpoint.id}/export")

      assert conn.status == 200
      {:ok, [{path, content}]} = :zip.unzip(conn.resp_body, [:memory])
      assert to_string(path) =~ ~r|endpoint_#{endpoint.id}/1/participant=1\.json$|
      assert content == ~s({"donation":true})
    end

    test "puts the donations of three participants in three folders", %{
      conn: conn,
      endpoint: endpoint,
      folder: folder
    } do
      :ok = Core.Authorization.assign_role(conn.assigns.current_user, endpoint, :owner)
      :ok = LocalFS.store(folder, "participant=2_key=run1/summary.json", "{}")
      :ok = LocalFS.store(folder, "participant=3_key=run1/summary.json", "{}")

      conn = get(conn, ~p"/storage/endpoint/#{endpoint.id}/export")

      {:ok, files} = :zip.unzip(conn.resp_body, [:memory])

      folders =
        files
        |> Enum.map(fn {path, _} -> path |> to_string() |> Path.split() |> Enum.at(1) end)
        |> Enum.uniq()
        |> Enum.sort()

      assert folders == ["1", "2", "3"]
    end

    test "puts a donation without a participant in its own folder", %{
      conn: conn,
      endpoint: endpoint,
      folder: folder
    } do
      :ok = Core.Authorization.assign_role(conn.assigns.current_user, endpoint, :owner)
      :ok = LocalFS.store(folder, "assignment=5_key=run1/summary.json", "{}")

      conn = get(conn, ~p"/storage/endpoint/#{endpoint.id}/export")

      {:ok, files} = :zip.unzip(conn.resp_body, [:memory])
      paths = Enum.map(files, fn {path, _} -> to_string(path) end)

      assert Enum.any?(
               paths,
               &(&1 =~ ~r|/\(no participant\)/assignment=5_key=run1/summary\.json$|)
             )
    end
  end
end
