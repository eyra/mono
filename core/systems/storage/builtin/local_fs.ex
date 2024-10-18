defmodule Systems.Storage.BuiltIn.LocalFS do
  @behaviour Systems.Storage.BuiltIn.Special
  use CoreWeb, :verified_routes

  @impl true
  def store(folder, filename, data) do
    folder_path = get_full_path(folder)
    File.mkdir(folder_path)
    file_path = Path.join(folder_path, filename)
    File.write!(file_path, data)
  end

  @impl true
  def list_files(folder) do
    folder_path = get_full_path(folder)
    File.ls!(folder_path)
  end

  @impl true
  def delete_files(folder) do
    folder_path = get_full_path(folder)
    File.rm_rf!(folder_path)
    :ok
  end

  defp get_full_path(folder) do
    Path.join(get_root_path(), folder)
  end

  def get_root_path do
    Application.get_env(:core, :upload_path)
  end
end
