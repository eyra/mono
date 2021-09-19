defmodule Core.Observatory do
  alias CoreWeb.Endpoint

  def subscribe(signal, key \\ []) do
    Endpoint.subscribe(topic_key(signal, key))
  end

  def dispatch(signal, key, data) do
    Endpoint.broadcast(topic_key(signal, key), "observation", {signal, data})
  end

  def local_dispatch(signal, key, data) do
    Endpoint.local_broadcast(topic_key(signal, key), "observation", {signal, data})
  end

  defp topic_key(signal, key) when is_atom(signal) and is_list(key) do
    key_str =
      key
      |> Enum.map(&to_string/1)
      |> Enum.join(":")

    "signal:#{to_string(signal)}:#{key_str}"
  end

  def observe(socket, subscriptions \\ []) do
    if Phoenix.LiveView.connected?(socket) do
      for {signal, key} <- subscriptions do
        __MODULE__.subscribe(signal, key)
      end
    end
  end

  defmacro __using__(_opts \\ []) do
    quote do
      @before_compile Core.Observatory
      import unquote(__MODULE__), only: [observe: 2]

      def handle_info(
            %{topic: _topic, payload: {signal, message}},
            socket
          ) do
        {:noreply, handle_observation(socket, signal, message)}
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def handle_observation(signal, _message, _assigns) do
        throw("No handler for observed signal: #{inspect(signal)}")
      end
    end
  end
end
