defmodule Systems.Crew.TaskPage do
  @moduledoc """
  The  page for an assigned task
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :survey

  alias EyraUI.Text.{Title1, Title3, BodyLarge}
  alias EyraUI.Button.PrimaryLiveViewButton
  alias EyraUI.Card.Highlight

  alias Systems.{
    Crew
  }

  data(task, :map)
  data(plugin, :any)
  data(plugin_info, :any)

  @impl true
  def get_authorization_context(%{"type" => type, "id" => id}, _session, _socket) do
    crew = Crew.Context.get_by_reference!(String.to_atom(type), id)
    Crew.Context.get!(crew.id)
  end

  @impl true
  def mount(%{"type" => type, "id" => id}, _session, %{assigns: %{current_user: user}} = socket) do
    crew = Crew.Context.get_by_reference!(String.to_atom(type), id)
    member = Crew.Context.get_member!(crew, user)
    task = Crew.Context.get_task(crew, member)

    plugin = load_plugin(task)
    plugin_info = plugin.info(task.id, socket)

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
    Crew.Context.start_task!(task)

    path = plugin.get_cta_path(task.id, plugin_info.call_to_action.target.value, socket)
    {:noreply, redirect(socket, external: path)}
  end

  def load_plugin(%{plugin: plugin}) do
    plugins()[plugin]
  end

  defp plugins, do: Application.fetch_env!(:core, :crew_task_plugins)

  defp grid_cols(1), do: "grid-cols-1 sm:grid-cols-1"
  defp grid_cols(2), do: "grid-cols-1 sm:grid-cols-2"
  defp grid_cols(_), do: "grid-cols-1 sm:grid-cols-3"

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ @plugin_info.hero_title }}
      menus={{ @menus }}
    >
      <ContentArea>
        <MarginY id={{:page_top}} />
        <div class="grid gap-6 sm:gap-8 {{ grid_cols(Enum.count(@plugin_info.highlights)) }}">
          <div :for={{ highlight <- @plugin_info.highlights }} class="bg-grey5 rounded">
            <Highlight title={{highlight.title}} text={{highlight.text}} />
          </div>
        </div>
        <Spacing value="L" />
        <Title1>{{@plugin_info.title}}</Title1>
        <Spacing value="M" />
        <Title3>{{@plugin_info.subtitle}}</Title3>
        <Spacing value="M" />
        <BodyLarge>{{@plugin_info.text}}</BodyLarge>
        <Spacing value="L" />
        <PrimaryLiveViewButton label={{ @plugin_info.call_to_action.label }} event="call-to-action" />
      </ContentArea>
    </Workspace>
    """
  end
end
