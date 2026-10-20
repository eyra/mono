defmodule Systems.Storage.BuiltIn.UploadPathCheckTest do
  use ExUnit.Case, async: false

  alias Systems.Storage.BuiltIn.Backend
  alias Systems.Storage.BuiltIn.LocalFS
  alias Systems.Storage.BuiltIn.S3

  @moduletag :tmp_dir

  setup %{tmp_dir: tmp_dir} do
    initial_upload_path = Application.get_env(:core, :upload_path)
    initial_builtin = Application.get_env(:core, Systems.Storage.BuiltIn)
    initial_local_fs = Application.get_env(:core, LocalFS)

    upload_path = Path.join(tmp_dir, "uploads")
    storage_path = Path.join(tmp_dir, "storage")
    File.mkdir_p!(upload_path)

    Application.put_env(:core, :upload_path, upload_path)
    Application.put_env(:core, LocalFS, root_path: storage_path)

    on_exit(fn ->
      Application.put_env(:core, :upload_path, initial_upload_path)
      Application.put_env(:core, Systems.Storage.BuiltIn, initial_builtin)
      Application.put_env(:core, LocalFS, initial_local_fs)
    end)

    %{upload_path: upload_path, storage_path: storage_path}
  end

  describe "with LocalFS storage" do
    setup do
      Application.put_env(:core, Systems.Storage.BuiltIn, special: LocalFS)
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
      assert error.message =~ "mv #{folder_1} #{folder_2} #{storage_path}/\n"
    end

    test "refuses to start while assignment donation folders are in the upload folder", %{
      upload_path: upload_path,
      storage_path: storage_path
    } do
      File.mkdir_p!(Path.join(upload_path, "assignment=1"))

      error = assert_raise RuntimeError, fn -> Backend.check_upload_path!() end

      folder = Path.join(upload_path, "assignment=1")

      assert error.message =~ "    #{folder}\n"
      assert error.message =~ "mv #{folder} #{storage_path}/\n"
    end

    test "quotes paths in the move command when the shell needs it", %{tmp_dir: tmp_dir} do
      upload_path = Path.join(tmp_dir, "my uploads")
      storage_path = Path.join(tmp_dir, "it's storage")
      File.mkdir_p!(Path.join(upload_path, "project_node=1"))

      error =
        assert_raise RuntimeError, fn -> LocalFS.check_upload_path!(upload_path, storage_path) end

      assert error.message =~
               "mv '#{upload_path}/project_node=1' '#{String.replace(storage_path, "'", "'\\''")}'/"
    end
  end

  test "starts on S3 storage even with donation folders in the upload folder", %{
    upload_path: upload_path
  } do
    Application.put_env(:core, Systems.Storage.BuiltIn, special: S3)
    File.mkdir_p!(Path.join(upload_path, "project_node=1"))

    assert :ok = Backend.check_upload_path!()
  end
end
