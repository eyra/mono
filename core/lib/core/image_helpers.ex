defmodule Core.ImageHelpers do
  def catalog, do: Application.get_env(:core, :image_catalog)

  def get_image_url(image_id, width \\ 800, height \\ 600)

  def get_image_url(nil, _, _) do
    temp_default_image_url()
  end

  def get_image_url(image_id, width, height) when is_binary(image_id) do
    catalog().info(image_id, width: width, height: height).url
  end

  defp temp_default_image_url do
    "https://images.unsplash.com/photo-1541701494587-cb58502866ab?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=3900&q=80"
  end
end
