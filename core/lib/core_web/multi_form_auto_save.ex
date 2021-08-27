defmodule CoreWeb.MultiFormAutoSave do
  alias Phoenix.LiveView.Socket

  @callback handle_auto_save_done(socket :: Socket.t()) :: Socket.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour CoreWeb.MultiFormAutoSave

      alias Core.Repo
      alias Core.Persister
      alias Phoenix.LiveView.Socket

      # Schedule Save
      @save_delay 1

      defp cancel_save_timer(nil), do: nil
      defp cancel_save_timer(timer), do: Process.cancel_timer(timer)

      def schedule_save(socket, id, changeset) do
        socket =
          update_in(socket.assigns.save_timer, fn timer ->
            cancel_save_timer(timer)
            Process.send_after(self(), :save, @save_delay * 1_000)
          end)

        socket =
          update_in(socket.assigns.changesets, fn existing_changesets ->
            Map.merge(existing_changesets, %{id => changeset})
          end)

        socket
      end

      # Schedule Hide Message
      @hide_flash_delay 3

      defp cancel_hide_flash_timer(nil), do: nil
      defp cancel_hide_flash_timer(timer), do: Process.cancel_timer(timer)

      def schedule_hide_flash(socket) do
        update_in(socket.assigns.hide_flash_timer, fn timer ->
          cancel_hide_flash_timer(timer)
          Process.send_after(self(), :hide_flash, @hide_flash_delay * 1_000)
        end)
      end

      def hide_flash(socket) do
        cancel_hide_flash_timer(socket.assigns.hide_flash_timer)

        socket
        |> clear_flash()
      end

      def put_error_flash(socket) do
        socket
        |> put_flash(:error, dgettext("eyra-ui", "error.flash"))
      end

      def put_saved_flash(socket) do
        socket
        |> put_flash(:info, dgettext("eyra-ui", "saved.info.flash"))
      end

      # Handle Event

      def handle_info(:save, %{assigns: %{changesets: changesets}} = socket) do
        changesets
        |> Enum.each(fn {_, changeset} ->
          Persister.save(changeset.data, changeset)
        end)

        {
          :noreply,
          socket
          |> assign(changesets: %{})
          |> put_saved_flash()
          |> schedule_hide_flash()
          |> handle_auto_save_done()
        }
      end

      def handle_info(:hide_flash, socket) do
        {
          :noreply,
          socket
          |> hide_flash()
        }
      end

      def handle_info({:flash, type, message}, socket) do
        {
          :noreply,
          socket
          |> put_flash(type, message)
          |> schedule_hide_flash()
        }
      end

      def handle_info({:flash, :error}, socket) do
        {
          :noreply,
          socket
          |> put_error_flash()
          |> schedule_hide_flash()
        }
      end

      def handle_info({:schedule_save, %{id: id, changeset: changeset}}, socket) do
        {
          :noreply,
          socket
          |> schedule_save(id, changeset)
        }
      end
    end
  end
end
