defmodule Systems.Graphite.LeaderboardView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Align

  alias Systems.{
    Graphite
  }

  import Graphite.Leaderboard.CategoryView

  @impl true
  def update(
        %{open: open, active_item_id: active_item_id, selector_id: :leaderboard_category},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(active_category_name: active_item_id, open: open)
      |> update_category()
    }
  end

  @impl true
  def update(%{open: open, id: id, categories: categories}, socket) do
    first_category = List.first(categories)

    {
      :ok,
      socket
      |> assign(
        id: id,
        categories: categories,
        active_category_name: first_category.name,
        open: open
      )
      |> prepare_selector()
      |> update_category()
    }
  end

  defp prepare_selector(
         %{assigns: %{id: id, categories: categories, active_category_name: active_category_name}} =
           socket
       ) do
    items = Enum.map(categories, &to_selector_item(&1, active_category_name))

    selector = %{
      id: :leaderboard_category,
      module: Selector,
      items: items,
      type: :segmented,
      parent: %{type: __MODULE__, id: id}
    }

    assign(socket, selector: selector)
  end

  defp update_category(
         %{assigns: %{categories: categories, active_category_name: active_category_name}} =
           socket
       ) do
    active_category = categories |> Enum.find(&(&1.name == active_category_name))
    assign(socket, active_category: active_category)
  end

  defp to_selector_item(%{name: name}, active_category) do
    %{
      id: name,
      value: String.capitalize(String.replace(name, "_", " ")),
      active: name == active_category
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Align.horizontal_center>
        <.live_component {@selector} />
      </Align.horizontal_center>
      <.spacing value="M" />
      <%= if @active_category do %>
        <.category name={@active_category.name} scores={@active_category.scores} open={@open} />
      <% end %>
    </div>
    """
  end
end
