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

      defp cancel_save_timer(%Socket{} = socket) do
        update_in(socket.assigns.save_timer, fn timer ->
          cancel_save_timer(timer)
          Process.send_after(self(), :save, @save_delay * 1_000)
        end)
      end

      defp cancel_save_timer(timer), do: Process.cancel_timer(timer)

      def save(%{assigns: %{changesets: changesets}} = socket) do
        changesets
        |> Enum.each(fn {_, changeset} ->
          Persister.save(changeset.data, changeset)
        end)

        socket
        |> assign(changesets: %{})
        |> put_saved_flash()
        |> schedule_hide_flash()
        |> handle_auto_save_done()
      end

      def schedule_save(socket, id, changeset) do
        socket
        |> cancel_save_timer()
        |> merge(id, changeset)
      end

      def force_save(socket, id, changeset) do
        socket
        |> cancel_save_timer()
        |> merge(id, changeset)
        |> save()
      end

      defp merge(socket, id, changeset) do
        update_in(socket.assigns.changesets, fn existing_changesets ->
          Map.merge(existing_changesets, %{id => changeset})
        end)
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

      def handle_info(:save, socket) do
        {
          :noreply,
          socket
          |> save()
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

      def handle_info({:force_save, %{id: id, changeset: changeset}}, socket) do
        {
          :noreply,
          socket
          |> force_save(id, changeset)
        }
      end
    end
  end
end
