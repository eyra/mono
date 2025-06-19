defmodule Systems.Affiliate.Html do
  @moduledoc """
  HTML components for the Affiliate system.
  """
  use CoreWeb, :html

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Annotation

  attr(:title, :string, required: true)
  attr(:annotation, :any, default: nil)
  attr(:url, :string, required: true)

  def url_panel(assigns) do
    ~H"""
      <Panel.flat bg_color="bg-grey1">
         <:title>
            <div class="text-title3 font-title3 text-white">
               <%= @title %>
            </div>
         </:title>
         <.spacing value="S" />
         <%= if @annotation do %>
            <Annotation.view annotation={@annotation} />
         <% end %>
         <%= if @url do %>
            <.spacing value="S" />
            <div class="flex flex-row gap-6 items-center">
            <div class="flex-wrap">
                  <Text.body_large color="text-white"><span class="break-all"><%= @url %></span></Text.body_large>
            </div>
            <div class="flex-wrap flex-shrink-0 mt-1">
               <div id="copy-assignment-url" class="cursor-pointer" phx-hook="Clipboard" data-text={@url}>
                  <Button.Face.label_icon
                     label={dgettext("eyra-ui", "copy.clipboard.button")}
                     icon={:clipboard_tertiary}
                     text_color="text-tertiary"
                  />
               </div>
            </div>
            </div>
         <% end %>
      </Panel.flat>
    """
  end
end
