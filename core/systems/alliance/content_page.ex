defmodule Systems.Alliance.ContentPage do
  use CoreWeb, :live_view
  use Systems.Content.Page

  alias Systems.{
    Alliance
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Alliance.Public.get_tool!(id)
  end

  @impl true
  def mount(%{"id" => id, "tab" => initial_tab}, %{"locale" => locale}, socket) do
    model = Alliance.Public.get_tool!(String.to_integer(id))
    tabbar_id = "alliance_content/#{id}"

    {
      :ok,
      socket |> initialize(id, model, tabbar_id, initial_tab, locale)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.content_page
      title={@vm.title}
      menus={@menus}
      tabs={@vm.tabs}
      actions={@actions}
      more_actions={@more_actions}
      initial_tab={@initial_tab}
      tabbar_id={@tabbar_id}
      tabbar_size={@tabbar_size}
      breakpoint={@breakpoint}
      popup={@popup}
      dialog={@dialog}
      show_errors={@show_errors}
     />
    """
  end
end
