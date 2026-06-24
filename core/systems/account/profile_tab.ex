defmodule Systems.Account.ProfileTab do
  @moduledoc """
  Profile tab implementation.
  This tab is always visible for all users.
  """
  @behaviour Systems.Account.Page.Tab

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account

  @impl true
  def key, do: :profile

  @impl true
  def visible?(_user), do: true

  @impl true
  def build(_user, live_context) do
    profile_context =
      LiveContext.extend(live_context, %{
        show_signout_button: true,
        show_email: true,
        show_top_margin: true
      })

    element =
      CoreWeb.Live.Element.prepare_live_view(
        :profile_view,
        Account.ProfileView,
        live_context: profile_context
      )

    %{
      id: :profile,
      title: dgettext("eyra-account", "profile.tab.profile.title"),
      type: :fullpage,
      element: element,
      ready?: true
    }
  end

  def build_live_context(user) do
    LiveContext.new(%{user_id: user.id})
  end
end
