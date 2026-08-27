defmodule Systems.Pool.MarketplacePage do
  @moduledoc false
  use Systems.Content.Composer, :live_website

  alias Frameworks.Pixel.Breadcrumbs
  alias Frameworks.Pixel.Hero
  alias Systems.Pool

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Pool.Public.get!(String.to_integer(id))
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: user, model: pool}} = socket) do
    if Pool.Public.participant?(pool, user) do
      {:ok, compose_child(socket, :marketplace_view)}
    else
      {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl true
  def compose(:marketplace_view, %{vm: %{pool: pool, items: items, years: years}}) do
    %{
      module: Pool.MarketplaceView,
      params: %{
        pool: pool,
        items: items,
        years: years
      }
    }
  end

  @impl true
  def handle_view_model_updated(socket) do
    update_child(socket, :marketplace_view)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_website include_right_sidepadding?={@vm.include_right_sidepadding?} user={@current_user} user_agent={Browser.Ua.to_ua(@socket)} menus={@menus} modal={@modal} socket={@socket}>
      <:hero>
        <Hero.dynamic {@vm.hero} />
      </:hero>
      <div class="min-h-full">
        <div class="py-4 border-b border-grey4">
          <Area.content>
            <.live_component module={Breadcrumbs} id={:marketplace_breadcrumbs} elements={@vm.breadcrumbs} />
          </Area.content>
        </div>
        <Area.content class="py-6 lg:py-8">
          <.child name={:marketplace_view} fabric={@fabric} />
        </Area.content>
      </div>
    </.live_website>
    """
  end
end
