defmodule EyraUI.AutoSave do
  @moduledoc """
  Provides support for creating edit views the Eyra way (autosave etc.).
  """
  import Phoenix.LiveView, only: [assign: 2, assign: 3, put_flash: 3]
  alias Phoenix.LiveView.Socket

  @save_delay 1

  @callback load(params :: %{}, session :: map(), socket :: Socket.t()) :: any()
  @callback save(changeset :: any()) :: any()
  @callback get_changeset(entity :: any()) :: any()
  @callback get_changeset(entity :: any(), attrs :: any()) :: any()

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

  def handle_validation_error(socket, changeset) do
    {:noreply,
     socket
     |> assign(changeset: changeset)
     |> put_flash(:error, "Please correct the indicated errors.")}
  end

  def handle_success(socket, changeset, entity_name, entity) do
    {:noreply,
     socket
     |> schedule_save(changeset)
     |> assign(entity_name, entity)}
  end

  def update_changeset(socket, changeset, entity_name) do
    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, entity} ->
        handle_success(socket, changeset, entity_name, entity)

      {:error, %Ecto.Changeset{} = changeset} ->
        handle_validation_error(socket, changeset)
    end
  end

  def mount(entity_name, entity, changeset, socket) do
    socket =
      socket
      |> assign(
        changeset: changeset,
        save_changeset: changeset,
        save_timer: nil
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

      data(unquote(entity_var), :any)
      data(changeset, :any)

      def mount(params, session, socket) do
        entity = load(params, session, socket)
        changeset = get_changeset(entity)
        AutoSave.mount(unquote(entity_name), entity, changeset, socket)
      end

      def handle_event(
            "save",
            params,
            socket
          ) do
        entity_name = unquote(entity_name)
        entity = socket.assigns[entity_name]
        attrs = params[entity_name |> to_string]
        changeset = get_changeset(entity, attrs)

        AutoSave.update_changeset(socket, changeset, entity_name)
      end

      def handle_info(:save, %{assigns: %{save_changeset: changeset}} = socket) do
        {:ok, entity} = save(changeset)

        {:noreply,
         socket
         |> assign(unquote(entity_name), entity)}
      end

      def terminate(_reason, %{assigns: %{save_changeset: changeset}}) do
        {:ok, _} = save(changeset)
        :ok
      end
    end
  end
end
