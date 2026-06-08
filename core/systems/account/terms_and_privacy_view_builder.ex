defmodule Systems.Account.TermsAndPrivacyViewBuilder do
  @moduledoc """
  Builder for TermsAndPrivacyView. The view manages its own UI state
  (terms_accepted, policy URLs), so the view model only carries the
  current user reference for use by event handlers.
  """
  alias Systems.Account

  def view_model(%Account.User{} = user, _assigns) do
    %{user: user}
  end
end
