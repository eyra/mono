defmodule CoreWeb.Todo do
  @moduledoc """
   The todo screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :todo

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias EyraUI.Container.ContentArea
  alias Core.NextActions
  alias Core.NextActions.Live.NextAction

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    next_actions = NextActions.list_next_actions(url_resolver(socket), user)

    socket =
      socket
      |> update_menus()
      |> assign(:next_actions, next_actions)
      |> assign(:has_next_actions?, not Enum.empty?(next_actions))

    {:ok, socket}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("eyra-ui", "todo.title") }}
        menus={{ @menus }}
      >
        <div :if={{not @has_next_actions?}} class="h-full">
          <div class="flex flex-col items-center w-full h-full">
            <div class="flex-grow"></div>
            <div class="flex-none">
              <img src="/images/illustrations/zero-todo.svg" />
            </div>
            <div class="flex-grow"></div>
          </div>
        </div>

        <ContentArea>
          <div :if={{@has_next_actions?}} class="flex flex-col gap-6 sm:gap-10">
            <NextAction :for={{action <- @next_actions}} vm={{ action }} />
          </div>
        </ContentArea>
      </Workspace>
    """
  end
end
