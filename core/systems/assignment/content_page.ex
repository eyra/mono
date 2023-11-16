defmodule Systems.Assignment.ContentPage do
  use Systems.Content.Page
  use Fabric.LiveView

  alias Systems.{
    Assignment,
    Crew
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Assignment.Public.get!(String.to_integer(id))
  end

  @impl true
  def mount(%{"id" => id, "tab" => initial_tab}, %{"locale" => locale}, socket) do
    model = Assignment.Public.get!(String.to_integer(id), Assignment.Model.preload_graph(:down))
    tabbar_id = "assignment_content/#{id}"

    {
      :ok,
      socket
      |> initialize(id, model, tabbar_id, initial_tab, locale)
      |> ensure_tester_role()
    }
  end

  @impl true
  def mount(params, session, socket) do
    mount(Map.put(params, "tab", nil), session, socket)
  end

  defp ensure_tester_role(%{assigns: %{current_user: user, model: %{crew: crew}}} = socket) do
    if Crew.Public.get_member(crew, user) == nil do
      Crew.Public.apply_member_with_role(crew, user, :tester)
    end

    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.content_page
      title={@vm.title}
      show_errors={@vm.show_errors}
      tabs={@vm.tabs}
      menus={@menus}
      actions={@actions}
      more_actions={@more_actions}
      initial_tab={@initial_tab}
      tabbar_id={@tabbar_id}
      tabbar_size={@tabbar_size}
      breakpoint={@breakpoint}
      popup={@popup}
      dialog={@dialog}
     />
    """
  end
end
