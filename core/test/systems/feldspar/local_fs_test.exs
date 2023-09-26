defmodule Systems.Feldspar.LocalFSTest do
  use ExUnit.Case, async: true

  alias Systems.Feldspar.LocalFS

  describe "store/1" do
    test "extracts zip and stores files on disk" do
      id = LocalFS.store(Path.join(__DIR__, "hello.zip"))
      path = LocalFS.storage_path(id)
      assert ["index.html"] == File.ls!(path)
    end

    # TODO:
    # filters files? .exe etc.?
    # runs virus scanner? clamav
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
      id = LocalFS.store(Path.join(__DIR__, "hello.zip"))
      path = LocalFS.storage_path(id)
      assert :ok == LocalFS.remove(id)
      refute File.exists?(path)
    end
  end
end
