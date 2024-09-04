defmodule Systems.Observatory.Public do
  alias CoreWeb.Endpoint

  def subscribe(signal, key \\ []) do
    Endpoint.subscribe(topic_key(signal, key))
  end

  def dispatch(signal, key, data) do
    Endpoint.broadcast(
      topic_key(signal, key),
      "observation",
      {signal, data}
    )
  end

  def local_dispatch(signal, key, data) do
    Endpoint.local_broadcast(
      topic_key(signal, key),
      "observation",
      {signal, data}
    )
  end

  defp topic_key(signal, key) when is_atom(signal) and is_list(key) do
    key_str = Enum.map_join(key, ":", &to_string/1)

    "signal:#{to_string(signal)}:#{key_str}"
  end

  def observe(socket, subscriptions \\ []) do
    if Phoenix.LiveView.connected?(socket) do
      for {signal, key} <- subscriptions do
        __MODULE__.subscribe(signal, key)
      end
    end

    socket
  end

  def update_view_model(socket, page, model, presenter) do
    vm = get_view_model(socket, page, model, presenter)

    Phoenix.Component.assign(socket, vm: vm)
  end

  def get_view_model(_socket, page, _model, nil) do
    raise "No presenter available for #{page}"
  end

  def get_view_model(
        %{assigns: assigns} = _socket,
        page,
        model,
        presenter
      ) do
    apply(presenter, :view_model, [page, model, assigns])
  end
end
