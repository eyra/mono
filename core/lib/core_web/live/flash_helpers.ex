defmodule CoreWeb.Live.FlashHelpers do
  @moduledoc """
  Reusable flash message helpers for LiveView and LiveComponent.

  Provides convenience functions for showing flash messages that work
  across different view types (live_component, embedded_live_view, etc.).

  ## Usage

      use CoreWeb.Live.FlashHelpers

  ## Functions

  - `hide_flash/1` - Hides any visible flash message
  - `flash_info/2` - Shows an info flash message
  - `flash_error/1` - Shows a generic error flash message
  - `flash_error/2` - Shows a custom error flash message
  - `flash_persister_saved/1` - Shows the standard "Saved" message
  - `flash_persister_error/1` - Shows the standard persister error message
  - `flash_persister_error/2` - Shows a custom persister error message
  """

  defmacro __using__(_opts) do
    quote do
      use Gettext, backend: CoreWeb.Gettext

      def hide_flash(socket) do
        Frameworks.Pixel.Flash.push_hide(socket)
        socket
      end

      def flash_info(socket, message) do
        Frameworks.Pixel.Flash.push_info(socket, message)
        socket
      end

      def flash_error(socket) do
        Frameworks.Pixel.Flash.push_error(socket)
        socket
      end

      def flash_error(socket, message) do
        Frameworks.Pixel.Flash.push_error(socket, message)
        socket
      end

      def flash_persister_error(socket) do
        flash_persister_error(socket, dgettext("eyra-ui", "persister.error.flash"))
      end

      def flash_persister_error(socket, message) do
        Frameworks.Pixel.Flash.push_error(socket, message)
        socket
      end

      def flash_persister_saved(socket) do
        message = dgettext("eyra-ui", "persister.saved.flash")
        Frameworks.Pixel.Flash.push_info(socket, message)
        socket
      end
    end
  end
end
