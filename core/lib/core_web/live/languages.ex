defmodule CoreWeb.Languages do
  @moduledoc """
  """
  use CoreWeb, :html

  attr(:languages, :any, required: true)
  attr(:label, :string, required: true)

  def languages(assigns) do
    ~H"""
    <%= if @languages do %>
      <div class="text-grey1">
        <div class="flex flex-row items-center gap-3 h-full">
          <div class="text-title6 font-title6 mr-1">
            <%= @label %>
          </div>
          <%= for language <- @languages do %>
            <div>
              <img src={~p"/images/icons/#{"#{language}.svg"}"} alt={"#{language}"}>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end
end
