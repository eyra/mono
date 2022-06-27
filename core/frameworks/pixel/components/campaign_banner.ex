defmodule Frameworks.Pixel.CampaignBanner do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use Surface.Component

  prop(photo_url, :string, required: true)
  prop(placeholder_photo_url, :string, required: true)
  prop(title, :string, required: true)
  prop(subtitle, :string, required: true)
  prop(url, :string, required: true)

  defp sanitize(nil), do: nil
  defp sanitize(""), do: nil
  defp sanitize("http://" <> _rest = url), do: url
  defp sanitize("https://" <> _rest = url), do: url
  defp sanitize(url), do: "https://" <> url

  def render(assigns) do
    ~F"""
    <div class="w-full sm:h-campaign-banner bg-grey1 rounded overflow-hidden">
      <div class="flex flex-col sm:flex-row items-center h-full ml-6 mr-6 mb-6 mt-6 sm:mb-0 sm:ml-11 sm:mr-11 sm:mt-0">
        <div class="bg-grey4 w-40 h-40 rounded-full overflow-hidden flex-shrink-0">
          <img
            class="object-cover w-full h-full"
            src={if @photo_url do
              @photo_url
            else
              @placeholder_photo_url
            end}
          />
        </div>
        <div class="mt-6 sm:mt-0 sm:ml-11 text-left w-full flex-wrap">
          <div class="text-title4 font-title4 sm:text-title2 sm:font-title2 text-white">{@title}</div>
          <div class="mb-2" />
          <div class="text-title6 font-title6 sm:text-title5 sm:font-title5 text-white">{@subtitle}</div>
          <div class="mb-2" />
          <a
            :if={sanitize(@url) != nil}
            class="text-white text-body font-bodylinkmedium underline"
            href={"#{sanitize(@url)}"}
          >
            Bezoek website
          </a>
        </div>
      </div>
    </div>
    """
  end
end
