defmodule Systems.Manual.ChapterView do
  @moduledoc """
    Chapter View divided into Desktop and Mobile views.
  """

  use CoreWeb, :live_component

  @impl true
  def update(%{chapter: chapter}, socket) do
    {
      :ok,
      socket
      |> assign(chapter: chapter)
      |> compose_child(:chapter_desktop)
      |> compose_child(:chapter_mobile)
    }
  end

  @impl true
  def compose(:chapter_desktop, %{chapter: chapter}) do
    %{
      module: Manual.ChapterDesktopView,
      params: %{chapter: chapter}
    }
  end

  @impl true
  def compose(:chapter_mobile, %{chapter: chapter}) do
    %{
      module: Manual.ChapterMobileView,
      params: %{chapter: chapter}
    }
  end

  def handle_event("back", _, socket) do
    {
      :noreply,
      socket |> send_event(:parent, "back")
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="hidden md:block">
        <.child name={:chapter_desktop} fabric={@fabric} />
      </div>
      <div class="block md:hidden">
        <.child name={:chapter_mobile} fabric={@fabric} />
      </div>
    </div>
    """
  end
end
