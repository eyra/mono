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

    socket
    |> Phoenix.Component.assign(vm: vm)
  end

  defp get_view_model(
         %{assigns: assigns} = _socket,
         page,
         model,
         presenter
       ) do
    apply(presenter, :view_model, [page, model, assigns])
  end

  defmacro __using__(_opts \\ []) do
    quote do
      import CoreWeb.Gettext
      alias Systems.Observatory.Public

      require Logger

      @presenter Frameworks.Concept.System.presenter(__MODULE__)

      def handle_info(%{auto_save: status}, socket) do
        {
          :noreply,
          socket |> assign(auto_save_status: status)
        }
      end

      def handle_info(
            %{topic: _topic, payload: {signal, %{model: model, from_pid: from_pid}}} = payload,
            socket
          ) do
        {
          :noreply,
          socket
          |> assign(model: model)
          |> update_view_model()
          |> handle_view_model_updated()
          |> put_info_flash(from_pid)
        }
      end

      def handle_info(%{topic: topic, payload: {signal, %{model: model}}} = payload, socket) do
        Logger.warn("Unknown sender, no from_pid provided")
        handle_info(%{topic: topic, payload: {signal, %{model: model, from_pid: nil}}}, socket)
      end

      def observe_view_model(%{assigns: %{model: %{id: id} = model}} = socket) do
        socket
        |> Public.observe([{__MODULE__, [id]}])
        |> Public.update_view_model(__MODULE__, model, @presenter)
      end

      def observe_event(%{assigns: %{model: %{id: id} = model}} = socket) do
        socket
        |> Public.observe([{__MODULE__, [id]}])
        |> Public.update_view_model(__MODULE__, model, @presenter)
      end

      def update_view_model(%{assigns: %{model: model}} = socket) do
        socket
        |> Public.update_view_model(__MODULE__, model, @presenter)
      end

      def handle_view_model_updated(socket) do
        Logger.warn("handle_view_model_updated/1 not implemented")
        socket
      end

      defoverridable handle_view_model_updated: 1

      def put_info_flash(socket, from_pid) do
        if from_pid == self() do
          socket |> put_saved_info_flash()
        else
          socket |> put_updated_info_flash()
        end
      end

      def put_updated_info_flash(socket) do
        socket |> Frameworks.Pixel.Flash.put_info("Updated")
      end

      def put_saved_info_flash(socket) do
        socket |> Frameworks.Pixel.Flash.put_info("Saved")
      end
    end
  end
end
