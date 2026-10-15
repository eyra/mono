defmodule Systems.Content.LocalFSTest do
  use ExUnit.Case, async: true

  alias Systems.Content.LocalFS

  describe "store/1" do
    test "extracts stores file on disk" do
      path = LocalFS.store(Path.join(__DIR__, "hello.svg"), "original_file.svg")
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
      path = LocalFS.store(Path.join(__DIR__, "hello.svg"), "original_file.svg")
      assert :ok == LocalFS.remove(path)
      refute File.exists?(path)
    end
  end
end
