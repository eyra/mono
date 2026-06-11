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
      |> assign_new(:confirm_label, fn ->
        Map.get(assigns, :confirm_label, dgettext("eyra-ui", "confirm.button"))
      end)
      |> assign_new(:cancel_label, fn ->
        Map.get(assigns, :cancel_label, dgettext("eyra-ui", "cancel.button"))
      end)
      # Optional custom confirm action (e.g. an http_get link to an external
      # URL). Defaults to a "confirm" send event handled by the parent.
      |> assign_new(:confirm_action, fn -> Map.get(assigns, :confirm_action) end)
      |> update_buttons()
    }
  end

  defp update_buttons(
         %{
           assigns: %{
             myself: myself,
             confirm_label: confirm_label,
             cancel_label: cancel_label,
             confirm_action: confirm_action
           }
         } = socket
       ) do
    confirm = %{
      action: confirm_action || %{type: :send, target: myself, event: "confirm"},
      face: %{type: :primary, label: confirm_label}
    }

    cancel = %{
      action: %{type: :send, target: myself, event: "cancel"},
      face: %{type: :secondary, label: cancel_label}
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
