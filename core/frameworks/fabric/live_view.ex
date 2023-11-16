defmodule Fabric.LiveView do
  defmodule RefModel do
    @type t :: %__MODULE__{pid: pid()}
    defstruct [:pid]
  end

  defmacro __using__(_opts) do
    quote do
      import Fabric
      import Fabric.Html

      @before_compile Fabric.LiveView

      def handle_info(%{fabric_event: %{name: name, payload: payload}}, socket) do
        __MODULE__.handle_event(name, payload, socket)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      @doc """
      Automatically assigns Fabric to the socket on mount
      """
      def mount(params, session, socket) do
        self = %Fabric.LiveView.RefModel{pid: self()}
        fabric = %Fabric.Model{parent: nil, self: self, children: []}
        socket = Phoenix.Component.assign(socket, :fabric, fabric)
        super(params, session, socket)
      end
    end
  end
end
