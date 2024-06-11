defmodule Systems.Home.NextBestActionView do
  use CoreWeb, :live_component

  alias Systems.NextAction

  @impl true
  def update(%{next_best_action: next_best_action}, %{assigns: %{}} = socket) do
    {:ok, socket |> assign(next_best_action: next_best_action)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <NextAction.View.highlight {@next_best_action} />
      </div>
    """
  end
end
