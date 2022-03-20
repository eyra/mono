defmodule CoreWeb.MultiFormAutoSave do
  import CoreWeb.Gettext
  alias Phoenix.LiveView.Socket
  alias Frameworks.Pixel.Flash

  @callback handle_auto_save_done(socket :: Socket.t()) :: Socket.t()

  def put_saved_flash(socket) do
    socket |> Flash.put_info(dgettext("eyra-ui", "saved.info.flash"))
  end

  def hide_flash(socket) do
    socket |> Flash.hide()
  end

  def put_flash(type, message, socket) do
    socket |> Flash.put(type, message, true)
  end

  def put_error_flash(socket) do
    socket
    |> Flash.put_error()
    |> Flash.schedule_hide()
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour CoreWeb.MultiFormAutoSave

      alias CoreWeb.MultiFormAutoSave
      alias Core.Repo
      alias Core.Persister
      alias Phoenix.LiveView
      alias Phoenix.LiveView.Socket

      def auto_save(socket, changeset) do
        Persister.save(changeset.data, changeset)

        socket
        |> put_saved_flash()
        |> handle_auto_save_done()
      end

      def put_saved_flash(socket) do
        MultiFormAutoSave.put_saved_flash(socket)
      end

      # Handle Event

      def handle_info({:auto_save, changeset}, socket) do
        {
          :noreply,
          socket
          |> auto_save(changeset)
        }
      end

      def handle_info({:flash, type, message}, socket) do
        MultiFormAutoSave.put_flash(type, message, socket)
        {:noreply, socket}
      end

      def handle_info({:flash, :error}, socket) do
        MultiFormAutoSave.put_error_flash(socket)
        {:noreply, socket}
      end
    end
  end
end
