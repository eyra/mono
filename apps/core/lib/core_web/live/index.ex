defmodule CoreWeb.Index do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  import Core.Accounts
  alias EyraUI.Card.{PrimaryCTA, USP}
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Hero.HeroLarge
  alias EyraUI.Text.{Title1, Intro}
  alias EyraUI.Grid.{AbsoluteGrid}

  data(current_user, :any)
  data(current_user_profile, :any)
  data(path_provider, :any)

  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile = get_profile(user)

    socket =
      socket
      |> assign(current_user_profile: profile)

    {:ok, socket}
  end

  def cta_title(nil) do
    dgettext("eyra-link", "member.card.title")
  end

  def cta_title(current_user_profile) do
    dgettext("eyra-link", "member.profile.card.title", user: current_user_profile.displayname)
  end

  def render(assigns) do
    ~H"""
      <HeroLarge title={{ dgettext("eyra-link", "welcome.title") }}
            subtitle={{dgettext("eyra-link", "welcome.subtitle")}} />

      <ContentArea>
        <AbsoluteGrid>
          <div class="md:col-span-2">
            <Title1>
              {{ dgettext("eyra-link", "link.title") }}
            </Title1>
            <Intro>
              {{ dgettext("eyra-link", "link.message") }}
            </Intro>
          </div>
          <div>
            <div :if={{ @current_user != nil }}>
              <PrimaryCTA
                title={{ cta_title(@current_user_profile) }}
                button_label={{ dgettext("eyra-link", "dashboard-button") }}
                to={{ @path_provider.live_path(@socket, CoreWeb.Dashboard)}} />
            </div>
            <div :if={{ @current_user == nil }}>
              <PrimaryCTA title={{ dgettext("eyra-link", "signup.card.title") }}
                button_label={{ dgettext("eyra-link", "signup.card.button") }}
                to={{ @path_provider.live_path(@socket, CoreWeb.User.Signup) }} />
            </div>
          </div>
          <USP title={{ dgettext("eyra-link", "usp1.title") }} description={{ dgettext("eyra-link", "usp1.description") }} />
          <USP title={{ dgettext("eyra-link", "usp2.title") }} description={{ dgettext("eyra-link", "usp2.description") }} />
          <USP title={{ dgettext("eyra-link", "usp3.title") }} description={{ dgettext("eyra-link", "usp3.description") }} />
         </AbsoluteGrid>
      </ContentArea>
    """
  end
end
