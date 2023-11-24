defmodule Systems.Feldspar.S3Test do
  use ExUnit.Case, async: true
  import Mox
  alias Systems.Feldspar.S3

  setup :verify_on_exit!

  setup do
    initial_config = Application.get_env(:core, :feldspar)

    Application.put_env(:core, :feldspar,
      backend: Systems.Feldspar.S3,
      bucket: "test-bucket",
      public_url: "http://example.com",
      s3_backend: MockAws
    )

    on_exit(fn ->
      Application.put_env(:core, :feldspar, initial_config)
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

      id = S3.store(Path.join(__DIR__, "hello.zip"))
      assert is_binary(id)
      refute id == ""
    end
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
