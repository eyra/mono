defmodule Systems.Content.LocalFSTest do
  use ExUnit.Case, async: true

  alias Systems.Content.LocalFS

  describe "store/1" do
    test "extracts stores file on disk" do
      id = LocalFS.store(Path.join(__DIR__, "hello.svg"))
      path = LocalFS.storage_path(id)
      assert File.exists?(path)
    end
  end

  describe "get_public_url/1" do
    test "returns URL" do
      id = Ecto.UUID.generate()
      url = LocalFS.get_public_url(id)
      uri = URI.parse(url)
      assert String.contains?(uri.path, id)
    end
  end

  describe "remove/1" do
    test "removes folder" do
      id = LocalFS.store(Path.join(__DIR__, "hello.svg"))
      path = LocalFS.storage_path(id)
      assert :ok == LocalFS.remove(id)
      refute File.exists?(path)
    end
  end
end
