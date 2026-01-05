defmodule Systems.Assignment.FinishedView do
  use CoreWeb, :embedded_live_view
  use CoreWeb, :verified_routes

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  alias Systems.Assignment

  def dependencies(), do: [:assignment_id, :current_user]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("retry", _, socket) do
    {:noreply, socket |> publish_event(:retry)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex flex-row w-full h-full" data-testid="finished-view">
        <div class="flex-grow" />
        <div class="flex flex-col gap-4 sm:gap-8 items-center w-full h-full px-6">
          <div class="flex-grow" />
          <Text.title1 margin="" data-testid="finished-title"><%= @vm.title %></Text.title1>
          <div>
            <Text.body_large align="text-center" data-testid="finished-body">
              <%= @vm.body %>
            </Text.body_large>
            <div :if={@vm.illustration} class="flex flex-col items-center w-full pt-4" data-testid="finished-illustration">
              <img class="block w-[220px] h-[220px] object-cover" src={@vm.illustration} id="zero-todos" alt="All tasks done">
            </div>
          </div>

          <div class="flex flex-row items-center gap-6" data-testid="finished-buttons">
            <Button.dynamic :if={@vm.back_button} {@vm.back_button} data-testid="back-button" />
            <Button.dynamic :if={@vm.continue_button} {@vm.continue_button} data-testid="continue-button" />
          </div>
          <div class="flex-grow" />
        </div>
        <div class="flex-grow" />
      </div>
    """
  end
end
