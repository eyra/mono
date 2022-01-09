defmodule Systems.NextAction.OverviewPage do
  @moduledoc """
   The todo screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :todo

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias Systems.NextAction

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    model = %{
      id: user.id,
      presenter: Systems.NextAction.Presenter
    }

    {
      :ok,
      socket
      |> assign(model: model)
      |> observe_view_model()
      |> update_menus()
      |> refresh_next_actions()
    }
  end

  def refresh_next_actions(%{assigns: %{current_user: user}} = socket) do
    assign(
      socket,
      :next_actions,
      NextAction.Context.list_next_actions(url_resolver(socket), user)
    )
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    refresh_next_actions(socket)
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def render(assigns) do
    ~F"""
      <Workspace
        title={dgettext("eyra-ui", "todo.title")}
        menus={@menus}
      >
        <div :if={Enum.empty?(@vm.next_actions)} class="h-full">
          <div class="flex flex-col items-center w-full h-full">
            <div class="flex-grow"></div>
            <div class="flex-none">
              <img src="/images/illustrations/zero-todo.svg" id="zero-todos" alt="All done" />
            </div>
            <div class="flex-grow"></div>
          </div>
        </div>

        <ContentArea>
          <MarginY id={:page_top} />
          <div :if={!Enum.empty?(@vm.next_actions)} class="flex flex-col gap-6 sm:gap-10" id="next-actions">
            <NextAction.View :for={action <- @vm.next_actions} vm={action} />
          </div>
        </ContentArea>
      </Workspace>
    """
  end
end
