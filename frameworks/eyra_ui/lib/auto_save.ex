defmodule EyraUI.AutoSave do
  @moduledoc """
  Provides support for creating edit views the Eyra way (autosave etc.).
  """
  import Phoenix.LiveView, only: [assign: 2, assign: 3, put_flash: 3, clear_flash: 1]
  alias Phoenix.LiveView.Socket
  import EyraUI.Gettext

  @save_delay 1
  @hide_message_delay 3

  @callback init(params :: %{}, session :: map(), socket :: Socket.t()) :: Socket.t()
  @callback load(params :: %{}, session :: map(), socket :: Socket.t()) :: any()
  @callback save(changeset :: any()) :: any()
  @callback get_changeset(entity :: any(), type :: atom(), attrs :: any()) :: any()

  defp cancel_save_timer(nil), do: nil
  defp cancel_save_timer(timer), do: Process.cancel_timer(timer)

  def schedule_save(socket, changeset) do
    update_in(socket.assigns.save_timer, fn timer ->
      cancel_save_timer(timer)
      Process.send_after(self(), :save, @save_delay * 1_000)
    end)
    |> assign(
      changeset: changeset,
      save_changeset: changeset
    )
  end

  defp cancel_hide_message_timer(nil), do: nil
  defp cancel_hide_message_timer(timer), do: Process.cancel_timer(timer)

  def schedule_hide_message(socket) do
    update_in(socket.assigns.hide_message_timer, fn timer ->
      cancel_hide_message_timer(timer)
      Process.send_after(self(), :hide_message, @hide_message_delay * 1_000)
    end)
  end

  def handle_validation_error(socket, changeset) do
    {:noreply,
     socket
     |> assign(changeset: changeset)
     |> put_error_flash()}
  end

  def handle_success(socket, changeset, entity_name, entity) do
    {:noreply,
     socket
     |> schedule_save(changeset)
     |> assign(entity_name, entity)}
  end

  def update_changeset(socket, changeset, entity_name) do
    socket =
      socket
      |> hide_message()

    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, entity} ->
        handle_success(socket, changeset, entity_name, entity)

      {:error, %Ecto.Changeset{} = changeset} ->
        handle_validation_error(socket, changeset)
    end
  end

  def hide_message(socket) do
    cancel_hide_message_timer(socket.assigns.hide_message_timer)

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

  def mount(entity_name, entity, changeset, socket) do
    socket =
      socket
      |> assign(
        changeset: changeset,
        save_changeset: changeset,
        save_timer: nil,
        hide_message_timer: nil,
        focus: nil
      )
      |> assign(entity_name, entity)

    {:ok, socket}
  end

  defmacro __using__(entity_name) do
    entity_var = {entity_name, [], Elixir}

    quote do
      @behaviour EyraUI.AutoSave

      alias Ecto.Changeset
      alias EyraUI.AutoSave

      require EyraUI.Gettext

      data(unquote(entity_var), :any)
      data(changeset, :any)
      data(focus, :any)

      def mount(params, session, socket) do
        socket = init(params, session, socket)
        entity = load(params, session, socket)
        changeset = get_changeset(entity, :mount, %{})
        AutoSave.mount(unquote(entity_name), entity, changeset, socket)
      end

      def handle_event("save", params, socket) do
        entity_name = unquote(entity_name)
        entity = socket.assigns[entity_name]
        attrs = params[entity_name |> to_string]

        changeset = get_changeset(entity, :auto_save, attrs)

        AutoSave.update_changeset(socket, changeset, entity_name)
      end

      def handle_info(:save, %{assigns: %{save_changeset: changeset}} = socket) do
        {:ok, entity} = save(changeset)

        {:noreply,
         socket
         |> assign(unquote(entity_name), entity)
         |> AutoSave.put_saved_flash()
         |> AutoSave.schedule_hide_message()}
      end

      def handle_info(:hide_message, socket) do
        {:noreply,
         socket
         |> AutoSave.hide_message()}
      end

      def terminate(reason, %{assigns: %{save_changeset: changeset}}) do
        {:ok, _} = save(changeset)
        :ok
      end
    end
  end
end
