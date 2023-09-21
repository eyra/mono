defmodule Systems.Feldspar.PlugTest do
  use ExUnit.Case
  use Plug.Test

  require Systems.Feldspar.Plug
  alias Systems.Feldspar.Plug

  setup do
    conf = Application.get_env(:core, :feldspar, [])

    on_exit(fn ->
      Application.put_env(:core, :feldspar, conf)
    end)

    folder_name = "temp_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"

    tmp_dir =
      System.tmp_dir()
      |> Path.join(folder_name)

    File.mkdir!(tmp_dir)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    conf =
      conf
      |> Keyword.put(:backend, Systems.Feldspar.LocalFS)
      |> Keyword.put(:local_fs_root_path, tmp_dir)

    Application.put_env(
      :core,
      :feldspar,
      conf
    )

    {:ok, tmp_dir: tmp_dir, app_conf: conf}
  end

  test "call with LocalFS backend serves static content", %{tmp_dir: tmp_dir} do
    tmp_dir
    |> Path.join("plug_test.txt")
    |> File.write("hello world!")

    opts = Plug.init(at: "/web_apps")
    conn = Plug.call(conn(:get, "/web_apps/plug_test.txt"), opts)
    assert "hello world!" == conn.resp_body
  end

  test "call with other backends doesn't serve static content", %{app_conf: conf} do
    Application.put_env(
      :core,
      :feldspar,
      Keyword.put(conf, :backend, Systems.Feldspar.FakeBackend)
    )

    opts = Plug.init(at: "/web_apps")
    conn = Plug.call(conn(:get, "/web_apps/plug_test.txt"), opts)
    assert nil == conn.resp_body
  end
end
