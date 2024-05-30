defmodule Systems.Pool.LandingPage do
  @moduledoc """
   The pool details screen.
  """
  use Systems.Content.Composer, :live_workspace

  alias Frameworks.Pixel.Text
  alias Systems.Pool

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Pool.Public.get!(String.to_integer(id))
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_uri(socket), do: socket

  @impl true
  def handle_event("register", _, socket) do
    {
      :noreply,
      socket
      |> register()
    }
  end

  @impl true
  def handle_event("unregister", _, socket) do
    {
      :noreply,
      socket
      |> unregister()
    }
  end

  defp register(%{assigns: %{vm: %{pool: pool}, current_user: user}} = socket) do
    Pool.Public.link!(pool, user)
    socket
  end

  defp unregister(%{assigns: %{vm: %{pool: pool}, current_user: user}} = socket) do
    Pool.Public.unlink!(pool, user)
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={dgettext("eyra-pool", "landing.title")} menus={@menus} modal={@modal} popup={@popup} dialog={@dialog}>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= @vm.title %></Text.title2>
        <Text.body><%= @vm.description %></Text.body>

        <.spacing value="M" />
        <div class="flex flex-row gap-4">
          <%= for button <- @vm.buttons do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </Area.content>
    </.live_workspace>
    """
  end
end
