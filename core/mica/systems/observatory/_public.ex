defmodule Systems.Observatory.Public do
  use Core, :public
  alias CoreWeb.Endpoint
  alias Systems.Observatory.UpdateCollector

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
        subscribe(signal, key)
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
    presenter.view_model(page, model, assigns)
  end

  @doc """
  Collects an Observatory update to be dispatched later within a transaction.

  This is a convenience wrapper around UpdateCollector.collect/3.
  Use this when you want to defer LiveView updates until after a transaction commits.

  ## Examples

      Observatory.Public.collect_update({:page, MyPage}, [id], %{model: model})
      Observatory.Public.collect_update({:embedded_live_view, MyView}, [id, user_id], %{model: model})
  """
  def collect_update(target, args, message) do
    UpdateCollector.collect(target, args, message)
  end

  @doc """
  Commits all collected Observatory updates by dispatching them.

  This is a convenience wrapper around UpdateCollector.dispatch_all/0.
  Call this after your transaction commits to send all collected updates.

  ## Examples

      Multi.run(multi, :commit_observatory, fn _, _ ->
        Observatory.Public.commit_updates()
        {:ok, :committed}
      end)
  """
  def commit_updates do
    UpdateCollector.dispatch_all()
  end

  @doc """
  Clears all collected Observatory updates without dispatching them.

  This is useful in error cases where you want to abandon collected updates.

  ## Examples

      Observatory.Public.clear_updates()
  """
  def clear_updates do
    UpdateCollector.clear()
  end
end
