defmodule CoreWeb.Live.FormHelpers do
  @moduledoc """
  Reusable form helpers with auto-save functionality.

  Provides convenience functions for form handling and auto-save that work
  across different view types (live_component, embedded_live_view, etc.).

  ## Requirements

  This module requires `CoreWeb.Live.FlashHelpers` to be used first for
  flash message functions.

  ## Usage

      use CoreWeb.Live.FlashHelpers
      use CoreWeb.Live.FormHelpers

  ## Functions

  - `auto_save/2` - Validates changeset and persists if valid, showing flash feedback
  """

  defmacro __using__(_opts) do
    quote do
      import Frameworks.Pixel.Form

      @doc """
      Auto-saves a changeset with flash feedback.

      1. Hides any existing flash
      2. Validates the changeset
      3. If valid, persists using Core.Persister
      4. Shows success or error flash message

      Returns the updated socket.
      """
      def auto_save(socket, changeset) do
        socket
        |> hide_flash()
        |> do_auto_save(changeset)
      end

      defp do_auto_save(socket, changeset) do
        case Ecto.Changeset.apply_action(changeset, :update) do
          {:ok, _entity} ->
            persist_changeset(socket, changeset)

          {:error, %Ecto.Changeset{} = changeset} ->
            socket
            |> assign(changeset: changeset)
            |> flash_error()
        end
      end

      defp persist_changeset(socket, changeset) do
        case Core.Persister.save(changeset.data, changeset) do
          {:ok, entity} ->
            socket
            |> assign(model: entity)
            |> update_view_model()
            |> flash_persister_saved()

          {:error, changeset} ->
            socket
            |> assign(changeset: changeset)
            |> flash_persister_error()
        end
      end
    end
  end
end
