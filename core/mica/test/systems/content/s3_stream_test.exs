defmodule Systems.Content.S3StreamTest do
  # Points the global :ex_aws S3 config at Bypass.
  use ExUnit.Case, async: false

  alias Systems.Content.S3

  @bucket "test-bucket"

  setup do
    bypass = Bypass.open()
    initial_content = Application.get_env(:mica, :content)
    initial_s3 = Application.get_env(:ex_aws, :s3)

    Application.put_env(:mica, :content, backend: S3, bucket: @bucket)

    Application.put_env(:ex_aws, :s3,
      scheme: "http://",
      host: "localhost",
      port: bypass.port
    )

    on_exit(fn ->
      Application.put_env(:mica, :content, initial_content)
      Application.put_env(:ex_aws, :s3, initial_s3)
    end)

    {:ok, bypass: bypass}
  end

  describe "stream/1" do
    test "streams an object in chunks", %{bypass: bypass} do
      content = :binary.copy("TY  - JOUR\n", 250)
      serve_object(bypass, "/#{@bucket}/papers.ris", content)

      assert {:ok, stream} = S3.stream("papers.ris")
      assert stream |> Enum.to_list() |> IO.iodata_to_binary() == content
    end
  end

  defp serve_object(bypass, path, content) do
    Bypass.expect(bypass, "HEAD", path, fn conn ->
      Plug.Conn.resp(conn, 200, content)
    end)

    Bypass.expect(bypass, "GET", path, fn conn ->
      [range] = Plug.Conn.get_req_header(conn, "range")
      ["bytes=" <> from, to] = String.split(range, "-")
      from = String.to_integer(from)
      to = min(String.to_integer(to), byte_size(content) - 1)

      Plug.Conn.resp(conn, 206, binary_part(content, from, to - from + 1))
    end)
  end
end
