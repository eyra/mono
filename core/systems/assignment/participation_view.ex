defmodule Systems.Assignment.ParticipationView do
  @moduledoc """
  Terminal outcome page for a reviewed contribution: :accepted or :rejected.
  No retry affordance. A "back to home" plain-arrow button lets the participant
  navigate away.
  """
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Systems.Assignment
  alias Systems.Notify

  def dependencies, do: [:assignment_id, :current_user]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(
        :not_mounted_at_router,
        _session,
        %{assigns: %{assignment_id: assignment_id, current_user: user}} = socket
      ) do
    # Participant has landed on their outcome page → tell Notify the outcome
    # messages for this participation have been seen.
    mark_outcome_seen(assignment_id, user)

    {:ok, socket}
  end

  defp mark_outcome_seen(assignment_id, user) do
    case Assignment.Public.get_participation(%Assignment.Model{id: assignment_id}, user) do
      %Assignment.ParticipationModel{id: participation_id} ->
        Notify.Public.mark_seen(user, correlation_id: "participation:#{participation_id}")

      _ ->
        :ok
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full h-full py-10" data-testid="participation-view">
      <div class="flex-grow" />
      <Area.sheet>
        <div class="flex flex-col gap-8 items-center text-center">
          <div data-testid={"participation-#{@vm.outcome}"} class="flex flex-col gap-6 items-center">
            <Text.title2 margin=""><%= @vm.title %></Text.title2>
            <div class="flex flex-col gap-2 items-center">
              <Text.body align="text-center"><%= Phoenix.HTML.raw(@vm.body) %></Text.body>
              <div :if={@vm.reason} class="italic" data-testid="participation-reason">
                <Text.body align="text-center">&ldquo;<%= @vm.reason %>&rdquo;</Text.body>
              </div>
            </div>
          </div>
          <div class="flex flex-row justify-center" data-testid="participation-buttons">
            <Button.dynamic {@vm.home_button} testid="participation-home-button" />
          </div>
        </div>
      </Area.sheet>
      <div class="flex-grow" />
    </div>
    """
  end
end
