defmodule Systems.Assignment.LandingPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Composer

  alias Systems.Assignment

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    %{crew: crew} = Assignment.Public.get!(String.to_integer(id), [:crew])
    crew
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Assignment.Public.get!(id, [:info])
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
    }
  end

  @impl true
  def handle_event("continue", _params, %{assigns: %{id: id}} = socket) do
    {:noreply, socket |> push_navigate(to: ~p"/assignment/#{id}/join")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div class="flex flex-col items-center justify-center w-full h-full px-6 py-12">
        <div class="max-w-2xl w-full space-y-6">
          <Text.title1><%= @vm.title %></Text.title1>
          <Text.body_large><%= @vm.description %></Text.body_large>
          <div class="pt-4">
            <Button.primary_live_view label={@vm.continue_button} event="continue" />
          </div>
        </div>
      </div>
    </.stripped>
    """
  end
end
