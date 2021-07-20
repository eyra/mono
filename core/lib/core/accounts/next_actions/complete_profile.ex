defmodule Core.Accounts.NextActions.CompleteProfile do
  @behaviour Core.NextActions.ViewModel

  @impl Core.NextActions.ViewModel
  def to_view_model(url_resolver, _count, _params) do
    %{
      title: "Complete your profile",
      description: "Fill out the missing fields to complete your profile.",
      cta: "Open profile",
      url: url_resolver.(CoreWeb.User.Profile, [])
    }
  end
end
