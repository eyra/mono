defmodule Systems.Crew.TaskPage do
  @moduledoc """
  The  page for an assigned task
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :survey

  alias EyraUI.Text.{Title1, BodyLarge}
  alias EyraUI.Button.PrimaryLiveViewButton

  alias Systems.{
    Crew
  }

  data(task, :map)
  data(plugin, :any)
  data(plugin_info, :any)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    task = Crew.Context.get_task!(id)
    Crew.Context.get!(task.crew_id)
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    task = Crew.Context.get_task!(id)

    plugin = load_plugin(task)
    plugin_info = plugin.info(id, socket)

    {
      :ok,
      socket
      |> assign(
        task: task,
        plugin: plugin,
        plugin_info: plugin_info
      )
      |> update_menus()
    }
  end

  @impl true
  def handle_event("call-to-action", _params,
        %{assigns: %{task: task, plugin: plugin, plugin_info: plugin_info}} = socket
  ) do
    path = plugin.get_cta_path(task.id, plugin_info.call_to_action.target.value, socket)
    {:noreply, redirect(socket, external: path)}
  end

  def load_plugin(%{plugin: plugin}) do
    plugins()[plugin]
  end

  defp plugins, do: Application.fetch_env!(:core, :crew_task_plugins)

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ @plugin_info.hero_title }}
      menus={{ @menus }}
    >
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Title1>{{@plugin_info.title}}</Title1>
        <Spacing value="M" />
        <BodyLarge>{{@plugin_info.text}}</BodyLarge>
        <Spacing value="L" />
        <PrimaryLiveViewButton label={{ @plugin_info.call_to_action.label }} event="call-to-action" />
      </ContentArea>
    </Workspace>
    """
  end
end
