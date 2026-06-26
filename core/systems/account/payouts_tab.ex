defmodule Systems.Account.PayoutsTab do
  @moduledoc """
  Payouts (Uitbetalingen) tab implementation.
  Visible for all participants: shows the bank-account verification status and
  the payout history.
  """
  @behaviour Systems.Account.Page.Tab

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account

  @impl true
  def key, do: :payouts

  @impl true
  def visible?(_user), do: true

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
