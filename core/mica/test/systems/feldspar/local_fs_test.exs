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

      assert {:error, :invalid_zip} = LocalFS.store(zip, "app.zip")
      refute File.exists?(Path.join(LocalFS.get_root_path(), outside))
    end

    @tag :tmp_dir
    test "refuses a zip with an entry that climbs out through a subfolder", %{tmp_dir: tmp_dir} do
      outside = "outside_#{System.unique_integer([:positive])}"
      zip = create_zip(tmp_dir, [{"assets/../../#{outside}/x.json", "x"}])

      assert {:error, :invalid_zip} = LocalFS.store(zip, "app.zip")
      refute File.exists?(Path.join(LocalFS.get_root_path(), outside))
    end

    @tag :tmp_dir
    test "creates no app folder for a refused zip", %{tmp_dir: tmp_dir} do
      name = "refused_#{System.unique_integer([:positive])}"
      zip = create_zip(tmp_dir, [{"../x/x.json", "x"}])

      assert {:error, :invalid_zip} = LocalFS.store(zip, "#{name}.zip")
      assert Path.wildcard(Path.join(LocalFS.get_root_path(), "*_#{name}")) == []
    end

    @tag :tmp_dir
    test "refuses a zip whose local entry name differs from its central directory name",
         %{tmp_dir: tmp_dir} do
      outside = "outside_#{System.unique_integer([:positive])}"
      name = "../#{outside}/x.json"
      zip = create_zip(tmp_dir, [{name, "x"}])

      rename_in_central_directory(
        zip,
        name,
        String.duplicate("a", byte_size(name) - 7) <> "/x.json"
      )

      assert {:error, :invalid_zip} = LocalFS.store(zip, "app.zip")
      refute File.exists?(Path.join(LocalFS.get_root_path(), outside))
    end

    @tag :tmp_dir
    test "refuses a zip whose data doesn't match its checksum and leaves no app folder",
         %{tmp_dir: tmp_dir} do
      name = "broken_#{System.unique_integer([:positive])}"
      zip = create_zip(tmp_dir, [{"index.html", "app"}])
      break_first_checksum(zip)

      assert {:error, :invalid_zip} = LocalFS.store(zip, "#{name}.zip")
      assert Path.wildcard(Path.join(LocalFS.get_root_path(), "*_#{name}")) == []
    end

    @tag :tmp_dir
    test "refuses a file that is not a zip", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, "app.zip")
      File.write!(file, "not a zip")

      assert {:error, :invalid_zip} = LocalFS.store(file, "app.zip")
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

  # Bytes 14-17 of a local file header hold the entry's CRC-32.
  defp break_first_checksum(path) do
    <<header::binary-size(14), crc::little-32, rest::binary>> = File.read!(path)
    File.write!(path, <<header::binary, Bitwise.bxor(crc, 1)::little-32, rest::binary>>)
  end

  # The central directory comes last, so its copy of the name is the last match.
  defp rename_in_central_directory(path, name, new_name)
       when byte_size(name) == byte_size(new_name) do
    zip = File.read!(path)
    {offset, length} = zip |> :binary.matches(name) |> List.last()

    File.write!(
      path,
      binary_part(zip, 0, offset) <>
        new_name <> binary_part(zip, offset + length, byte_size(zip) - offset - length)
    )
  end
end
