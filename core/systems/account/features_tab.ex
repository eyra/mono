defmodule Systems.Account.FeaturesTab do
  @moduledoc """
  Features tab implementation.
  This tab is only visible for PANL participants.
  """
  @behaviour Systems.Account.Page.Tab

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Pool

  @impl true
  def key, do: :features

  @impl true
  def visible?(user), do: Pool.Public.participant?(:panl, user)

  @impl true
  def build(_user, live_context) do
    element =
      CoreWeb.Live.Element.prepare_live_view(
        :features_view,
        Account.FeaturesView,
        live_context: live_context
      )

    %{
      id: :features,
      title: dgettext("eyra-account", "profile.tab.features.title"),
      type: :fullpage,
      element: element,
      ready?: true
    }
  end

  def build_live_context(user) do
    LiveContext.new(%{user_id: user.id})
  end
end
