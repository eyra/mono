defmodule Fabric.LiveComponent do
  defmodule RefModel do
    @type t :: %__MODULE__{id: atom() | binary(), module: atom()}
    defstruct [:id, :module]
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
      def update(%{fabric_event: %{name: name, payload: payload}}, socket) do
        {:noreply, socket} = handle_event(name, payload, socket)
        {:ok, socket}
      end

      @impl true
      def update(%{id: _id, fabric: fabric} = params, socket) do
        params = Map.drop(params, [:fabric])
        socket = assign(socket, fabric: fabric)
        update(params, socket)
      end

      @impl true
      def handle_event(_name, _payload, socket) do
        Logger.error("handle_event/3 not implemented")
        {:noreply, socket}
      end

      defoverridable handle_event: 3
    end
  end
end
