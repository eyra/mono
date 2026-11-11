defmodule Systems.Feldspar.S3Test do
  use ExUnit.Case, async: true
  import Mox
  alias Systems.Feldspar.S3

  setup :verify_on_exit!

  setup do
    initial_config = Application.get_env(:mica, :feldspar)

    Application.put_env(:mica, :feldspar,
      backend: Systems.Feldspar.S3,
      bucket: "test-bucket",
      public_url: "http://example.com",
      s3_backend: MockAws
    )

    on_exit(fn ->
      Application.put_env(:mica, :feldspar, initial_config)
    end)

    :ok
  end

  describe "store/1" do
    test "extracts zip and stores files on disk" do
      expect(MockAws, :request!, fn args ->
        assert %ExAws.Operation.S3{
                 bucket: "test-bucket",
                 http_method: :put,
                 body: "Hello World!"
               } = args
      end)

      id = S3.store(Path.join(__DIR__, "hello.zip"), "original_file.zip")
      assert is_binary(id)
      refute id == ""
    end

    # Mox fails the test on any unexpected S3 request, so nothing is uploaded.
    @tag :tmp_dir
    test "refuses a zip without index.html and uploads nothing", %{tmp_dir: tmp_dir} do
      zip = create_zip(tmp_dir, ["export/a.json", "export/b.json"])

      assert {:error, :no_index_html} = S3.store(zip, "app.zip")
    end

    @tag :tmp_dir
    test "refuses a zip with index.html only in a subfolder and uploads nothing",
         %{tmp_dir: tmp_dir} do
      zip = create_zip(tmp_dir, ["app/index.html"])

      assert {:error, :no_index_html} = S3.store(zip, "app.zip")
    end
  end

  defp create_zip(dir, names) do
    path = Path.join(dir, "app.zip")
    {:ok, _} = :zip.create(to_charlist(path), Enum.map(names, &{to_charlist(&1), "x"}))
    path
  end

  describe "get_public_url/1 (without prefix)" do
    test "returns URL" do
      id = Ecto.UUID.generate()
      url = S3.get_public_url(id)
      assert "http://example.com/#{id}" == url
    end
  end

  describe "remove/1" do
    test "removes folder" do
      id = Ecto.UUID.generate()

      expect(MockAws, :request!, 2, fn args ->
        case args do
          %{params: %{"list-type" => 2, "prefix" => ^id}} ->
            %{
              body: %{
                contents: [
                  %{key: "some-thing.html"}
                ]
              }
            }

          %ExAws.Operation.S3DeleteAllObjects{
            bucket: "test-bucket",
            objects: objects,
            opts: [],
            service: :s3
          } ->
            assert objects == ["some-thing.html"]
        end
      end)

      assert :ok == S3.remove(id)
    end
  end
end
