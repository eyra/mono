defmodule Frameworks.Pixel.ConfirmationModal do
  use CoreWeb, :live_component

  @impl true
  def update(%{assigns: assigns}, socket) do
    {
      :ok,
      socket
      |> assign_new(:title, fn ->
        Map.get(assigns, :title, dgettext("eyra-ui", "confirmation_modal.title"))
      end)
      |> assign_new(:body, fn ->
        Map.get(assigns, :body, dgettext("eyra-ui", "confirmation_modal.body"))
      end)
      |> update_buttons()
    }
  end

  defp update_buttons(%{assigns: %{myself: myself}} = socket) do
    confirm = %{
      action: %{type: :send, target: myself, event: "confirm"},
      face: %{type: :primary, label: dgettext("eyra-ui", "confirm.button")}
    }

    cancel = %{
      action: %{type: :send, target: myself, event: "cancel"},
      face: %{type: :secondary, label: dgettext("eyra-ui", "cancel.button")}
    }

    assign(socket, buttons: [confirm, cancel])
  end

  def handle_event("confirm", _, socket) do
    {:noreply, socket |> send_event(:parent, "confirmed")}
  end

  def handle_event("cancel", _, socket) do
    {:noreply, socket |> send_event(:parent, "cancelled")}
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div>
        <Text.title2>
          <%= @title %>
        </Text.title2>

        <.spacing value="M" />

        <Text.body_large>
          <%= @body %>
        </Text.body_large>

        <.spacing value="M" />

        <div class="flex flex-row gap-4">
        <%= for button <- @buttons do %>
          <Button.dynamic {button} />
        <% end %>
      </div>
      </div>
    """
  end
end
