defmodule Systems.Crew.TaskPage do
  @moduledoc """
  The  page for an assigned task
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :survey

  alias EyraUI.Text.{Title1, Title3, BodyLarge}
  alias EyraUI.Card.Highlight

  alias CoreWeb.UI.Navigation.ButtonBar

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
        crew: crew,
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

  @impl true
  def handle_event("withdraw", _params,
        %{assigns: %{crew: crew, task: task, plugin: plugin, plugin_info: plugin_info, current_user: user}} = socket
  ) do

    path = plugin.get_cta_path(task.id, plugin_info.withdraw_redirect.target.value, socket)

    Crew.Context.withdraw_member(crew, user)

    {:noreply, redirect(socket, external: path)}
  end

  def load_plugin(%{plugin: plugin}) do
    plugins()[plugin]
  end

  defp plugins, do: Application.fetch_env!(:core, :crew_task_plugins)

  defp grid_cols(1), do: "grid-cols-1 sm:grid-cols-1"
  defp grid_cols(2), do: "grid-cols-1 sm:grid-cols-2"
  defp grid_cols(_), do: "grid-cols-1 sm:grid-cols-3"

  defp action_map(%{plugin_info: plugin_info}) do
    %{
      call_to_action: %{
        action: %{type: :send, event: "call-to-action"},
        face: %{
          type: :primary,
          label: plugin_info.call_to_action.label
        }
      },
      withdraw: %{
        action: %{type: :send, event: "withdraw"},
        face: %{
          type: :secondary,
          label: dgettext("eyra-crew", "withdraw.button"),
          text_color: "text-delete",
          border_color: "border-delete"
        }
      },
    }
  end

  defp create_actions(%{task: %{status: status}} = assigns) do
    create_actions(action_map(assigns), status == :completed)
  end

  defp create_actions(%{call_to_action: call_to_action, withdraw: withdraw}, false), do: [call_to_action, withdraw]
  defp create_actions(%{call_to_action: call_to_action}, true), do: [call_to_action]

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

        <MarginY id={{:button_bar_top}} />
        <ButtonBar buttons={{create_actions(assigns)}} />
      </ContentArea>
    </Workspace>
    """
  end
end
