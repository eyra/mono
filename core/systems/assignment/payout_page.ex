defmodule Systems.Assignment.PayoutPage do
  @moduledoc """
  Pay-out modal/page for an assignment. Stub for commit A — the real UI lands
  in commit B (with tabs, list, decline-with-reason expansion, "Pay out all",
  etc.). Right now it just confirms the route exists and links back to the
  participants tab.
  """
  use CoreWeb, :live_view

  alias Systems.Assignment

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    assignment = Assignment.Public.get!(String.to_integer(id), Assignment.Model.preload_graph(:down))

    {:ok,
     socket
     |> assign(assignment: assignment)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-title3 font-title3">Pay out (placeholder)</h1>
      <p class="mt-4">Modal UI lands in the next commit.</p>
      <a class="text-primary underline" href={~p"/assignment/#{@assignment.id}/content"}>
        Back to assignment
      </a>
    </div>
    """
  end
end
