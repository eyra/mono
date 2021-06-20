defmodule CoreWeb.LiveForm do

  defmacro __using__(_opts) do
    quote do
      use Surface.LiveComponent

      def update(%{focus: focus}, socket) do
        {
          :ok,
          socket
          |> assign(focus: focus)
        }
      end

      def handle_event("focus", %{"field" => field}, socket) do
        claim_focus(socket)
        {
          :noreply,
          socket
          |> assign(focus: field)
        }
      end

      def hide_flash(socket) do
        send(self(), :hide_flash)
        socket
      end

      def flash_error(socket) do
        send(self(), {:flash, :error})
        socket
      end

      def schedule_save(socket, %Ecto.Changeset{} = changeset, node_changeset) do
        socket
        |> hide_flash()

        case Ecto.Changeset.apply_action(changeset, :update) |> IO.inspect(label: "APPLY ACTION") do
          {:ok, entity} ->
            handle_success(socket, changeset, node_changeset, entity)

          {:error, %Ecto.Changeset{} = changeset} ->
            handle_validation_error(socket, changeset)
        end
      end

      defp handle_validation_error(socket, changeset) do
        socket
        |> assign(changeset: changeset)
        |> flash_error()
      end

      defp handle_success(socket, changeset, node_changeset, entity) do
        changesets =  %{
          "#{socket.assigns.id}_tool" => changeset,
          "#{socket.assigns.id}_node" => node_changeset
        }

        schedule_save(changesets)

        socket
        |> assign(:entity, entity)
      end

      defp schedule_save(changesets) do
        send(self(), {:schedule_save, changesets})
      end

      defp claim_focus(%{assigns: %{id: id}}) do
        send(self(), {:claim_focus, id})
      end

    end
  end
end
