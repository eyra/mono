defmodule Systems.Assignment.CallbackPage do
  @moduledoc """
  The redirect page to complete a task
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :survey

  alias EyraUI.Text.{Title1, Title3, BodyLarge}
  alias EyraUI.Button.PrimaryLiveViewButton

  alias Systems.{
    Assignment
  }

  data(task, :map)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Assignment.Context.get!(id, [:crew]).crew
  end

  @impl true
  def mount(%{"id" => id}, _session, %{assigns: %{current_user: user}} = socket) do
    assignment = Assignment.Context.get!(id, [:crew])
    task = Assignment.Context.complete_task(assignment, user)

    {
      :ok,
      socket
      |> assign(
        task: task,
        model: assignment
      )
      |> observe_view_model()
      |> update_menus()
    }
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_event("call-to-action", _params,
    %{
      assigns: %{
        model: model,
        vm: %{call_to_action: call_to_action}
      }
    } = socket
  ) do
    {:noreply, socket |> call_to_action.handle.(call_to_action, model)}
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ @vm.hero_title }}
        menus={{ @menus }}
      >
        <ContentArea>
          <MarginY id={{:page_top}} />
          <Title1>{{@vm.title}}</Title1>
          <Spacing value="M" />
          <div :if={{@task == nil }}>
            <Title3>{{ dgettext("eyra-crew", "task.expired.subtitle") }}</Title3>
            <Spacing value="M" />
            <BodyLarge>{{ dgettext("eyra-crew", "task.expired.text") }}</BodyLarge>
          </div>
          <div :if={{@task != nil }}>
            <Title3>{{ dgettext("eyra-crew", "task.completed.title") }}</Title3>
            <Spacing value="M" />
            <BodyLarge>{{ dgettext("eyra-crew", "task.completed.message.part1") }}</BodyLarge>
            <Spacing value="XS" />
            <BodyLarge>{{ dgettext("eyra-crew", "task.completed.message.part2") }}</BodyLarge>
          </div>
          <Spacing value="L" />
          <PrimaryLiveViewButton label={{ @vm.call_to_action.label }} event="call-to-action" />
        </ContentArea>
      </Workspace>
    """
  end
end
