defmodule Systems.Storage.BuiltIn.UploadPathCheckTest do
  use ExUnit.Case, async: false

  alias Systems.Storage.BuiltIn.Backend
  alias Systems.Storage.BuiltIn.LocalFS
  alias Systems.Storage.BuiltIn.S3

  @moduletag :tmp_dir

  setup %{tmp_dir: tmp_dir} do
    initial_upload_path = Application.get_env(:mica, :upload_path)
    initial_builtin = Application.get_env(:mica, Systems.Storage.BuiltIn)
    initial_local_fs = Application.get_env(:mica, LocalFS)

    upload_path = Path.join(tmp_dir, "uploads")
    storage_path = Path.join(tmp_dir, "storage")
    File.mkdir_p!(upload_path)

    Application.put_env(:mica, :upload_path, upload_path)
    Application.put_env(:mica, LocalFS, root_path: storage_path)

    on_exit(fn ->
      Application.put_env(:mica, :upload_path, initial_upload_path)
      Application.put_env(:mica, Systems.Storage.BuiltIn, initial_builtin)
      Application.put_env(:mica, LocalFS, initial_local_fs)
    end)

    %{upload_path: upload_path, storage_path: storage_path}
  end

  describe "with LocalFS storage" do
    setup do
      Application.put_env(:mica, Systems.Storage.BuiltIn, special: LocalFS)
      :ok
    end

    test "starts when the upload folder holds no donation folders", %{upload_path: upload_path} do
      File.write!(Path.join(upload_path, "logo.png"), "png")
      File.mkdir_p!(Path.join(upload_path, "feldspar_app"))
      File.write!(Path.join(upload_path, "project_node=3.txt"), "not a folder")

      assert :ok = Backend.check_upload_path!()
    end

    test "starts when the upload folder does not exist", %{upload_path: upload_path} do
      File.rm_rf!(upload_path)

      assert :ok = Backend.check_upload_path!()
    end

    test "refuses to start while donation folders are in the upload folder", %{
      upload_path: upload_path,
      storage_path: storage_path
    } do
      File.mkdir_p!(Path.join(upload_path, "project_node=1"))
      File.mkdir_p!(Path.join(upload_path, "project_node=2"))

      error = assert_raise RuntimeError, fn -> Backend.check_upload_path!() end

      folder_1 = Path.join(upload_path, "project_node=1")
      folder_2 = Path.join(upload_path, "project_node=2")

      assert error.message =~ "    #{folder_1}\n"
      assert error.message =~ "    #{folder_2}\n"
      assert error.message =~ "STORAGE_PATH (#{storage_path})"
      assert error.message =~ "mkdir -p #{storage_path}\n"
      assert error.message =~ "mv #{upload_path}/project_node=*/ #{storage_path}/\n"
      refute error.message =~ "assignment="
    end

    test "refuses to start while assignment donation folders are in the upload folder", %{
      upload_path: upload_path,
      storage_path: storage_path
    } do
      File.mkdir_p!(Path.join(upload_path, "assignment=1"))

      error = assert_raise RuntimeError, fn -> Backend.check_upload_path!() end

      folder = Path.join(upload_path, "assignment=1")

      assert error.message =~ "    #{folder}\n"
      assert error.message =~ "mv #{upload_path}/assignment=*/ #{storage_path}/\n"
      refute error.message =~ "project_node="
    end

    test "quotes paths in the move command when the shell needs it", %{tmp_dir: tmp_dir} do
      upload_path = Path.join(tmp_dir, "my uploads")
      storage_path = Path.join(tmp_dir, "it's storage")
      File.mkdir_p!(Path.join(upload_path, "project_node=1"))

      error =
        assert_raise RuntimeError, fn -> LocalFS.check_upload_path!(upload_path, storage_path) end

      assert error.message =~
               "mv '#{upload_path}'/project_node=*/ '#{String.replace(storage_path, "'", "'\\''")}'/"
    end

    test "the printed commands work when paths need quoting", %{tmp_dir: tmp_dir} do
      upload_path = Path.join(tmp_dir, "my uploads")
      storage_path = Path.join(tmp_dir, "it's storage")
      File.mkdir_p!(Path.join(upload_path, "project_node=1"))

      error =
        assert_raise RuntimeError, fn -> LocalFS.check_upload_path!(upload_path, storage_path) end

      run_printed_commands(error.message)

      assert File.ls!(storage_path) == ["project_node=1"]
    end

    test "the error is not cut off by the logger with many folders", %{upload_path: upload_path} do
      create_donation_folders(upload_path, 100)

      error = assert_raise RuntimeError, fn -> Backend.check_upload_path!() end

      logged = format_log(error.message)

      refute logged =~ "(truncated)"
      assert logged =~ "Then start the app again."
    end

    test "the printed commands move every folder with many folders", %{
      upload_path: upload_path,
      storage_path: storage_path
    } do
      folders = create_donation_folders(upload_path, 100)
      File.write!(Path.join(upload_path, "project_node=3.txt"), "not a folder")
      File.mkdir_p!(Path.join(upload_path, "feldspar_app"))

      error = assert_raise RuntimeError, fn -> Backend.check_upload_path!() end

      run_printed_commands(error.message)

      assert Enum.sort(File.ls!(storage_path)) == Enum.sort(folders)
      assert Enum.sort(File.ls!(upload_path)) == ["feldspar_app", "project_node=3.txt"]
    end

    test "moves a symlinked folder without a trailing slash", %{
      tmp_dir: tmp_dir,
      upload_path: upload_path,
      storage_path: storage_path
    } do
      File.mkdir_p!(Path.join(upload_path, "project_node=1"))
      [link] = create_linked_folders(tmp_dir, upload_path, ["project_node=2"])

      error = assert_raise RuntimeError, fn -> Backend.check_upload_path!() end

      assert error.message =~ "    mv #{upload_path}/project_node=2 #{storage_path}/\n"
      assert error.message =~ "mv #{upload_path}/project_node=*/ #{storage_path}/\n"

      run_printed_commands(error.message)

      assert File.ls!(upload_path) == []
      assert_moved_links(storage_path, [link])
      assert File.ls!(storage_path) |> Enum.sort() == ["project_node=1", "project_node=2"]
    end

    test "leaves out the glob of a prefix that only has symlinked folders", %{
      tmp_dir: tmp_dir,
      upload_path: upload_path,
      storage_path: storage_path
    } do
      File.mkdir_p!(Path.join(upload_path, "project_node=1"))
      links = create_linked_folders(tmp_dir, upload_path, ["assignment=2"])

      error = assert_raise RuntimeError, fn -> Backend.check_upload_path!() end

      refute error.message =~ "assignment=*"

      run_printed_commands(error.message)

      assert File.ls!(upload_path) == []
      assert_moved_links(storage_path, links)
    end

    test "the printed commands move every folder with many folders and symlinks", %{
      tmp_dir: tmp_dir,
      upload_path: upload_path,
      storage_path: storage_path
    } do
      folders = create_donation_folders(upload_path, 100)
      links = create_linked_folders(tmp_dir, upload_path, ["project_node=101"])
      File.mkdir_p!(Path.join(upload_path, "feldspar_app"))

      error = assert_raise RuntimeError, fn -> Backend.check_upload_path!() end

      run_printed_commands(error.message)

      assert Enum.sort(File.ls!(storage_path)) == Enum.sort(folders ++ links)
      assert File.ls!(upload_path) == ["feldspar_app"]
      assert_moved_links(storage_path, links)
    end

    test "the printed commands move every symlink with many symlinks", %{
      tmp_dir: tmp_dir,
      upload_path: upload_path,
      storage_path: storage_path
    } do
      folders = create_donation_folders(upload_path, 100)
      links = create_linked_folders(tmp_dir, upload_path, Enum.map(101..200, &"assignment=#{&1}"))
      File.write!(Path.join(tmp_dir, "file"), "not a folder")
      File.ln_s!(Path.join(tmp_dir, "file"), Path.join(upload_path, "assignment=0"))

      error = assert_raise RuntimeError, fn -> Backend.check_upload_path!() end

      refute format_log(error.message) =~ "(truncated)"

      run_printed_commands(error.message)

      assert Enum.sort(File.ls!(storage_path)) == Enum.sort(folders ++ links)
      assert File.ls!(upload_path) == ["assignment=0"]
      assert_moved_links(storage_path, links)
    end

    test "writes the error to stderr as plain text when the log is not plain text", %{
      upload_path: upload_path
    } do
      File.mkdir_p!(Path.join(upload_path, "project_node=1"))
      use_log_formatter(LoggerJSON.Formatters.Basic.new())

      {error, stderr} =
        ExUnit.CaptureIO.with_io(:stderr, fn ->
          assert_raise RuntimeError, fn -> Backend.check_upload_path!() end
        end)

      assert stderr == error.message <> "\n"
    end

    test "does not write the error to stderr when the log is plain text", %{
      upload_path: upload_path
    } do
      File.mkdir_p!(Path.join(upload_path, "project_node=1"))
      use_log_formatter(Logger.Formatter.new())

      stderr =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert_raise RuntimeError, fn -> Backend.check_upload_path!() end
        end)

      assert stderr == ""
    end
  end

  test "starts on S3 storage even with donation folders in the upload folder", %{
    upload_path: upload_path
  } do
    Application.put_env(:mica, Systems.Storage.BuiltIn, special: S3)
    File.mkdir_p!(Path.join(upload_path, "project_node=1"))

    assert :ok = Backend.check_upload_path!()
  end

  defp create_donation_folders(upload_path, count) do
    folders =
      Enum.map(1..count, fn
        id when rem(id, 3) == 0 -> "assignment=#{id}"
        id -> "project_node=#{id}"
      end)

    Enum.each(folders, &File.mkdir_p!(Path.join([upload_path, &1, "files"])))
    folders
  end

  # Links each folder name in the upload folder to a folder of that name elsewhere.
  defp create_linked_folders(tmp_dir, upload_path, names) do
    Enum.each(names, fn name ->
      target = Path.join([tmp_dir, "elsewhere", name])
      File.mkdir_p!(Path.join(target, "files"))
      File.ln_s!(target, Path.join(upload_path, name))
    end)

    names
  end

  # The links themselves are moved, and still point at their untouched folders.
  defp assert_moved_links(storage_path, links) do
    Enum.each(links, fn name ->
      path = Path.join(storage_path, name)
      assert {:ok, %File.Stat{type: :symlink}} = File.lstat(path)
      assert File.ls!(path) == ["files"]
    end)
  end

  defp use_log_formatter(formatter) do
    initial = Application.get_env(:logger, :default_handler)
    Application.put_env(:logger, :default_handler, formatter: formatter)
    on_exit(fn -> Application.put_env(:logger, :default_handler, initial) end)
  end

  # Formats the message the way Logger prints it at boot, with its default `truncate`.
  defp format_log(message) do
    {_, config} = Logger.Formatter.new()
    event = %{level: :error, msg: {:string, message}, meta: %{}}

    event |> Logger.Formatter.format(config) |> IO.chardata_to_string()
  end

  defp run_printed_commands(message) do
    commands =
      message
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, ["    mkdir ", "    mv ", "    for "]))
      |> Enum.join("\n")

    assert {_, 0} = System.cmd("sh", ["-ec", commands], stderr_to_stdout: true)
  end
end
