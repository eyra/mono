defmodule Systems.Pool.ParticipantsView do
  @moduledoc """
  Embedded LiveView for the Participants tab on the Pool Admin page.

  Read-only list of users who hold the `:participant` role on the pool.
  Search by email or display name; no admin actions yet (the
  Activate/Deactivate model is a separate design conversation).
  """
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.UserListItem
  alias Systems.Pool

  def dependencies(), do: [:pool_id]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{pool_id: pool_id}}) do
    Pool.Public.get!(pool_id)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket |> assign(query_string: "")}
  end

  @impl true
  def consume_event(
        %{name: :search_query, payload: %{query: query, query_string: query_string}},
        socket
      ) do
    {
      :stop,
      socket
      |> assign(query: query, query_string: query_string)
      |> update_view_model()
    }
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="pool-participants-view">
      <Area.content>
        <Margin.y id={:page_top} />

        <Text.title2>
          <%= @vm.title %> <span class="text-primary"><%= @vm.participant_count %></span>
        </Text.title2>
        <.spacing value="S" />

        <div class="w-full">
          <.live_component
            module={SearchBar}
            id={:pool_participants_search_bar}
            query_string={@query_string}
            placeholder={@vm.search_placeholder}
            debounce="200"
          />
        </div>
        <.spacing value="M" />

        <table class="w-full" data-testid="pool-participants-list">
          <%= for {person, index} <- Enum.with_index(@vm.people) do %>
            <.live_component
              module={UserListItem}
              id={"pool-participant-#{index}"}
              people_item={person}
            />
          <% end %>
        </table>
      </Area.content>
    </div>
    """
  end
end
