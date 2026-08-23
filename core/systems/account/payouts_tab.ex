defmodule Systems.Account.PayoutsTab do
  @moduledoc """
  Payouts (Uitbetalingen) tab implementation: shows the bank-account
  verification status and the payout history.

  Part of the post-launch money surface, so it follows `:panl_post_launch`
  along with the rewards summary and the participation history.
  """
  @behaviour Systems.Account.Page.Tab

  use Gettext, backend: CoreWeb.Gettext
  use Core.FeatureFlags

  alias Frameworks.Concept.LiveContext
  alias Systems.Account

  @impl true
  def key, do: :payouts

  @impl true
  def visible?(_user), do: feature_enabled?(:panl_post_launch)

  @impl true
  def build(_user, live_context) do
    element =
      CoreWeb.Live.Element.prepare_live_view(
        :payouts_view,
        Account.PayoutsView,
        live_context: live_context
      )

    %{
      id: :payouts,
      title: dgettext("eyra-account", "profile.tab.payouts.title"),
      type: :fullpage,
      element: element,
      ready?: true
    }
  end

  def build_live_context(user) do
    LiveContext.new(%{user_id: user.id})
  end
end
