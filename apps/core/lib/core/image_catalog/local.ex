defmodule Core.ImageCatalog.Local do
  @behaviour Core.ImageCatalog

  def search(query) when query == "", do: []

  def search(query) when query != "" do
    list_image_ids()
    |> Enum.filter(&String.contains?(&1, query))
  end

  def search_info(query, opts) do
    query |> search() |> Enum.map(&info(&1, opts))
  end

  def info(image_id, _opts) do
    if info = Map.get(image_map(), image_id) do
      url = "/image-catalog/#{info.file_name}"
      %{id: info.id, url: url, srcset: "#{url} 1x"}
    end
  end

  defp file_name_to_image_info(file_name) do
    [_, image_id, width, height] = Regex.run(~r/(.*?)_(\d+)x(\d+).\w+/, file_name)

    %{
      id: image_id,
      width: String.to_integer(width),
      height: String.to_integer(height),
      file_name: file_name
    }
  end

  defp root_dir do
    Application.app_dir(:core, "priv/static/images")
  end

  defp list_files do
    File.ls!(root_dir())
  end

  defp list_image_ids, do: Map.keys(image_map())

  defp image_map do
    list_files() |> Enum.map(&file_name_to_image_info/1) |> Enum.into(%{}, &{&1.id, &1})
  end
end
