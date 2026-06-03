defmodule Systems.Account.TermsAndPrivacyView do
  @moduledoc """
  Onboarding step shown to first-time SSO users: welcome + terms acceptance.
  Embedded in OnboardingPage as the :terms_and_privacy step.

  On continue with terms accepted: activates the user (sets confirmed_at)
  and publishes :terms_completed for the parent to re-mount the onboarding
  URL so the builder advances past this step.
  """
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Flash
  alias Frameworks.Pixel.Selector.Item, as: SelectorItem
  alias Frameworks.Pixel.Text
  alias Systems.Account

  @policy_urls Application.compile_env(:core, :policy_urls)

  defp policy_url(key), do: @policy_urls[key]

  def dependencies(), do: [:user_id]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{user_id: user_id}}) do
    Account.Public.get_user!(user_id)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok,
     socket
     |> assign(
       terms_accepted: false,
       terms_url: policy_url(:next_terms),
       privacy_url: policy_url(:next_privacy)
     )}
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_event("toggle_terms", _params, %{assigns: %{terms_accepted: accepted}} = socket) do
    {:noreply, assign(socket, terms_accepted: !accepted)}
  end

  @impl true
  def handle_event("continue", _params, %{assigns: %{terms_accepted: false}} = socket) do
    {:noreply,
     Flash.push_error(
       socket,
       dgettext("eyra-account", "terms_and_privacy.onboarding.terms.required")
     )}
  end

  @impl true
  def handle_event("continue", _params, %{assigns: %{model: user}} = socket) do
    {:ok, _} =
      user
      |> Account.User.confirm_changeset()
      |> Core.Repo.update()

    {:noreply, socket |> publish_event(:terms_completed)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-8 items-center" data-testid="terms-and-privacy-view">
      <Text.title2 align="text-center"><%= dgettext("eyra-account", "terms_and_privacy.onboarding.title") %></Text.title2>
      <Text.body align="text-center"><%= dgettext("eyra-account", "terms_and_privacy.onboarding.body") %></Text.body>
      <div class="cursor-pointer" phx-click="toggle_terms" data-testid="terms-and-privacy-onboarding-terms">
        <SelectorItem.checkbox raw?={true} item={%{
          value: dgettext("eyra-account", "terms_and_privacy.onboarding.terms",
            terms: ~s(<a href="#{@terms_url}" target="_blank" class="text-primary underline">#{dgettext("eyra-ui", "terms.link")}</a>),
            privacy: ~s(<a href="#{@privacy_url}" target="_blank" class="text-primary underline">#{dgettext("eyra-ui", "privacy.link")}</a>)
          ),
          active: @terms_accepted
        }} />
      </div>
      <Button.dynamic
        action={%{type: :send, event: "continue"}}
        face={%{type: :primary, label: dgettext("eyra-account", "onboarding.continue.button")}}
        testid="onboarding-continue"
      />
    </div>
    """
  end
end
