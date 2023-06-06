defmodule CoreWeb.LiveForm do
  defmacro __using__(_opts) do
    quote do
      use CoreWeb, :live_component

      def hide_flash(socket) do
        Frameworks.Pixel.Flash.push_hide()
        socket
      end

      def flash_error(socket) do
        Frameworks.Pixel.Flash.push_error()
        socket
      end

      def flash_persister_error(socket) do
        message = dgettext("eyra-ui", "persister.error.flash")
        Frameworks.Pixel.Flash.push_error(message)
        socket
      end

      def flash_persister_saved(socket) do
        message = dgettext("eyra-ui", "persister.saved.flash")
        Frameworks.Pixel.Flash.push_info(message)
        socket
      end

      def save(socket, changeset) do
        socket
        |> save_closure(fn socket ->
          case Ecto.Changeset.apply_action(changeset, :update) do
            {:ok, entity} ->
              handle_success(socket, changeset, entity)

            {:error, %Ecto.Changeset{} = changeset} ->
              handle_validation_error(socket, changeset)
          end
        end)
      end

      def save_closure(socket, closure) do
        socket
        |> auto_save_begin()
        |> hide_flash()
        |> closure.()
        |> auto_save_end()
      end

      defp handle_validation_error(socket, changeset) do
        socket
        |> assign(changeset: changeset)
        |> flash_error()
      end

      defp handle_success(socket, changeset, entity) do
        socket
        |> auto_save(changeset)
      end

      defp auto_save(socket, changeset) do
        case Core.Persister.save(changeset.data, changeset) do
          {:ok, entity} ->
            socket
            |> assign(entity: entity, changeset: changeset)
            |> flash_persister_saved()
            |> handle_auto_save_done()

          {:error, changeset} ->
            socket
            |> assign(:changeset, changeset)
            |> flash_persister_error()
        end
      end

      defp handle_auto_save_done(%{assigns: %{id: id}} = socket) do
        send(self(), {:handle_auto_save_done, id})
        socket
      end

      def auto_save_begin(socket) do
        send(self(), %{auto_save: :active})
        socket
      end

      def auto_save_end(socket) do
        send(self(), %{auto_save: :idle})
        socket
      end
    end
  end
end
