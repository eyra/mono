defmodule Core.ImageHelpers do
  @default_image_id "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1447433819943-74a20887a81e%3Fixid%3DMnwyMTY0MzZ8MHwxfHNlYXJjaHw1OXx8c3BhY2V8ZW58MHx8fHwxNjIxNzU2Njc3%26ixlib%3Drb-1.2.1&username=nasa&name=NASA&blur_hash=LMG%40%7DcK%2CBX9Ec%5BxwoOrpEmtSi%7Ct6"

  def catalog, do: Application.get_env(:core, :image_catalog)

  @deprecated "use get_image_info/3"
  def get_image_url(image_id, width \\ 800, height \\ 600)

  def get_image_url(nil, _, _) do
    get_image_info(@default_image_id).url
  end

  def get_image_url(image_id, width, height) when is_binary(image_id) do
    catalog().info(image_id, width: width, height: height).url
  end

  def get_image_info(image_id, width \\ 800, height \\ 600)

  def get_image_info(nil, width, height) do
    get_image_info(@default_image_id, width, height)
  end

  def get_image_info(image_id, width, height) do
    IO.inspect(image_id, label: "image_id")
    catalog().info(image_id, width: width, height: height)
  end
end
