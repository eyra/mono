defmodule CoreWeb.LiveForm do
  @moduledoc """
  A macro for creating live form components with auto-save functionality.

  This module provides a complete setup for live components that need
  form handling with automatic persistence and flash feedback.

  ## Usage

      use CoreWeb.LiveForm

  This is equivalent to:

      use CoreWeb, :live_component
      use CoreWeb.Live.FlashHelpers
      use CoreWeb.Live.FormHelpers

  Plus additional backward-compatible helpers for existing forms.
  """

  defmacro __using__(_) do
    quote do
      use CoreWeb, :live_component
      use CoreWeb.Live.FlashHelpers

      import Frameworks.Pixel.Form

      # Backward compatibility: existing forms use save/2
      def save(socket, changeset) do
        socket
        |> save_closure(fn socket ->
          case Ecto.Changeset.apply_action(changeset, :update) do
            {:ok, _entity} ->
              do_auto_save_legacy(socket, changeset)

            {:error, %Ecto.Changeset{} = changeset} ->
              socket
              |> assign(changeset: changeset)
              |> flash_error()
          end
        end)
      end

      def save_closure(socket, closure) do
        socket
        |> hide_flash()
        |> closure.()
      end

      # Legacy auto_save that assigns to :entity instead of :model
      # and calls handle_auto_save_done for live_component callback
      defp do_auto_save_legacy(socket, changeset) do
        case Core.Persister.save(changeset.data, changeset) do
          {:ok, entity} ->
            socket
            |> assign(entity: entity)
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
    end
  end
end
