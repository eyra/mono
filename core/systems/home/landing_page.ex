defmodule Systems.Home.LandingPage do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Website.Component, :index
  alias CoreWeb.Layouts.Website.Component, as: Website

  alias Frameworks.Pixel.Text.{Title1, Intro}
  alias Frameworks.Pixel.Hero.HeroLarge

  data(current_user, :any)

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> update_menus()
    }
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
            title={dgettext("eyra-home", "hero.title")}
            subtitle={dgettext("eyra-home", "hero.subtitle")}
          />
        </#template>
        <ContentArea>
          <Title1>
            {dgettext("eyra-home", "title")}
          </Title1>
          <Intro>
            {dgettext("eyra-home", "intro")}
          </Intro>
        </ContentArea>
    </Website>
    """
  end
end
