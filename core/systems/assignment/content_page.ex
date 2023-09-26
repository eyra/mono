defmodule Systems.Assignment.ContentPage do
  use Systems.Content.Page

  alias Systems.{
    Assignment
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
      socket |> initialize(id, model, tabbar_id, initial_tab, locale)
    }
  end

  @impl true
  def mount(params, session, socket) do
    mount(Map.put(params, "tab", nil), session, socket)
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
