defmodule Systems.Promotion.Page do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Website.Component, :index
  alias Core.Accounts

  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Card
  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Hero

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> update_menus()
    }
  end

  def cta_title(nil) do
    dgettext("eyra-link", "member.card.title")
  end

  def cta_title(current_user) do
    dgettext("eyra-link", "member.profile.card.title", user: current_user.displayname)
  end

  @impl true
  def handle_event("menu-item-clicked", %{"action" => action}, socket) do
    # toggle menu
    {:noreply, push_redirect(socket, to: action)}
  end

  #  data(current_user, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.website user={@current_user} user_agent={Browser.Ua.to_ua(@socket)} menus={@menus}>
      <:hero>
        <Hero.large
          title={dgettext("eyra-link", "welcome.title")}
          subtitle={dgettext("eyra-link", "welcome.subtitle")}
        />
      </:hero>

      <Area.content>
        <Margin.y id={:page_top} />
        <Grid.absolute>
          <div class="md:col-span-2">
            <Text.title1>
              <%= dgettext("eyra-link", "link.title") %>
            </Text.title1>
            <Text.intro>
              <%= dgettext("eyra-link", "link.message") %>
            </Text.intro>
          </div>
          <div>
            <%= if @current_user do %>
              <Card.primary_cta
                title={cta_title(@current_user)}
                button_label={Accounts.start_page_title(@current_user)}
                to={Accounts.start_page_path(@current_user)}
              />
            <% else %>
              <Card.primary_cta
                title={dgettext("eyra-link", "signup.card.title")}
                button_label={dgettext("eyra-link", "signup.card.button")}
                to={Routes.live_path(@socket, CoreWeb.User.Signup)}
              />
            <% end %>
          </div>
          <Panel.usp
            title={dgettext("eyra-link", "usp1.title")}
            description={dgettext("eyra-link", "usp1.description")}
          />
          <Panel.usp
            title={dgettext("eyra-link", "usp2.title")}
            description={dgettext("eyra-link", "usp2.description")}
          />
          <Panel.usp
            title={dgettext("eyra-link", "usp3.title")}
            description={dgettext("eyra-link", "usp3.description")}
          />
        </Grid.absolute>
      </Area.content>
    </.website>
    """
  end
end
