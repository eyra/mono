defmodule Systems.Home.StudiesPage do
  use Systems.Content.Composer, :live_website

  alias Systems.Home
  alias Systems.Pool
  alias Frameworks.Pixel.Hero
  alias Frameworks.Pixel.Breadcrumbs

  @impl true
  def get_model(_params, _session, _socket) do
    Systems.Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    socket = socket |> compose_child(:studies_view)

    if participant?(user) do
      {:ok, socket}
    else
      {:ok, socket |> push_navigate(to: ~p"/")}
    end
  end

  defp participant?(%Systems.Account.User{} = user), do: Pool.Public.participant?(:panl, user)
  defp participant?(_), do: false

  @impl true
  def compose(:studies_view, %{vm: %{items: items, years: years}}) do
    %{
      module: Home.StudiesView,
      params: %{
        items: items,
        years: years
      }
    }
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket |> update_child(:studies_view)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_website include_right_sidepadding?={@vm.include_right_sidepadding?} user={@current_user} user_agent={Browser.Ua.to_ua(@socket)} menus={@menus} modal={@modal} socket={@socket}>
      <:hero>
        <Hero.dynamic {@vm.hero} />
      </:hero>
      <div class="bg-grey6 min-h-full">
        <div class="py-4 border-b border-grey4">
          <Area.content>
            <.live_component module={Breadcrumbs} id={:studies_breadcrumbs} elements={@vm.breadcrumbs} />
          </Area.content>
        </div>
        <Area.content class="py-6 lg:py-8">
          <.child name={:studies_view} fabric={@fabric} />
        </Area.content>
      </div>
    </.live_website>
    """
  end
end
