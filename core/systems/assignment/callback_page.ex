defmodule Systems.Assignment.CallbackPage do
  @moduledoc """
  The redirect page to complete a task
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :survey

  alias Frameworks.Pixel.Text.{Title1, Title3, BodyLarge}
  alias Frameworks.Pixel.Button.PrimaryLiveViewButton

  alias Systems.{
    Assignment
  }

  data(state, :atom)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Assignment.Context.get!(id, [:crew]).crew
  end

  @impl true
  def mount(%{"id" => id}, _session, %{assigns: %{current_user: user}} = socket) do
    %{crew: crew} = assignment = Assignment.Context.get!(id, [:crew])

    state =
      if Assignment.Context.complete_task(assignment, user) do
        :participant
      else
        if Core.Authorization.user_has_role?(user, crew, :tester) do
          :tester
        else
          :expired
        end
      end

    {
      :ok,
      socket
      |> assign(
        state: state,
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
          <div :if={{@state == :expired }}>
            <Title3>{{ dgettext("eyra-crew", "task.expired.subtitle") }}</Title3>
            <Spacing value="M" />
            <BodyLarge>{{ dgettext("eyra-crew", "task.expired.text") }}</BodyLarge>
          </div>
          <div :if={{@state == :tester }}>
            <Title3>{{ dgettext("eyra-crew", "tester.completed.subtitle") }}</Title3>
            <Spacing value="M" />
            <BodyLarge>{{ dgettext("eyra-crew", "tester.completed.text") }}</BodyLarge>
          </div>
          <div :if={{@state == :participant }}>
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
