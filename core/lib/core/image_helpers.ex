defmodule Core.ImageHelpers do
  @default_image_id "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1620121478247-ec786b9be2fa%3Fixid%3DM3w1MzYyOTF8MHwxfGFsbHx8fHx8fHx8fDE3MDE2NDIxNDl8%26ixlib%3Drb-4.0.3&username=ricvath&name=Richard%20Horvath&blur_hash=La3n%7Dpo_kObWi%3DZ~a2bKVXWFa%2Aoe"

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
    catalog().info(image_id, width: width, height: height)
  end

  def get_photo_url(nil), do: "/images/profile_photo_default.svg"
  def get_photo_url(%{photo_url: nil, gender: :man}), do: "/images/profile_photo_default_male.svg"

  def get_photo_url(%{photo_url: nil, gender: :woman}),
    do: "/images/profile_photo_default_female.svg"

  def get_photo_url(%{photo_url: nil}), do: "/images/profile_photo_default.svg"
  def get_photo_url(%{photo_url: photo_url}), do: photo_url
end
