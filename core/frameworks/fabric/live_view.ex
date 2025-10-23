defmodule Fabric.LiveView do
  defmodule RefModel do
    @type t :: %__MODULE__{pid: pid()}
    defstruct [:pid]
  end

  defmacro __using__(_) do
    quote do
      # Function handle_event/3 only terminates with explicit exception.
      @dialyzer {:nowarn_function, handle_event: 3}

      use Fabric

      @impl true
      def handle_event(_name, _payload, _socket) do
        raise "handle_event/3 not implemented"
      end

      defoverridable handle_event: 3

      @impl true
      def handle_info(
            %{fabric_event: %{name: :handle_modal_closed, payload: %{source: %{name: name}}}},
            socket
          ) do
        socket =
          if function_exported?(__MODULE__, :handle_modal_closed, 2) do
            apply(__MODULE__, :handle_modal_closed, [socket, name])
          else
            socket
          end

        {:noreply, socket}
      end

      @impl true
      def handle_info(%{fabric_event: %{name: name, payload: payload}}, socket) do
        handle_event(name, payload, socket)
      end

      @impl true
      def handle_info({ref, %{async: async}}, socket) do
        Process.demonitor(ref, [:flush])
        handle_async(socket, async)
      end

      defp handle_async(socket, %{
             source: %Fabric.LiveComponent.RefModel{} = live_component,
             event: name,
             result: result
           }) do
        Fabric.send_event(live_component, %{name: name, payload: result})
        {:noreply, socket}
      end

      defp handle_async(socket, %{
             source: %Fabric.LiveView.RefModel{},
             event: name,
             result: result
           }) do
        handle_event(name, result, socket)
      end
    end
  end
end

defimpl String.Chars, for: Fabric.LiveView.RefModel do
  def to_string(term) do
    "#{inspect(term.pid)}"
  end
end
