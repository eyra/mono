defmodule Frameworks.Utility.Assets do
  def image_src(asset_key, :icon), do: "/images/icons/#{asset_key}.svg"
  def image_src(asset_key, :logo), do: "/images/icons/#{asset_key}_wide.svg"
end
