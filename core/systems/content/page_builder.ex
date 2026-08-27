defmodule Systems.Content.PageBuilder do
  @moduledoc false
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.NotificationView
  alias Phoenix.LiveView.Socket
  alias Systems.Account

  @callback set_status(socket :: Socket.t(), status :: atom()) ::
              Socket.t()

  def handle_request_verification(%{assigns: %{fabric: fabric}} = socket) do
    child =
      Fabric.prepare_child(fabric, :request_verification_view, NotificationView, %{
        title: dgettext("eyra-content", "request.verification.title"),
        body: dgettext("eyra-content", "request.verification.body")
      })

    socket
    |> Fabric.add_child(child)
    |> Fabric.ModalController.show_modal(:request_verification_view, :compact)
  end

  defmacro __using__(_) do
    quote do
      @behaviour Systems.Content.PageBuilder

      alias Systems.Content

      def handle_publish(%{assigns: %{current_user: %{id: user_id}}} = socket) do
        # reload user for latest config
        if Content.Private.can_user_publish?(Account.Public.get!(user_id)) do
          set_status(socket, :online)
        else
          Content.PageBuilder.handle_request_verification(socket)
        end
      end

      def handle_retract(socket) do
        set_status(socket, :offline)
      end

      def handle_close(socket) do
        set_status(socket, :idle)
      end

      def handle_open(socket) do
        set_status(socket, :concept)
      end
    end
  end
end
