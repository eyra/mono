defmodule Systems.Content.LocalFS do
  use CoreWeb, :verified_routes

  def public_path, do: "/uploads"

  def get_public_url(path) do
    filename = Path.basename(path)
    base_url = get_base_url()
    "#{base_url}/uploads/#{filename}"
  end

  def store(path, original_filename) do
    uuid = Ecto.UUID.generate()
    root_path = get_root_path()
    new_path = "#{root_path}/#{uuid}_#{original_filename}"
    File.cp!(path, new_path)
    new_path
  end

  def get_root_path do
    Application.get_env(:core, :upload_path)
  end

  def get_base_url do
    Application.get_env(:core, :base_url)
  end

  def remove(path) do
    with {:ok, _} <- File.rm_rf(path) do
      :ok
    end
  end
end
