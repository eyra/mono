defmodule Systems.Content.S3Test do
  use ExUnit.Case, async: true
  import Mox
  alias Systems.Content.S3

  setup :verify_on_exit!

  setup do
    initial_config = Application.get_env(:core, :content)

    Application.put_env(:core, :content,
      backend: Systems.Content.S3,
      bucket: "test-bucket",
      public_url: "http://example.com",
      s3_backend: MockAws
    )

    on_exit(fn ->
      Application.put_env(:core, :content, initial_config)
    end)

    :ok
  end

  describe "store/1" do
    test "stores file on disk" do
      expect(MockAws, :request!, fn args ->
        assert %ExAws.Operation.S3{
                 bucket: "test-bucket",
                 http_method: :put,
                 resource: "",
                 params: %{},
                 headers: %{"content-type" => "image/svg+xml"},
                 service: :s3
               } = args
      end)

      id = S3.store(Path.join(__DIR__, "hello.svg"), "original_file.svg")
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
    test "removes file" do
      id = Ecto.UUID.generate()

      expect(MockAws, :request!, 1, fn args ->
        args
      end)

      assert %ExAws.Operation.S3{
               bucket: "test-bucket",
               http_method: :delete,
               body: "",
               resource: "",
               params: %{},
               headers: %{},
               service: :s3
             } = S3.remove(id)
    end
  end
end
