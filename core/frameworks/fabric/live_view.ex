defmodule Fabric.LiveView do
  defmodule RefModel do
    @type t :: %__MODULE__{pid: pid()}
    defstruct [:pid]
  end

  defmacro __using__(layout) do
    quote do
      use Phoenix.LiveView, layout: {unquote(layout), :live}
      unquote(helpers())
    end
  end

  defmacro __using__() do
    quote do
      use Phoenix.LiveView
      unquote(helpers())
    end
  end

  def helpers() do
    quote do
      use Fabric

      @before_compile Fabric.LiveView

      @impl true
      def handle_info(%{fabric_event: %{name: name, payload: payload}}, socket) do
        handle_event(name, payload, socket)
      end

      @impl true
      def handle_event(_name, _payload, _socket) do
        raise "handle_event/3 not implemented"
      end

      defoverridable handle_event: 3
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
        fabric = %Fabric.Model{parent: nil, self: self, children: nil}
        socket = Phoenix.Component.assign(socket, :fabric, fabric)
        super(params, session, socket)
      end
    end
  end
end

defimpl String.Chars, for: Fabric.LiveView.RefModel do
  def to_string(term) do
    "#{inspect(term.pid)}"
  end
end
