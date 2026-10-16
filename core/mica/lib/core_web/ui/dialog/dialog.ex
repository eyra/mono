defmodule CoreWeb.UI.Dialog do
  use CoreWeb, :ui

  alias Frameworks.Pixel.Button

  attr(:title, :string, default: nil)
  attr(:text, :string, default: nil)
  attr(:buttons, :list, default: [])
  slot(:inner_block)

  def dialog(assigns) do
    ~H"""
    <div class="h-full">
      <div class="flex flex-col gap-4 sm:gap-8">
        <%= if @title do %>
          <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
            <%= @title %>
          </div>
        <% end %>
        <%= if @text do %>
          <div class="text-bodymedium font-body sm:text-bodylarge">
            <%= @text %>
          </div>
        <% end %>
        <div>
          <%= render_slot(@inner_block) %>
        </div>
        <div class="flex flex-row gap-4">
          <%= for button <- @buttons do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def form_dialog_buttons(target) do
    [
      %{
        action: %{type: :send, target: target, event: "submit"},
        face: %{type: :primary, label: dgettext("eyra-ui", "submit.button")}
      },
      %{
        action: %{type: :send, target: target, event: "cancel"},
        face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
      }
    ]
  end
end
