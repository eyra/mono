defmodule Systems.Storage.EndpointForm.Helper do
  defmacro __using__(model) do
    quote do
      use CoreWeb.LiveForm, :fabric
      use Fabric.LiveComponent

      alias unquote(model), as: Model

      # Handle initial update
      @impl true
      def update(
            %{id: id, model: model},
            socket
          ) do
        {
          :ok,
          socket
          |> assign(
            id: id,
            model: model,
            attrs: %{},
            show_errors: false
          )
          |> update_changeset()
        }
      end

      @impl true
      def handle_event("save", %{"endpoint_model" => attrs}, socket) do
        {
          :noreply,
          socket
          |> assign(attrs: attrs)
          |> update_changeset()
        }
      end

      @impl true
      def handle_event("show_errors", _payload, %{assigns: %{changeset: changeset}} = socket) do
        {
          :noreply,
          socket |> assign(show_errors: true)
        }
      end

      defp update_changeset(%{assigns: %{id: id, model: model, attrs: attrs}} = socket) do
        changeset =
          Model.changeset(model, attrs)
          |> Model.validate()

        changeset =
          if model.id do
            Map.put(changeset, :action, :update)
          else
            Map.put(changeset, :action, :insert)
          end

        socket
        |> assign(:changeset, changeset)
        |> send_event(:parent, "update", %{changeset: changeset})
      end
    end
  end
end
