defmodule Systems.Observatory.LiveFeature do
  @callback handle_view_model_updated(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Systems.Observatory.LiveFeature

      @impl true
      def handle_view_model_updated(socket), do: socket

      defoverridable handle_view_model_updated: 1

      @presenter Frameworks.Concept.System.presenter(__MODULE__)

      use Gettext, backend: CoreWeb.Gettext
      alias Systems.Observatory

      # Stubs for messages that are handled in Live Hooks
      def handle_info(%Phoenix.Socket.Broadcast{}, socket), do: {:noreply, socket}
      def handle_info(:view_model_updated, socket), do: {:noreply, socket}

      def observe_view_model(%{assigns: %{authorization_failed: true}} = socket) do
        socket
      end

      def observe_view_model(%{assigns: %{model: %{id: id} = model}} = socket) do
        socket
        |> Observatory.Public.observe([{__MODULE__, [id]}])
        |> Observatory.Public.update_view_model(__MODULE__, model, @presenter)
      end

      def update_view_model(%{assigns: %{model: model}} = socket) do
        socket
        |> Observatory.Public.update_view_model(__MODULE__, model, @presenter)
      end

      def put_info_flash(socket, from_pid) do
        if from_pid == self() do
          socket |> put_saved_info_flash()
        else
          socket |> put_updated_info_flash()
        end
      end

      def put_updated_info_flash(socket) do
        socket |> Frameworks.Pixel.Flash.put_info("Updated")
      end

      def put_saved_info_flash(socket) do
        socket |> Frameworks.Pixel.Flash.put_info("Saved")
      end
    end
  end
end
