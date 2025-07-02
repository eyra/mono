defmodule Systems.Zircon.Screening.CriteriaView do
  use Phoenix.LiveView
  use LiveNest, :embedded_live_view

  use Gettext, backend: CoreWeb.Gettext

  import Frameworks.Pixel.SidePanel, only: [side_panel: 1]
  import Frameworks.Builder.HTML, only: [library: 1]

  alias Frameworks.Pixel.Text
  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Margin

  @impl true
  def mount(
        :not_mounted_at_router,
        %{"tool" => tool, "title" => title, "builder" => builder, "user" => user},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        tool: tool,
        title: title,
        builder: builder,
        user: user
      )
      |> assign_view_model()
    }
  end

  defp assign_view_model(%{assigns: %{tool: tool, builder: builder} = assigns} = socket) do
    vm = builder.view_model(tool, assigns)
    socket |> assign(vm: vm)
  end

  @impl true
  def handle_event("add", %{"item" => _item}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div id={:screening_criteria_builder} class="flex flex-row">
        <div class="flex-grow">
          <Area.content>
            <Margin.y id={:page_top} />
            <Text.title2><%= @title %></Text.title2>
          </Area.content>
        </div>
        <div class="flex-shrink-0 w-side-panel">
          <.side_panel id={:screening_criteria_library} parent={:screening_criteria_builder}>
            <Margin.y id={:page_top} />
            <.library
              title={dgettext("eyra-zircon", "screening.criteria.library.title")}
              description={dgettext("eyra-zircon", "screening.criteria.library.description")}
              items={Enum.map(@vm.library_items, &Map.from_struct/1)}
            />
          </.side_panel>
        </div>
      </div>
    """
  end
end
