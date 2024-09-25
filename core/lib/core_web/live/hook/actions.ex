defmodule CoreWeb.Live.Hook.Actions do
  use Frameworks.Concept.LiveHook

  @impl true
  def on_mount(live_view_module, _params, _session, socket) do
    {
      :cont,
      socket
      |> update_actions(live_view_module)
      |> handle_action_click(live_view_module)
      |> handle_uri(live_view_module)
      |> handle_view_model_updated(live_view_module)
      |> handle_viewport_updated(live_view_module)
    }
  end

  defp handle_action_click(socket, live_view_module) do
    attach_hook(socket, :tabbar_handle_action_click, :handle_event, fn
      "action_click", %{"item" => action_id}, socket ->
        {:cont, socket |> handle_action_click(live_view_module, action_id)}

      _, _, socket ->
        {:cont, socket}
    end)
  end

  defp handle_uri(socket, live_view_module) do
    attach_hook(socket, :actions_handle_uri, :handle_params, fn _params, _uri, socket ->
      {:cont, socket |> update_actions(live_view_module)}
    end)
  end

  defp handle_view_model_updated(socket, live_view_module) do
    attach_hook(socket, :actions_handle_view_model_updated, :handle_info, fn
      :view_model_updated, socket ->
        {:cont, socket |> update_actions(live_view_module)}

      _, socket ->
        {:cont, socket}
    end)
  end

  defp handle_viewport_updated(socket, live_view_module) do
    attach_hook(socket, :actions_viewport_updated, :handle_info, fn
      :viewport_updated, socket ->
        {:cont, socket |> update_actions(live_view_module)}

      _, socket ->
        {:cont, socket}
    end)
  end

  def handle_action_click(
        %{assigns: %{vm: %{actions: actions}}} = socket,
        live_view_module,
        action_id
      )
      when is_binary(action_id) do
    action_id = String.to_existing_atom(action_id)
    action = Keyword.get(actions, action_id)

    socket
    |> action.handle_click.()
    |> update_view_model(live_view_module)
    |> update_actions(live_view_module)
  end

  def update_view_model(socket, live_view_module) do
    socket
    |> optional_apply(live_view_module, :update_view_model)
    |> optional_apply(live_view_module, :handle_update_view_model)
  end

  def update_actions(socket, live_view_module) do
    optional_apply(socket, live_view_module, :update_actions)
  end
end
