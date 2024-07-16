defmodule Systems.Storage.EndpointForm.Helper do
  defmacro __using__(model) do
    quote do
      use CoreWeb.LiveForm
      require Logger

      alias Systems.Storage

      alias unquote(model), as: Model

      # Handle initial update
      @impl true
      def update(
            %{id: id, entity: entity},
            socket
          ) do
        changeset = Model.changeset(entity, %{})
        show_status = Map.get(socket.assigns, :show_status, false)
        loading = Map.get(socket.assigns, :loading, false)
        connected? = Map.get(socket.assigns, :connected?, false)

        {
          :ok,
          socket
          |> assign(
            id: id,
            entity: entity,
            changeset: changeset,
            show_status: show_status,
            loading: loading,
            connected?: connected?
          )
          |> update_submit_button()
        }
      end

      defp update_submit_button(%{assigns: %{loading: loading}} = socket) do
        submit_button = %{
          face: %{
            type: :primary,
            label: dgettext("eyra-storage", "account.submit.button"),
            loading: loading
          },
          action: %{type: :submit}
        }

        assign(socket, submit_button: submit_button)
      end

      @impl true
      def handle_event("change", _payload, socket) do
        {:noreply, socket |> assign(show_status: false)}
      end

      @impl true
      def handle_event(
            "save",
            %{"endpoint_model" => attrs},
            %{assigns: %{entity: entity}} = socket
          ) do
        changeset = Model.changeset(entity, attrs)

        {
          :noreply,
          socket
          |> auto_save(changeset)
          |> validate()
          |> test_connection()
        }
      end

      @impl true
      def handle_event("connected?", connected?, socket) do
        {
          :noreply,
          socket
          |> assign(connected?: connected?, loading: false, show_status: true)
          |> update_submit_button()
        }
      end

      defp validate(%{assigns: %{entity: entity}} = socket) do
        changeset =
          entity
          |> Model.changeset(%{})
          |> Model.validate()

        assign(socket, changeset: %Ecto.Changeset{changeset | action: :update})
      end

      defp test_connection(%{assigns: %{changeset: changeset, entity: entity}} = socket) do
        async(socket, "connected?", fn ->
          Storage.Public.connected?(entity)
        end)

        socket
        |> assign(loading: changeset.valid?, show_status: false)
        |> update_submit_button()
      end
    end
  end
end
