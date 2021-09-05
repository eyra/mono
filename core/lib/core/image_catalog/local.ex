defmodule Core.ImageCatalog.Local do
  @behaviour Core.ImageCatalog

  def search(query, page, page_size) when query == "" do
    %{
      images: [],
      meta: %{
        image_count: 0,
        page_count: 0,
        page: page,
        page_size: page_size,
        begin: page * page_size - page_size,
        end: page * page_size
      }
    }
  end

  def search(query, page, page_size) when query != "" do
    images =
      list_image_ids()
      |> Enum.filter(&String.contains?(&1, query))

    image_count = Enum.count(images)

    %{
      images: images,
      meta: %{
        image_count: image_count,
        page_count: 1,
        page: page,
        page_size: page_size,
        begin: page * page_size - page_size,
        end: page * page_size
      }
    }
  end

  def search_info(query, page, page_size, opts) do
    search_result = search(query, page, page_size)

    %{
      search_result
      | images: search_result.images |> Enum.map(&info(&1, opts))
    }
  end

  def info(image_id, _opts) do
    if info = Map.get(image_map(), image_id) do
      url = "/image-catalog/#{info.file_name}"

      %{
        id: info.id,
        url: url,
        srcset: "#{url} 1x",
        width: info.width,
        height: info.height,
        blur_hash: nil
      }
    end
  end

  def random(count \\ 2) do
    list_image_ids()
    |> Enum.take_random(count)
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
    Application.app_dir(:core, "priv/static/image_catalog")
  end

  defp list_files do
    File.ls!(root_dir())
  end

  defp list_image_ids, do: Map.keys(image_map())

  defp image_map do
    list_files() |> Enum.map(&file_name_to_image_info/1) |> Enum.into(%{}, &{&1.id, &1})
  end
end
