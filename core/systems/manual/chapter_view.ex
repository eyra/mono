defmodule Systems.Manual.ChapterView do
  @moduledoc """
    Chapter View divided into Desktop and Mobile views.
  """

  use CoreWeb, :live_component

  alias Systems.Userflow

  @impl true
  def update(%{chapter: chapter, user: user}, socket) do
    {
      :ok,
      socket
      |> assign(chapter: chapter, user: user)
      |> compose_child(:chapter_desktop)
      |> compose_child(:chapter_mobile)
      |> mark_visited()
    }
  end

  @impl true
  def compose(:chapter_desktop, %{chapter: chapter, user: user}) do
    %{
      module: Manual.ChapterDesktopView,
      params: %{chapter: chapter, user: user}
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

  defp mark_visited(%{assigns: %{chapter: %{userflow_step: userflow_step}, user: user}} = socket) do
    Userflow.Public.mark_visited(userflow_step, user)
    socket
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
