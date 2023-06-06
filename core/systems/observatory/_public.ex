defmodule Systems.Observatory.Public do
  alias Systems.Director
  alias CoreWeb.Endpoint

  import CoreWeb.UrlResolver, only: [url_resolver: 1]

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

  def update_view_model(%{assigns: %{model: %{presenter: presenter}}} = socket, model_or_id, page) do
    update_view_model(socket, presenter, model_or_id, page)
  end

  def update_view_model(%{assigns: %{model: model}} = socket, model_or_id, page) do
    update_view_model(socket, Director.presenter(model), model_or_id, page)
  end

  defp update_view_model(socket, presenter, model_or_id, page) do
    vm =
      presenter
      |> get_view_model(socket, model_or_id, page, url_resolver(socket))

    socket
    |> Phoenix.Component.assign(vm: vm)
  end

  defp get_view_model(
         presenter,
         %{assigns: assigns} = _socket,
         model_or_id,
         page,
         url_resolver
       ) do
    presenter
    |> apply(:view_model, [model_or_id, page, assigns, url_resolver])
  end

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__), only: [observe: 2]

      import CoreWeb.Gettext
      alias Systems.Observatory.Public

      # data(vm, :map)

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
          |> Public.update_view_model(model, __MODULE__)
          |> handle_view_model_updated()
          |> put_updated_info_flash()
        }
      end

      def observe_view_model(%{assigns: %{model: %{id: id}}} = socket) do
        socket
        |> Public.observe([{__MODULE__, [id]}])
        |> Public.update_view_model(id, __MODULE__)
      end

      def update_view_model(%{assigns: %{model: %{id: id}}} = socket) do
        socket
        |> Public.update_view_model(id, __MODULE__)
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
