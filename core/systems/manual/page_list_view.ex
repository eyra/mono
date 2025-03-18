defmodule Systems.Manual.PageListView do
  @moduledoc """
    Page List View for both Desktop and Mobile
  """
  use CoreWeb, :live_component

  import Systems.Manual.Html

  alias Systems.Manual

  @impl true
  def update(%{chapter: chapter, selected_page_id: selected_page_id}, socket) do
    {
      :ok,
      socket
      |> assign(
        chapter: chapter,
        selected_page_id: selected_page_id
      )
      |> update_pages()
      |> update_page_items()
      |> update_selected_page()
    }
  end

  def update_pages(%{assigns: %{chapter: %{pages: [_ | _] = pages}}} = socket) do
    socket |> assign(pages: pages |> Enum.sort_by(& &1.userflow_step.order))
  end

  def update_pages(socket) do
    socket |> assign(pages: [])
  end

  def update_page_items(%{assigns: %{pages: pages}} = socket) do
    page_items =
      pages
      |> Enum.with_index()
      |> Enum.map(&map_page_to_item/1)

    socket |> assign(page_items: page_items)
  end

  def update_selected_page(%{assigns: %{pages: []}} = socket) do
    socket |> assign(selected_page: nil, selected_page_id: nil)
  end

  def update_selected_page(
        %{assigns: %{pages: pages, selected_page_id: selected_page_id}} = socket
      ) do
    selected_page = Enum.find(pages, fn page -> page.id == selected_page_id end)
    socket |> assign(selected_page: selected_page)
  end

  def map_page_to_item({%Manual.PageModel{id: id, title: title}, index}) do
    %{
      id: id,
      title: title,
      number: index + 1
    }
  end

  def handle_event("select_page", %{"item" => page_id}, socket) do
    {
      :noreply,
      socket
      |> send_event(:parent, "select_page", %{page_id: page_id |> String.to_integer()})
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.page_list items={@page_items} selected_page_id={@selected_page_id} target={@myself} />
    </div>
    """
  end
end
