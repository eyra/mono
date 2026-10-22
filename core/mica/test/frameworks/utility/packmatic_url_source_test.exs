defmodule Frameworks.Utility.PackmaticURLSourceTest do
  use ExUnit.Case, async: true

  alias Frameworks.Utility.PackmaticURLSource

  setup do
    bypass = Bypass.open()

    Bypass.stub(bypass, "GET", "/chunks", fn conn ->
      conn = Plug.Conn.send_chunked(conn, 200)

      Enum.reduce(["aaaa", "bbbb", "cccc"], conn, fn chunk, conn ->
        {:ok, conn} = Plug.Conn.chunk(conn, chunk)
        conn
      end)
    end)

    %{url: "http://localhost:#{bypass.port}/chunks"}
  end

  test "reads a body sent in several chunks", %{url: url} do
    {:ok, source} = PackmaticURLSource.init(url)

    assert read_all(source) == {:ok, "aaaabbbbcccc"}
  end

  test "counts the limit across chunks", %{url: url} do
    {:ok, source} = PackmaticURLSource.init({url, max_bytes: 10})

    assert read_all(source) == {:error, {:too_large, 10}}
  end

  defp read_all(source, acc \\ []) do
    case PackmaticURLSource.read(source) do
      :eof -> {:ok, IO.iodata_to_binary(acc)}
      {:error, reason} -> {:error, reason}
      data -> read_all(source, [acc, data])
    end
  end
end
