defmodule Systems.Account.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Account

  @impl true
  def view_model(page, model, assigns) do
    builder(page).view_model(model, assigns)
  end

  defp builder(Account.Page), do: Account.PageBuilder
  defp builder(Account.FeaturesView), do: Account.FeaturesViewBuilder
  defp builder(Account.PayoutsView), do: Account.PayoutsViewBuilder
  defp builder(Account.ProfileView), do: Account.ProfileViewBuilder
  defp builder(Account.OnboardingPage), do: Account.OnboardingPageBuilder
  defp builder(Account.TermsAndPrivacyView), do: Account.TermsAndPrivacyViewBuilder
end
