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
      import Fabric
      import Fabric.Html

      def update(%{fabric_event: %{name: name, payload: payload}}, socket) do
        {:noreply, socket} = __MODULE__.handle_event(name, payload, socket)
        {:ok, socket}
      end

      def update(%{id: _id, fabric: fabric} = params, socket) do
        params = Map.drop(params, [:fabric])
        socket = assign(socket, fabric: fabric)
        update(params, socket)
      end
    end
  end
end
