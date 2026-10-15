defmodule Systems.Assignment.OnboardingConsentViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Consent

  def view_model(%{consent_agreement: consent_agreement} = _assignment, %{current_user: user}) do
    revision = Consent.Public.latest_revision(consent_agreement, [:signatures])

    %{
      title: dgettext("eyra-assignment", "onboarding.consent.title"),
      revision: revision,
      user: user,
      clickwrap_view: clickwrap_view(revision, user)
    }
  end

  defp clickwrap_view(revision, user) do
    %{
      module: Consent.ClickWrapView,
      id: :clickwrap_view,
      revision: revision,
      user: user,
      accept_text: dgettext("eyra-consent", "click_wrap.accept.button"),
      decline_text: dgettext("eyra-consent", "click_wrap.decline.button"),
      validation_text: dgettext("eyra-consent", "click_wrap.consent.validation")
    }
  end
end
