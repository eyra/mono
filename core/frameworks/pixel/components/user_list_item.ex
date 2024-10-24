defmodule Frameworks.Pixel.UserListItem do
  @moduledoc """
    User list item
  """
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  attr(:photo_url, :string, required: true)
  attr(:name, :string, default: nil)
  attr(:email, :string, required: true)
  attr(:info, :string, default: nil)
  attr(:action_buttons, :map, default: nil)

  def small(assigns) do
    ~H"""
    <tr class="h-12">
      <td class="w-[44px]">
        <img
          src={@photo_url}
          class="rounded-full w-8 h-8 border-2 border-grey4"
          alt=""
        />
      </td>
      <td>
        <Text.label><%= @name %></Text.label>
      </td>
      <td>
        <Text.body_small><%= @email %></Text.body_small>
      </td>
      <%= if @info do %>
        <td>
          <Text.body_small color="text-grey2"><%= @info %></Text.body_small>
        </td>
      <% end %>
      <%= if @action_buttons do %>
        <td>
          <div class="flex flex-row">
            <div class="flex-grow" />
            <Button.dynamic_bar buttons={@action_buttons} />
          </div>
        </td>
      <% end %>
    </tr>
    """
  end
end
