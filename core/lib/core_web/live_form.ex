defmodule CoreWeb.LiveForm do
  defmacro __using__(_opts) do
    quote do
      use CoreWeb.UI.LiveComponent

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

      def flash_error(socket, message) do
        send(self(), {:flash, :error, message})
        socket
      end

      def schedule_save(socket, changeset), do: save(socket, changeset, true)

      def save(socket, changeset, schedule?) do
        socket
        |> hide_flash()

        case Ecto.Changeset.apply_action(changeset, :update) do
          {:ok, entity} ->
            handle_success(socket, changeset, entity, schedule?)

          {:error, %Ecto.Changeset{} = changeset} ->
            handle_validation_error(socket, changeset)
        end
      end

      defp handle_validation_error(socket, changeset) do
        socket
        |> assign(changeset: changeset)
        |> flash_error()
      end

      defp handle_success(socket, changeset, entity, schedule?) do
        do_save(socket, changeset, schedule?)

        socket
        |> assign(:entity, entity)
        |> assign(:changeset, changeset)
      end

      defp do_save(%{assigns: %{id: id}}, changeset, schedule?) do
        send(self(), {save_key(schedule?), %{id: id, changeset: changeset}})
      end

      defp save_key(true), do: :schedule_save
      defp save_key(_), do: :force_save

      defp claim_focus(%{assigns: %{id: id}}) do
        send(self(), {:claim_focus, id})
      end
    end
  end
end
