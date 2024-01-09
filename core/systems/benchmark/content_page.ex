defmodule Systems.Benchmark.ContentPage do
  use CoreWeb, :live_view
  use Systems.Content.Page

  alias Systems.{
    Benchmark
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Benchmark.Public.get_tool!(id)
  end

  @impl true
  def mount(%{"id" => id} = params, %{"resolved_locale" => locale}, socket) do
    initial_tab = Map.get(params, "tab")

    model =
      Benchmark.Public.get_tool!(String.to_integer(id), Benchmark.ToolModel.preload_graph(:down))

    tabbar_id = "benchmark_content/#{id}"

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
