defmodule Systems.Promotion.Page do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Website.Component, :index
  alias CoreWeb.Layouts.Website.Component, as: Website
  alias Core.Accounts
  alias CoreWeb.Router.Helpers, as: Routes

  alias Frameworks.Pixel.Card.PrimaryCTA
  alias Frameworks.Pixel.Panel.USP
  alias Frameworks.Pixel.Text.{Title1, Intro}
  alias Frameworks.Pixel.Grid.{AbsoluteGrid}
  alias Frameworks.Pixel.Hero.HeroLarge

  data(current_user, :any)

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

  def render(assigns) do
    ~F"""
      <Website
        user={@current_user}
        user_agent={Browser.Ua.to_ua(@socket)}
        menus={@menus}
      >
        <#template slot="hero">
          <HeroLarge
            title={dgettext("eyra-link", "welcome.title")}
            subtitle={dgettext("eyra-link", "welcome.subtitle")}
          />
        </#template>

        <ContentArea>
          <MarginY id={:page_top} />
          <AbsoluteGrid>
            <div class="md:col-span-2">
              <Title1>
                {dgettext("eyra-link", "link.title")}
              </Title1>
              <Intro>
                {dgettext("eyra-link", "link.message")}
              </Intro>
            </div>
            <div>
              <div :if={@current_user != nil}>
                <PrimaryCTA
                  title={cta_title(@current_user)}
                  button_label={Accounts.start_page_title(@current_user)}
                  to={Routes.live_path(@socket, Accounts.start_page_target(@current_user))} />
              </div>
              <div :if={@current_user == nil}>
                <PrimaryCTA title={dgettext("eyra-link", "signup.card.title")}
                  button_label={dgettext("eyra-link", "signup.card.button")}
                  to={Routes.live_path(@socket, CoreWeb.User.Signup)} />
              </div>
            </div>
            <USP title={dgettext("eyra-link", "usp1.title")} description={dgettext("eyra-link", "usp1.description")} />
            <USP title={dgettext("eyra-link", "usp2.title")} description={dgettext("eyra-link", "usp2.description")} />
            <USP title={dgettext("eyra-link", "usp3.title")} description={dgettext("eyra-link", "usp3.description")} />
          </AbsoluteGrid>
        </ContentArea>
    </Website>
    """
  end
end
