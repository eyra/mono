defmodule Fabric.LiveComponent do
  defmodule RefModel do
    @type t :: %__MODULE__{id: atom() | binary(), name: atom() | binary(), module: atom()}
    defstruct [:id, :name, :module]
  end

  defmodule Model do
    @type ref :: Fabric.LiveComponent.RefModel.t()
    @type params :: map()
    @type t :: %__MODULE__{ref: ref, params: params}
    defstruct [:ref, :params]
  end

  defmacro __using__(_opts) do
    quote do
      use Fabric
      use Phoenix.LiveComponent

      @impl true
      def update(
            %{
              fabric_event: %{name: :handle_modal_closed, payload: %{live_component: %{ref: ref}}}
            },
            %{assigns: %{fabric: fabric}} = socket
          ) do
        # Sent from Fabric.handle_modal_closed/2 indicating this live component has been closed as a modal view. Notify the parent.
        {:ok, socket |> send_event(:parent, :handle_modal_closed)}
      end

      @impl true
      def update(
            %{fabric_event: %{name: :handle_modal_closed, payload: %{source: %{name: name}}}},
            %{assigns: %{fabric: fabric}} = socket
          ) do
        socket =
          if function_exported?(__MODULE__, :handle_modal_closed, 2) do
            apply(__MODULE__, :handle_modal_closed, [socket, name])
          else
            socket
          end

        {:ok, socket}
      end

      @impl true
      def update(%{fabric_event: %{name: name, payload: payload}}, socket) do
        {:noreply, socket} = handle_event(name, payload, socket)
        {:ok, socket}
      end

      @impl true
      def update(%{id: _id, fabric: fabric} = params, %{assigns: %{fabric: _}} = socket) do
        # only assign fabric once
        params = Map.drop(params, [:fabric])
        update(params, socket)
      end

      @impl true
      def update(%{id: id, fabric: fabric} = params, socket) do
        params = Map.drop(params, [:fabric])
        socket = assign(socket, id: id, fabric: fabric)
        update(params, socket)
      end

      @impl true
      def handle_event(_name, _payload, socket) do
        Logger.error("[#{__MODULE__}] handle_event/3 not implemented")
        {:noreply, socket}
      end

      defoverridable handle_event: 3
    end
  end
end

defimpl String.Chars, for: Fabric.LiveComponent.RefModel do
  def to_string(term) do
    "#{term.id}"
  end
end
