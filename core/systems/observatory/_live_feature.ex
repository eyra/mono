defmodule Systems.Observatory.LiveFeature do
  @moduledoc false
  alias Phoenix.LiveView.Socket

  @callback handle_view_model_updated(Socket.t()) :: Socket.t()

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Systems.Observatory.LiveFeature

      use Gettext, backend: CoreWeb.Gettext

      alias Frameworks.Pixel.Flash
      alias Systems.Observatory

      @impl true
      def handle_view_model_updated(socket), do: socket

      defoverridable handle_view_model_updated: 1

      @presenter Frameworks.Concept.System.presenter(__MODULE__)

      # Stubs for messages that are handled in Live Hooks
      def handle_info(%Phoenix.Socket.Broadcast{}, socket), do: {:noreply, socket}
      def handle_info(:view_model_updated, socket), do: {:noreply, socket}

      def observe_view_model(%{assigns: %{authorization_failed: true}} = socket) do
        socket
      end

      def observe_view_model(%{assigns: %{model: %{id: id} = model}} = socket) do
        user_id =
          if current_user = Map.get(socket.assigns, :current_user) do
            current_user.id
          else
            0
          end

        socket
        |> Observatory.Public.observe([
          {__MODULE__, [id]},
          {__MODULE__, [id, user_id]}
        ])
        |> Observatory.Public.update_view_model(__MODULE__, model, @presenter)
      end

      def update_view_model(%{assigns: %{model: model}} = socket) do
        Observatory.Public.update_view_model(socket, __MODULE__, model, @presenter)
      end

      def put_info_flash(socket, from_pid) do
        if from_pid == self() do
          put_saved_info_flash(socket)
        else
          put_updated_info_flash(socket)
        end
      end

      def put_updated_info_flash(socket) do
        Flash.put_info(socket, "Updated")
      end

      def put_saved_info_flash(socket) do
        Flash.put_info(socket, "Saved")
      end
    end
  end
end
