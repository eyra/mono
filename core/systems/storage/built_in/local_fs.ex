defmodule Systems.Storage.BuiltIn.LocalFS do
  @behaviour Systems.Storage.BuiltIn.Special
  use CoreWeb, :verified_routes

  @impl true
  def store(folder, identifier, data) do
    filename = Enum.join(identifier, "_") <> ".json"
    folder_path = get_full_path(folder)
    File.mkdir(folder_path)
    file_path = Path.join(folder_path, filename)
    File.write!(file_path, data)
  end

  defp get_full_path(folder) do
    Path.join(get_root_path(), folder)
  end

  def get_root_path do
    Application.get_env(:core, :upload_path)
  end
end
