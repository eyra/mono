defmodule Systems.Storage.Yoda.BackendTest do
  use ExUnit.Case, async: true

  alias Systems.Storage.Yoda.Backend

  describe "filename/1" do
    test "empty identifier" do
      assert ".json" = Backend.filename([])
    end

    test "single identifier" do
      assert "participant=1.json" = Backend.filename([[:participant, 1]])
    end

    test "multiple identifiers" do
      identifier = [[:assignment, 1], [:participant, "abc"], [:source, "test"]]
      assert "assignment=1_participant=abc_source=test.json" = Backend.filename(identifier)
    end
  end

  describe "file_url/2" do
    test "puts the file directly in the endpoint folder" do
      identifier = [[:assignment, 1], [:task, "9"], [:key, "1761568123456-whatsapp group chat"]]

      assert "https://yoda.example/folder/assignment=1_task=9_key=1761568123456-whatsapp%20group%20chat.json" =
               Backend.file_url("https://yoda.example/folder", identifier)
    end

    test "names the file as before for the characters real donation keys contain" do
      identifier = [[:assignment, 1], [:key, "1761568123456-it's (a), c: {d} é"]]

      %URI{path: path} = URI.parse(Backend.file_url("https://yoda.example/folder", identifier))

      assert URI.decode(path) == "/folder/" <> Backend.filename(identifier)
    end

    test "keeps a slash in a value inside the endpoint folder" do
      url = Backend.file_url("https://yoda.example/folder", [[:task, "../t"]])

      assert %URI{path: "/folder/task=.._t.json"} = URI.parse(url)
    end

    test "keeps a question mark in a value out of the query" do
      url = Backend.file_url("https://yoda.example/folder", [[:key, "k?x=1"]])

      assert %URI{path: "/folder/key=k%3Fx=1.json", query: nil} = URI.parse(url)
    end
  end

  describe "store/3" do
    setup do
      {:ok, listen} = :gen_tcp.listen(0, [:binary, active: false, reuseaddr: true])
      {:ok, port} = :inet.port(listen)
      test_pid = self()

      spawn_link(fn ->
        {:ok, socket} = :gen_tcp.accept(listen)
        send(test_pid, {:request_head, read_head(socket, "")})
        :gen_tcp.send(socket, "HTTP/1.1 201 Created\r\ncontent-length: 0\r\n\r\n")
        :gen_tcp.close(socket)
      end)

      on_exit(fn -> :gen_tcp.close(listen) end)

      %{
        endpoint: %{
          "user" => "researcher",
          "password" => "secret",
          "url" => "http://127.0.0.1:#{port}/folder"
        }
      }
    end

    test "keeps the whole file name in the request line", %{endpoint: endpoint} do
      identifier = [[:assignment, 1], [:key, "k?y=1 HTTP/1.1\r\nX-Extra: yes\r\nX:"]]

      assert :ok = Backend.store(endpoint, "{}", %{"identifier" => identifier})
      assert_receive {:request_head, head}, 5_000

      [request_line | header_lines] = String.split(head, "\r\n")

      assert request_line ==
               "PUT /folder/assignment=1_key=k%3Fy=1%20HTTP_1.1%0D%0AX-Extra:%20yes%0D%0AX:.json HTTP/1.1"

      refute Enum.any?(header_lines, &String.starts_with?(&1, "X-Extra"))
    end
  end

  defp read_head(socket, acc) do
    if String.contains?(acc, "\r\n\r\n") do
      acc |> String.split("\r\n\r\n") |> hd()
    else
      {:ok, data} = :gen_tcp.recv(socket, 0, 5_000)
      read_head(socket, acc <> data)
    end
  end
end
