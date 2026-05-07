defmodule Systems.Observatory.LiveHook do
  use Frameworks.Concept.LiveHook

  require Logger

  @impl true
  def mount(live_view_module, _params, session, socket) do
    has_previous_vm? = Map.has_key?(socket.assigns, :vm)

    {
      :cont,
      socket
      |> assign(session: session)
      |> observe_view_model(live_view_module)
      |> maybe_notify_view_model_updated(live_view_module, has_previous_vm?)
      |> maybe_attach_hooks(live_view_module, has_previous_vm?)
    }
  end

  defp observe_view_model(socket, live_view_module) do
    live_view_module.observe_view_model(socket)
  end

  defp maybe_notify_view_model_updated(socket, live_view_module, true = _has_previous_vm?) do
    optional_apply(socket, live_view_module, :handle_view_model_updated)
  end

  defp maybe_notify_view_model_updated(socket, _live_view_module, false = _has_previous_vm?) do
    socket
  end

  defp maybe_attach_hooks(socket, live_view_module, false = _has_previous_vm?) do
    socket
    |> attach_auto_save_status_hook(live_view_module)
    |> attach_model_update_hook(live_view_module)
  end

  defp maybe_attach_hooks(socket, _live_view_module, true = _has_previous_vm?) do
    socket
  end

  defp attach_auto_save_status_hook(socket, _live_view_module) do
    attach_hook(socket, :handle_auto_save_status, :handle_info, fn
      %{auto_save: status}, socket ->
        {:cont, socket |> assign(auto_save_status: status)}

      _, socket ->
        {:cont, socket}
    end)
  end

  defp attach_model_update_hook(socket, live_view_module) do
    attach_hook(socket, :handle_model_update, :handle_info, fn
      %{topic: _topic, payload: {_signal, %{model: model, from_pid: from_pid}}}, socket ->
        {:cont, socket |> handle_model_update(live_view_module, model, from_pid)}

      %{topic: _topic, payload: {_signal, %{model: model}}}, socket ->
        Logger.warning("Unknown sender, no from_pid provided")
        {:cont, socket |> handle_model_update(live_view_module, model, nil)}

      _, socket ->
        {:cont, socket}
    end)
  end

  defp handle_model_update(socket, live_view_module, model, from_pid) do
    # Send message to other Live Hooks
    send(self(), :view_model_updated)

    socket
    |> assign(model: model)
    |> optional_apply(live_view_module, :update_view_model)
    |> optional_apply(live_view_module, :handle_view_model_updated)
    |> optional_apply(live_view_module, :put_info_flash, [from_pid])
  end
end
