defmodule CoreWeb.Todo do
  @moduledoc """
   The todo screen.
  """
  use CoreWeb, :live_view

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias EyraUI.Container.ContentArea
  alias Core.NextActions
  alias Core.NextActions.Live.NextAction

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    next_actions = NextActions.list_next_actions(url_resolver(socket), user)

    socket =
      socket
      |> assign(:next_actions, next_actions)
      |> assign(:has_next_actions?, not Enum.empty?(next_actions))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("eyra-ui", "todo.title") }}
        user={{@current_user}}
        user_agent={{ Browser.Ua.to_ua(@socket) }}
        active_item={{ :todo }}
      >
        <ContentArea>
          <div :if={{not @has_next_actions?}}>
            All tasks done. Great job!
          </div>
          <div :if={{@has_next_actions?}}>
            <NextAction :for={{action <- @next_actions}}
            title={{action.title}} description={{action.description}} cta={{action.cta}} url={{action.url}} />
          </div>
        </ContentArea>
      </Workspace>
    """
  end
end
