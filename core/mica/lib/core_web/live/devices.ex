defmodule CoreWeb.Devices do
  @moduledoc """
  """
  use CoreWeb, :html

  attr(:devices, :any, required: true)
  attr(:label, :string, required: true)

  def devices(assigns) do
    ~H"""
    <%= if @devices do %>
      <div class="text-grey1">
        <div class="flex flex-row items-center gap-2 h-full">
          <div class="text-title6 font-title6 mr-2">
            <%= @label %>
          </div>
          <%= for device <- @devices do %>
            <div >
              <img src={~p"/images/" <> "#{device}.svg"} alt={"Select #{device}"}>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end
end
