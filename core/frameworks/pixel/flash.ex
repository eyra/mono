defmodule Frameworks.Pixel.Flash do
  @moduledoc """
  Provides support for flash messages.
  """
  alias Phoenix.LiveView
  import CoreWeb.Gettext

  @hide_message_delay 3

  def mount(socket) do
    socket |> LiveView.assign(hide_timer: nil)
  end

  def schedule_hide(socket), do: schedule_hide(socket, true)
  def schedule_hide(socket, false), do: socket

  def schedule_hide(socket, true) do
    cancel_hide_timer(socket)

    socket
    |> LiveView.assign(
      hide_timer: Process.send_after(self(), :hide_flash, @hide_message_delay * 1_000)
    )
  end

  def hide(socket) do
    socket
    |> cancel_hide_timer()
    |> LiveView.clear_flash()
  end

  defp default_error(), do: dgettext("eyra-ui", "error.flash")

  def put_error(socket), do: put_error(socket, default_error())
  def put_error(socket, message), do: put(socket, :error, message, false)
  def put_info(socket, message), do: put(socket, :info, message, true)

  def put(socket, type, message, auto_hide) do
    socket
    |> LiveView.put_flash(type, message)
    |> schedule_hide(auto_hide)
  end

  def push_error(), do: push_error(default_error())
  def push_error(message), do: push(:error, message, false)
  def push_info(message), do: push(:info, message, true)

  def push(type, message, auto_hide) do
    send(self(), {:show_flash, %{type: type, message: message, auto_hide: auto_hide}})
  end

  defp cancel_hide_timer(%{assigns: %{hide_timer: hide_timer}} = socket)
       when not is_nil(hide_timer) do
    Process.cancel_timer(hide_timer)
    socket
  end

  defp cancel_hide_timer(socket), do: socket

  defmacro __using__(_opts) do
    quote do
      alias Frameworks.Pixel.Flash

      def handle_info(:hide_flash, socket) do
        {:noreply, socket |> Flash.hide()}
      end

      def handle_info(
            {:show_flash, %{type: type, message: message, auto_hide: auto_hide}},
            socket
          ) do
        {:noreply, socket |> Flash.put(type, message, auto_hide)}
      end
    end
  end
end
