defmodule Systems.Zircon.CriteriaView do
  use Phoenix.LiveView
  use LiveNest, :embedded_live_view

  use Gettext, backend: CoreWeb.Gettext

  import Frameworks.Pixel.SidePanel, only: [side_panel: 1]
  import Frameworks.Builder.HTML, only: [library: 1]

  # alias Frameworks.Builder
  alias Frameworks.Pixel.Text
  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Margin

  @impl true
  def mount(
        :not_mounted_at_router,
        %{"tool" => tool, "title" => title, "content_flags" => content_flags, "user" => user},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        tool: tool,
        title: title,
        content_flags: content_flags,
        user: user
      )
      |> assign_library_items()
    }
  end

  defp assign_library_items(socket) do
    library_items = [
      # %Builder.LibraryItemModel{
      #   id: :population,
      #   type: :research_design_element,
      #   title: Element.Categories.population,
      #   tags: [
      #     Element.Templates.pico,
      #     Element.Templates.pic_o,
      #     Element.Templates.spider
      #   ],
      #   description: dgettext("eyra-zircon", "research_design_element.population.description")
      # },
      # %Builder.LibraryItemModel{
      #   id: :intervention,
      #   type: :research_design_element,
      #   title: Element.Categories.intervention,
      #   tags: [
      #     Element.Templates.pico,
      #     Element.Templates.spice
      #   ],
      #   description: dgettext("eyra-zircon", "research_design_element.intervention.description")
      # },
      # %Builder.LibraryItemModel{
      #   id: :comparison,
      #   type: :research_design_element,
      #   title: Element.Categories.comparison,
      #   tags: [
      #     Element.Templates.pico,
      #     Element.Templates.spice
      #   ],
      #   description: dgettext("eyra-zircon", "research_design_element.comparison.description")
      # },
      # %Builder.LibraryItemModel{
      #   id: :outcome,
      #   type: :research_design_element,
      #   title: Element.Categories.outcome,
      #   tags: [
      #     Element.Templates.pico,
      #     Element.Templates.picos,
      #     Element.Templates.spice
      #   ],
      #   description: dgettext("eyra-zircon", "research_design_element.outcome.description")
      # },
      # %Builder.LibraryItemModel{
      #   id: :phenomenon_of_interest,
      #   type: :research_design_element,
      #   title: Element.Categories.phenomenon_of_interest,
      #   tags: [
      #     Element.Templates.spider,
      #     Element.Templates.pic_o
      #   ],
      #   description: dgettext("eyra-zircon", "research_design_element.phenomenon_of_interest.description"),
      # },
      # %Builder.LibraryItemModel{
      #   id: :context,
      #   type: :research_design_element,
      #   title: Element.Categories.context,
      #   tags: [
      #     Element.Templates.pic_o,
      #     Element.Templates.spice
      #   ],
      #   description: dgettext("eyra-zircon", "research_design_element.context.description")
      # },
      # %Builder.LibraryItemModel{
      #   id: :setting,
      #   type: :research_design_element,
      #   title: Element.Categories.setting,
      #   tags: [
      #     Element.Templates.spice
      #   ],
      #   description: dgettext("eyra-zircon", "research_design_element.setting.description")
      # }
    ]

    assign(socket, library_items: library_items)
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
              items={Enum.map(@library_items, &Map.from_struct/1)}
            />
          </.side_panel>
        </div>
      </div>
    """
  end
end
