defmodule Systems.Feldspar.PlugTest do
  use ExUnit.Case
  import Plug.Test

  require Systems.Feldspar.Plug
  alias Systems.Feldspar.Plug

  setup do
    upload_path = Application.get_env(:core, :upload_path)
    backend = Application.fetch_env!(:core, :feldspar) |> Access.fetch!(:backend)

    on_exit(fn ->
      Application.put_env(:core, :upload_path, upload_path)
      Application.put_env(:core, :feldspar, backend: backend)
    end)

    folder_name = "temp_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"

    tmp_dir =
      System.tmp_dir()
      |> Path.join(folder_name)

    File.mkdir!(tmp_dir)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    Application.put_env(:core, :upload_path, tmp_dir)
    Application.put_env(:core, :feldspar, backend: Systems.Feldspar.LocalFS)

    {:ok, tmp_dir: tmp_dir}
  end

  test "call with LocalFS backend serves static content", %{tmp_dir: tmp_dir} do
    tmp_dir
    |> Path.join("plug_test.txt")
    |> File.write("hello world!")

    opts = Plug.init(at: "/web_apps")
    conn = Plug.call(conn(:get, "/web_apps/plug_test.txt"), opts)
    assert "hello world!" == conn.resp_body
  end

  test "call with other backends doesn't serve static content" do
    Application.put_env(:core, :feldspar, backend: Systems.Feldspar.FakeBackend)

    opts = Plug.init(at: "/web_apps")
    conn = Plug.call(conn(:get, "/web_apps/plug_test.txt"), opts)
    assert nil == conn.resp_body
  end
end
