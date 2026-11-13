defmodule Frameworks.Pixel.ClickableCard do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use MicaWeb, :pixel

  alias Frameworks.Pixel.Button
  alias Phoenix.LiveView.JS

  defp has_actions?(%{left_actions: [_ | _]}), do: true
  defp has_actions?(%{right_actions: [_ | _]}), do: true
  defp has_actions?(_), do: false

  # Helper function to show actions
  # The toggle that has focus hides itself, so focus moves to the other one.
  defp show_actions_js(card_id) do
    JS.hide(to: "#card-#{card_id}-show-more")
    |> JS.show(to: "#card-#{card_id}-hide-more")
    |> JS.show(to: ".card-#{card_id}-actions")
    |> JS.focus(to: "#card-#{card_id}-hide-more")
  end

  # Helper function to hide actions
  defp hide_actions_js(card_id) do
    JS.show(to: "#card-#{card_id}-show-more")
    |> JS.hide(to: "#card-#{card_id}-hide-more")
    |> JS.hide(to: ".card-#{card_id}-actions")
    |> JS.focus(to: "#card-#{card_id}-show-more")
  end

  # Component for the show more button
  attr(:card_id, :any, required: true)

  def show_more_button(assigns) do
    ~H"""
    <button type="button"
         id={"card-#{@card_id}-show-more"}
         phx-click={show_actions_js(@card_id)}
         data-testid={"show_more__action__card_#{@card_id}"}>
      <Button.Face.icon icon={:more_horizontal} alt={dgettext("eyra-ui", "card.actions.show")} />
    </button>
    """
  end

  # Component for the hide button
  attr(:card_id, :any, required: true)

  def hide_button(assigns) do
    ~H"""
    <button type="button"
         id={"card-#{@card_id}-hide-more"}
         phx-click={hide_actions_js(@card_id)}
         class="hidden">
      <Button.Face.icon icon={:close} alt={dgettext("eyra-ui", "card.actions.hide")} />
    </button>
    """
  end

  # Component for action button wrapper
  attr(:card_id, :any, required: true)
  attr(:button, :map, required: true)
  attr(:index, :integer, required: true)
  attr(:position, :atom, required: true)

  def action_button(assigns) do
    event = get_in(assigns, [:button, :action, :event])

    assigns = assign(assigns, :event, event)

    ~H"""
    <div id={"card-#{@card_id}-actions-#{@position}-#{@index}"}
         class={"card-#{@card_id}-actions hidden"}
         data-testid={"#{@event}__action__card_#{@card_id}"}>
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
  slot(:title)
  attr(:target, :any, default: "")

  def clickable_card(assigns) do
    ~H"""
    <div
      class={"h-full rounded-lg bg-#{@bg_color} #{@size}"}
      id={"card-#{@id}"}
    >
      <div class="flex flex-col h-full">
        <div class="flex-grow">
          <div
            id={"card-#{@id}-open"}
            class="flex flex-col cursor-pointer h-full overflow-hidden rounded-lg"
            role="button"
            tabindex="0"
            aria-labelledby={if @title != [], do: "card-#{@id}-title"}
            phx-hook="KeyboardClick"
            phx-target={@target}
            phx-click="card_clicked"
            phx-value-item={@id}
            data-testid={"card_#{@id}"}
          >
            <%= render_slot(@top) %>
            <%= if @title != [] do %>
              <div id={"card-#{@id}-title"} class="p-6 lg:pl-8 lg:pr-8 lg:pt-8">
                <%= render_slot(@title) %>
              </div>
            <% else %>
              <div class="pt-6 px-6 lg:pl-8 lg:pr-8 lg:pt-8" />
            <% end %>
            <div class="mt-auto">
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
