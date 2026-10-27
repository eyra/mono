defmodule Systems.Storage.PublicTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  alias Systems.Storage

  @storage_info %{key: :test, backend: Storage.FakeBackend, special: nil}

  describe "store/4" do
    test "refuses an identifier with a line break" do
      meta_data = %{remote_ip: "127.0.0.1", identifier: [[:key, "k\nx"]]}

      assert {:error, :identifier, :invalid, %{}} =
               Storage.Public.store(%Storage.EndpointModel{}, @storage_info, "{}", meta_data)
    end
  end

  describe "deliver_file/3" do
    test "refuses an identifier with a line break" do
      meta_data = %{remote_ip: "127.0.0.1", identifier: [[:key, "k\nx"]]}

      assert {:error, :identifier, :invalid, %{}} =
               Storage.Public.deliver_file(%Storage.EndpointModel{}, "file", meta_data)
    end
  end
end
