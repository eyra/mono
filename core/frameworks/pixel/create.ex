defmodule Frameworks.Pixel.Create do
  @moduledoc """
  Provides support for creating "new" views the Eyra way.
  """
  import Phoenix.Component
  import Phoenix.LiveView, only: [put_flash: 3, push_navigate: 2]
  alias Phoenix.LiveView.Socket

  @callback create(socket :: Phoenix.LiveView.Socket.t(), changeset :: any()) :: any()
  @callback get_changeset() :: any()
  @callback get_changeset(attrs :: any()) :: any()

  def handle_validation_error(socket, changeset) do
    {:noreply,
     socket
     |> assign(changeset: changeset)
     |> put_flash("eyra-ui", "Please correct the indicated errors.")}
  end

  def create(module, socket, changeset) do
    case module.create(socket, changeset) do
      {:ok, redirect_path} ->
        {:noreply, socket |> push_navigate(to: redirect_path, replace: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        handle_validation_error(socket, changeset)
    end
  end

  def mount(_entity_name, changeset, socket) do
    {:ok, socket |> assign(changeset: changeset)}
  end

  defmacro __using__(entity_name) do
    quote do
      @behaviour Frameworks.Pixel.Create

      alias Ecto.Changeset
      alias Frameworks.Pixel.Create

      data(changeset, :any)

      def mount(params, session, socket) do
        Create.mount(unquote(entity_name), get_changeset(), socket)
      end

      def handle_event("create", params, socket) do
        entity_name = unquote(entity_name)
        attrs = params[entity_name |> to_string]
        changeset = get_changeset(attrs)
        Create.create(__MODULE__, socket, changeset)
      end

      defoverridable mount: 3
    end
  end
end
