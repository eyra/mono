defmodule Systems.Content.PlugTest do
  use ExUnit.Case
  use Plug.Test

  require Systems.Content.Plug
  alias Systems.Content.Plug

  setup do
    conf = Application.get_env(:core, :content, [])

    on_exit(fn ->
      Application.put_env(:core, :content, conf)
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
      |> Keyword.put(:backend, Systems.Content.LocalFS)
      |> Keyword.put(:local_fs_root_path, tmp_dir)

    Application.put_env(
      :core,
      :content,
      conf
    )

    {:ok, tmp_dir: tmp_dir, app_conf: conf}
  end

  test "call with LocalFS backend serves static content", %{tmp_dir: tmp_dir} do
    tmp_dir
    |> Path.join("plug_test.txt")
    |> File.write("hello world!")

    opts = Plug.init(at: "/content")
    conn = Plug.call(conn(:get, "/content/plug_test.txt"), opts)
    assert "hello world!" == conn.resp_body
  end

  test "call with other backends doesn't serve static content", %{app_conf: conf} do
    Application.put_env(
      :core,
      :feldspar,
      Keyword.put(conf, :backend, Systems.Content.FakeBackend)
    )

    opts = Plug.init(at: "/txt")
    conn = Plug.call(conn(:get, "/txt/plug_test.txt"), opts)
    assert nil == conn.resp_body
  end
end
