defmodule Frameworks.Pixel.ClickableCard do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Button

  defp has_actions?(%{left_actions: [_ | _]}), do: true
  defp has_actions?(%{right_actions: [_ | _]}), do: true
  defp has_actions?(_), do: false

  attr(:id, :integer, required: true)
  attr(:bg_color, :string, default: "grey6")
  attr(:size, :string, default: "h-full")

  attr(:left_actions, :list, default: [])
  attr(:right_actions, :list, default: [])

  slot(:inner_block, required: true)
  slot(:top, default: nil)
  slot(:title, required: true)
  attr(:target, :any, default: "")

  def clickable_card(assigns) do
    ~H"""
    <div
      x-data="{show_actions: false}"
      class={"h-full rounded-lg bg-#{@bg_color} #{@size}"}
    >
      <div class="flex flex-col h-full">
        <div class="flex-grow">
          <div
            class="flex flex-col cursor-pointer"
            phx-target={@target}
            phx-click="card_clicked"
            phx-value-item={@id}
          >
            <%= if @top do render_slot(@top) end %>
            <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-8">
              <%= render_slot(@title) %>
            </div>
            <div class="flex-grow" />
            <div>
              <div
                class="relative pl-6 pr-6 pb-6 lg:pl-8 lg:pr-8 lg:pb-8"
              >
                <div>
                  <%= render_slot(@inner_block) %>
                </div>
              </div>
            </div>
          </div>
        </div>
        <%= if has_actions?(assigns) do %>
        <div class="flex-wrap pl-22px pr-22px pb-22px lg:pl-30px lg:pr-30px lg:pb-30px">
          <div class="flex flex-row gap-4 items-center">
            <div x-show="!show_actions">
              <Button.dynamic
                action={%{type: :click, code: "show_actions = true"}}
                face={%{type: :icon, icon: :more_horizontal}}
              />
            </div>
            <div x-show="show_actions">
              <Button.dynamic
                action={%{type: :click, code: "show_actions = false"}}
                face={%{type: :icon, icon: :close}}
              />
            </div>
            <%= for button <- @left_actions do %>
              <div x-show="show_actions">
                <Button.dynamic {button} />
              </div>
            <% end %>
            <div class="flex-grow" />
            <%= for button <- @right_actions do %>
              <div x-show="show_actions">
                <Button.dynamic {button} />
              </div>
            <% end %>
          </div>
        </div>
        <% end %>
      </div>
    </div>
    """
  end
end
