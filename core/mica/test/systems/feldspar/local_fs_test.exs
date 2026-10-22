defmodule Systems.Feldspar.LocalFSTest do
  use ExUnit.Case, async: true

  alias Systems.Feldspar.LocalFS

  describe "store/1" do
    test "extracts zip and stores files on disk" do
      id = LocalFS.store(Path.join(__DIR__, "hello.zip"), "original_file.zip")
      path = LocalFS.storage_path(id)
      assert ["index.html"] == File.ls!(path)
    end

    @tag :tmp_dir
    test "extracts entries in subfolders", %{tmp_dir: tmp_dir} do
      zip = create_zip(tmp_dir, [{"assets/app.js", "app"}])

      id = LocalFS.store(zip, "app.zip")

      assert File.read!(Path.join(LocalFS.storage_path(id), "assets/app.js")) == "app"
    end

    @tag :tmp_dir
    test "refuses a zip with an entry outside the app folder", %{tmp_dir: tmp_dir} do
      outside = "outside_#{System.unique_integer([:positive])}"
      zip = create_zip(tmp_dir, [{"index.html", "app"}, {"../#{outside}/x.json", "x"}])

      assert_raise ArgumentError, fn -> LocalFS.store(zip, "app.zip") end
      refute File.exists?(Path.join(LocalFS.get_root_path(), outside))
    end

    @tag :tmp_dir
    test "refuses a zip with an entry that climbs out through a subfolder", %{tmp_dir: tmp_dir} do
      outside = "outside_#{System.unique_integer([:positive])}"
      zip = create_zip(tmp_dir, [{"assets/../../#{outside}/x.json", "x"}])

      assert_raise ArgumentError, fn -> LocalFS.store(zip, "app.zip") end
      refute File.exists?(Path.join(LocalFS.get_root_path(), outside))
    end

    @tag :tmp_dir
    test "creates no app folder for a refused zip", %{tmp_dir: tmp_dir} do
      name = "refused_#{System.unique_integer([:positive])}"
      zip = create_zip(tmp_dir, [{"../x/x.json", "x"}])

      assert_raise ArgumentError, fn -> LocalFS.store(zip, "#{name}.zip") end
      assert Path.wildcard(Path.join(LocalFS.get_root_path(), "*_#{name}")) == []
    end

    # TODO
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
      id = LocalFS.store(Path.join(__DIR__, "hello.zip"), "original_file.zip")
      path = LocalFS.storage_path(id)
      assert :ok == LocalFS.remove(id)
      refute File.exists?(path)
    end
  end

  defp create_zip(dir, entries) do
    files = Enum.map(entries, fn {name, data} -> {to_charlist(name), data} end)
    {:ok, {_, zip}} = :zip.create(~c"app.zip", files, [:memory])
    path = Path.join(dir, "app.zip")
    File.write!(path, zip)
    path
  end
end
