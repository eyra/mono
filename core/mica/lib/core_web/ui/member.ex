defmodule CoreWeb.UI.Member do
  @moduledoc """
    Label with a pill formed background.
  """
  use CoreWeb, :ui

  alias Core.ImageHelpers

  alias Frameworks.Pixel.Button

  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:subtitle_color, :string, default: "text-grey4")
  attr(:photo_url, :string, default: nil)
  attr(:button_large, :map, required: true)
  attr(:button_small, :map, required: true)

  def member(assigns) do
    ~H"""
    <div class="bg-grey1 rounded-md p-6 sm:p-8">
      <div class="flex flex-row gap-4 md:gap-8 h-full">
        <div class="flex-shrink-0">
          <img
            src={ImageHelpers.get_photo_url(assigns)}
            class="rounded-full w-12 h-12 sm:w-16 sm:h-16 md:w-24 md:h-24 lg:w-32 lg:h-32"
            alt=""
          />
        </div>
        <div>
          <div class="h-full">
            <div class="flex flex-col h-full justify-center md:gap-3">
              <div>
                <div class="text-title6 font-title6 sm:text-title5 sm:font-title5 md:text-title4 md:font-title4 lg:text-title3 lg:font-title3 text-white"><%= @title %></div>
              </div>
              <div>
                <div class={"text-bodysmall sm:text-bodymedium lg:text-subhead font-subhead tracking-wider #{@subtitle_color}"}><%= @subtitle %></div>
              </div>
            </div>
          </div>
        </div>
        <div class="flex-grow">
        </div>
        <div class="hidden sm:block">
          <Button.dynamic {@button_large} />
        </div>
        <div class="sm:hidden">
          <Button.dynamic {@button_small} />
        </div>
      </div>
    </div>
    """
  end
end
