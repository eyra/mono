defmodule Systems.Content.PageBuilder do
  import CoreWeb.Gettext

  alias Phoenix.LiveView.Socket
  alias Frameworks.Pixel.NotificationView

  alias Systems.Account

  @callback set_status(socket :: Socket.t(), status :: atom()) :: Socket.t()

  def handle_request_verification(%{assigns: %{fabric: fabric}} = socket) do
    child =
      Fabric.prepare_child(fabric, :request_verification_view, NotificationView, %{
        title: dgettext("eyra-content", "request.verification.title"),
        body: dgettext("eyra-content", "request.verification.body")
      })

    socket
    |> Fabric.add_child(child)
    |> Fabric.show_modal(:request_verification_view, :notification)
  end

  defmacro __using__(_) do
    quote do
      @behaviour Systems.Content.PageBuilder
      alias Systems.Content

      def handle_publish(%{assigns: %{current_user: %{id: user_id}}} = socket) do
        # reload user for latest config
        if Content.Private.can_user_publish?(Account.Public.get!(user_id)) do
          socket |> set_status(:online)
        else
          Content.PageBuilder.handle_request_verification(socket)
        end
      end

      def handle_retract(socket) do
        socket |> set_status(:offline)
      end

      def handle_close(socket) do
        socket |> set_status(:idle)
      end

      def handle_open(socket) do
        socket |> set_status(:concept)
      end
    end
  end
end
