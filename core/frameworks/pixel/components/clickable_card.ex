defmodule Frameworks.Pixel.ClickableCard do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Button
  alias Phoenix.LiveView.JS

  defp has_actions?(%{left_actions: [_ | _]}), do: true
  defp has_actions?(%{right_actions: [_ | _]}), do: true
  defp has_actions?(_), do: false

  # Helper function to show actions
  defp show_actions_js(card_id) do
    JS.hide(to: "#card-#{card_id}-show-more")
    |> JS.show(to: "#card-#{card_id}-hide-more")
    |> JS.show(to: ".card-#{card_id}-actions")
  end

  # Helper function to hide actions
  defp hide_actions_js(card_id) do
    JS.show(to: "#card-#{card_id}-show-more")
    |> JS.hide(to: "#card-#{card_id}-hide-more")
    |> JS.hide(to: ".card-#{card_id}-actions")
  end

  # Component for the show more button
  attr(:card_id, :any, required: true)

  def show_more_button(assigns) do
    ~H"""
    <div id={"card-#{@card_id}-show-more"}
         phx-click={show_actions_js(@card_id)}>
      <Button.Face.icon icon={:more_horizontal} />
    </div>
    """
  end

  # Component for the hide button
  attr(:card_id, :any, required: true)

  def hide_button(assigns) do
    ~H"""
    <div id={"card-#{@card_id}-hide-more"}
         phx-click={hide_actions_js(@card_id)}
         class="hidden">
      <Button.Face.icon icon={:close} />
    </div>
    """
  end

  # Component for action button wrapper
  attr(:card_id, :any, required: true)
  attr(:button, :map, required: true)
  attr(:index, :integer, required: true)
  attr(:position, :atom, required: true)

  def action_button(assigns) do
    ~H"""
    <div id={"card-#{@card_id}-actions-#{@position}-#{@index}"}
         class={"card-#{@card_id}-actions hidden"}>
      <Button.dynamic {@button} />
    </div>
    """
  end

  attr(:id, :integer, required: true)
  attr(:bg_color, :string, default: "grey6")
  attr(:size, :string, default: "h-full")

  attr(:left_actions, :list, default: [])
  attr(:right_actions, :list, default: [])

  slot(:inner_block, required: true)
  slot(:top)
  slot(:title, required: true)
  attr(:target, :any, default: "")

  def clickable_card(assigns) do
    ~H"""
    <div
      class={"h-full overflow-hidden rounded-lg bg-#{@bg_color} #{@size}"}
      id={"card-#{@id}"}
    >
      <div class="flex flex-col h-full">
        <div class="flex-grow">
          <div
            class="flex flex-col cursor-pointer"
            phx-target={@target}
            phx-click="card_clicked"
            phx-value-item={@id}
          >
            <%= render_slot(@top) %>
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
            <.show_more_button card_id={@id} />
            <.hide_button card_id={@id} />

            <%= for {button, index} <- Enum.with_index(@left_actions) do %>
              <.action_button card_id={@id} button={button} index={index} position={:left} />
            <% end %>

            <div class="flex-grow" />

            <%= for {button, index} <- Enum.with_index(@right_actions) do %>
              <.action_button card_id={@id} button={button} index={index} position={:right} />
            <% end %>
          </div>
        </div>
        <% end %>
      </div>
    </div>
    """
  end
end
