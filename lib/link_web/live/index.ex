defmodule LinkWeb.Index do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  import Link.Users
  alias EyraUI.{Hero, PrimaryCTA, USPCard}

  data current_user, :any
  data current_user_profile, :any

  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile = get_profile(user)
    socket = assign_current_user(socket, session, user, profile)
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
      <Hero title={{ dgettext("eyra-link", "welcome.title") }}
            subtitle={{dgettext("eyra-link", "welcome.subtitle")}} />

      <div class="flex h-full w-full">
        <div class="flex-grow ml-6 mr-6 lg:ml-14 lg:mr-14">
          <div class="grid md:grid-cols-3 gap-8">
            <div class="md:col-span-2 mt-9 lg:mt-24">
              <div class="text-title3 font-title3 lg:text-title1 lg:font-title1 mb-7 lg:mb-9">
                {{ dgettext("eyra-link", "link.title") }}
              </div>
              <div class="text-intro lg:text-introdesktop font-intro lg:mb-9">
                {{ dgettext("eyra-link", "link.message") }}
              </div>
            </div>
            <div class="mt-0 md:mt-9 lg:mt-24">
              <div :if={{ @current_user != nil }}>
                <PrimaryCTA
                  title={{ cta_title(@current_user_profile) }}
                  button_label={{ dgettext("eyra-link", "dashboard-button") }}
                  to={{Routes.dashboard_path(@socket, :index)}} />
              </div>
              <div :if={{ @current_user == nil }}>
                <PrimaryCTA title={{ dgettext("eyra-link", "signup.card.title") }}
                  button_label={{ dgettext("eyra-link", "signup.card.button") }}
                  to={{ Routes.pow_session_path(@socket, :new) }} />
              </div>
            </div>
            <div>
              <USPCard title={{ dgettext("eyra-link", "usp1.title") }} description={{ dgettext("eyra-link", "usp1.description") }} />
            </div>
            <div>
              <USPCard title={{ dgettext("eyra-link", "usp2.title") }} description={{ dgettext("eyra-link", "usp2.description") }} />
            </div>
            <div>
              <USPCard title={{ dgettext("eyra-link", "usp3.title") }} description={{ dgettext("eyra-link", "usp3.description") }} />
            </div>
         </div>
      </div>
      <div class="flex-wrap flex-shrink-0 w-0 lg:w-sidebar">
      </div>
    </div>
    """
  end
end
