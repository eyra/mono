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

  def update_view_model(socket, model, page, presenter) do
    vm =
      presenter
      |> get_view_model(socket, model, page)

    socket
    |> Phoenix.Component.assign(vm: vm)
  end

  defp get_view_model(
         presenter,
         %{assigns: assigns} = _socket,
         model,
         page
       ) do
    presenter
    |> apply(:view_model, [model, page, assigns])
  end

  defmacro __using__(_opts \\ []) do
    quote do
      import CoreWeb.Gettext
      alias Systems.Observatory.Public

      @presenter Frameworks.Concept.System.presenter(__MODULE__)

      def handle_info(%{auto_save: status}, socket) do
        {
          :noreply,
          socket |> assign(auto_save_status: status)
        }
      end

      def handle_info(%{topic: _topic, payload: {signal, %{model: model}}} = payload, socket) do
        {
          :noreply,
          socket
          |> Public.update_view_model(model, __MODULE__, @presenter)
          |> handle_view_model_updated()
          |> put_updated_info_flash()
        }
      end

      def observe_view_model(%{assigns: %{model: %{id: id} = model}} = socket) do
        socket
        |> Public.observe([{__MODULE__, [id]}])
        |> Public.update_view_model(model, __MODULE__, @presenter)
      end

      def update_view_model(%{assigns: %{model: %{id: id} = model}} = socket) do
        socket
        |> Public.update_view_model(model, __MODULE__, @presenter)
      end

      def handle_view_model_updated(socket) do
        IO.puts("No handle_observation/1 implemented")
        socket
      end

      def put_updated_info_flash(%{assigns: %{auto_save_status: :active}} = socket) do
        socket
      end

      def put_updated_info_flash(socket) do
        socket |> Frameworks.Pixel.Flash.put_info("Updated")
      end
    end
  end
end
