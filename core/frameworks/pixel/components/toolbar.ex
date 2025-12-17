defmodule Frameworks.Pixel.Toolbar do
  @moduledoc """
  Toolbar LiveComponent that centralizes button event handling and forwards events
  to the parent via LiveNest events.
  """
  use CoreWeb, :live_component

  import Frameworks.Pixel.Line
  alias Frameworks.Pixel.Button

  @impl true
  def update(%{id: id, buttons: buttons} = assigns, socket) do
    close_button = Map.get(assigns, :close_button)
    mobile_close_button = Map.get(assigns, :mobile_close_button)

    {
      :ok,
      socket
      |> assign(
        id: id,
        buttons: buttons,
        close_button: close_button,
        mobile_close_button: mobile_close_button
      )
      |> update_toolbar_buttons()
    }
  end

  defp update_toolbar_buttons(%{assigns: %{buttons: buttons, myself: myself}} = socket) do
    toolbar_buttons =
      buttons
      |> Enum.with_index()
      |> Enum.map(fn {button, index} ->
        rewrite_button_action(button, index, myself)
      end)

    assign(socket, toolbar_buttons: toolbar_buttons)
  end

  defp rewrite_button_action(%{action: %{event: event}, face: face}, _index, myself) do
    %{
      action: %{
        type: :send,
        event: "button_click",
        item: event,
        target: myself
      },
      face: face
    }
  end

  @impl true
  def handle_event("button_click", %{"item" => action}, socket) do
    socket = publish_event(socket, {:toolbar_action, %{action: String.to_atom(action)}})
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", %{"item" => element_id}, socket) do
    socket = publish_event(socket, {:close, %{modal_id: element_id}})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="toolbar" class="w-full h-full bg-white">
      <div class="px-4 sm:px-8">
        <.line />
        <div class="flex flex-row w-full h-[56px] gap-4 sm:gap-8">
          <.close_button
            close_button={@close_button}
            mobile_close_button={@mobile_close_button}
            buttons={@toolbar_buttons}
          />
          <div class="flex-grow" />
          <%= for button <- @toolbar_buttons do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr(:close_button, :map, required: true)
  attr(:mobile_close_button, :map, default: nil)
  attr(:buttons, :list, default: [])

  defp close_button(%{close_button: nil} = assigns) do
    ~H""
  end

  defp close_button(%{mobile_close_button: nil} = assigns) do
    ~H"""
    <Button.dynamic {@close_button} />
    """
  end

  defp close_button(%{buttons: []} = assigns) do
    ~H"""
    <Button.dynamic {@close_button} />
    """
  end

  defp close_button(assigns) do
    ~H"""
    <div class="sm:hidden">
      <Button.dynamic {@mobile_close_button} />
    </div>
    <div class="hidden sm:block">
      <Button.dynamic {@close_button} />
    </div>
    """
  end
end
