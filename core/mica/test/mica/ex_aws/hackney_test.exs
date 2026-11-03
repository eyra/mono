defmodule Mica.ExAws.HackneyTest do
  use ExUnit.Case, async: true

  alias Mica.ExAws.Hackney

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, url: "http://localhost:#{bypass.port}"}
  end

  test "is the configured ExAws client" do
    assert ExAws.Config.new(:s3).http_client == Hackney
  end

  test "HEAD returns status and headers", %{bypass: bypass, url: url} do
    Bypass.expect_once(bypass, "HEAD", "/bucket/key", fn conn ->
      Plug.Conn.resp(conn, 200, "12345")
    end)

    assert {:ok, %{status_code: 200, headers: headers} = response} =
             Hackney.request(:head, url <> "/bucket/key")

    assert {"content-length", "5"} in headers
    refute Map.has_key?(response, :body)
  end

  test "GET returns the body", %{bypass: bypass, url: url} do
    Bypass.expect_once(bypass, "GET", "/bucket/key", fn conn ->
      Plug.Conn.resp(conn, 200, "content")
    end)

    assert {:ok, %{status_code: 200, body: "content"}} =
             Hackney.request(:get, url <> "/bucket/key")
  end

  test "POST sends the body", %{bypass: bypass, url: url} do
    Bypass.expect_once(bypass, "POST", "/bucket/key", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      Plug.Conn.resp(conn, 200, "got " <> body)
    end)

    assert {:ok, %{status_code: 200, body: "got <xml/>"}} =
             Hackney.request(:post, url <> "/bucket/key", "<xml/>")
  end

  test "an S3 put_object goes through", %{bypass: bypass} do
    Bypass.expect_once(bypass, "PUT", "/bucket/folder/file.txt", fn conn ->
      {:ok, "data", conn} = Plug.Conn.read_body(conn)
      Plug.Conn.resp(conn, 200, "")
    end)

    assert {:ok, %{status_code: 200}} =
             "bucket"
             |> ExAws.S3.put_object("folder/file.txt", "data")
             |> ExAws.request(scheme: "http://", host: "localhost", port: bypass.port)
  end

  test "a connection error returns the reason", %{bypass: bypass, url: url} do
    Bypass.down(bypass)

    assert {:error, %{reason: :econnrefused}} = Hackney.request(:get, url <> "/bucket/key")
  end
end
