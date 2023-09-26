defmodule Systems.NextAction.OverviewPage do
  @moduledoc """
   The todo screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :todo
  use Systems.Observatory.Public

  import CoreWeb.Layouts.Workspace.Component

  alias Systems.{
    NextAction
  }

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    {
      :ok,
      socket
      |> assign(model: user)
      |> observe_view_model()
      |> update_menus()
      |> refresh_next_actions()
    }
  end

  def refresh_next_actions(%{assigns: %{current_user: user}} = socket) do
    assign(
      socket,
      :next_actions,
      NextAction.Public.list_next_actions(user)
    )
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    refresh_next_actions(socket)
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-ui", "todo.title")} menus={@menus}>
      <%= if Enum.empty?(@vm.next_actions) do %>
        <div class="h-full">
          <div class="flex flex-col items-center w-full h-full">
            <div class="flex-grow" />
            <div class="flex-none">
              <img src="/images/illustrations/zero-todo.svg" id="zero-todos" alt="All done">
            </div>
            <div class="flex-grow" />
          </div>
        </div>
      <% else %>
        <Area.content>
          <Margin.y id={:page_top} />
          <div class="flex flex-col gap-6 sm:gap-10" id="next-actions">
            <%= for action <- @vm.next_actions do %>
              <NextAction.View.normal {action} />
            <% end %>
          </div>
        </Area.content>
      <% end %>
    </.workspace>
    """
  end
end
