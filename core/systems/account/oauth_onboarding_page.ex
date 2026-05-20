defmodule Systems.Account.OAuthOnboardingPage do
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Selector.Item, as: SelectorItem

  @policy_urls Application.compile_env(:core, :policy_urls)

  defp policy_url(key), do: @policy_urls[key]

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        terms_accepted: false,
        terms_url: policy_url(:next_terms),
        privacy_url: policy_url(:next_privacy)
      )
      |> update_menus()
    }
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  @impl true
  def handle_event("toggle_terms", _params, %{assigns: %{terms_accepted: accepted}} = socket) do
    {:noreply, assign(socket, terms_accepted: !accepted)}
  end

  @impl true
  def handle_event("continue", _params, %{assigns: %{terms_accepted: false}} = socket) do
    {:noreply,
     put_flash(socket, :error, dgettext("eyra-account", "oauth.onboarding.terms.required"))}
  end

  @impl true
  def handle_event("continue", _params, %{assigns: %{current_user: user}} = socket) do
    {:noreply, push_navigate(socket, to: Systems.Account.UserAuth.signed_in_path(user))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.form>
        <div data-testid="oauth-onboarding-page">
          <Margin.y id={:page_top} />
          <Margin.y id={:page_top} />
          <div class="flex justify-center">
            <img class="h-16" src="/images/logos/products/next_wide.svg" alt="Next">
          </div>
          <.spacing value="L" />
          <Text.title2 align="center"><%= dgettext("eyra-account", "oauth.onboarding.title") %></Text.title2>
          <.spacing value="M" />
          <Text.body_small align="center"><%= dgettext("eyra-account", "oauth.onboarding.body") %></Text.body_small>
          <.spacing value="M" />
          <div class="cursor-pointer" phx-click="toggle_terms" data-testid="oauth-onboarding-terms">
            <SelectorItem.checkbox raw?={true} item={%{
              value: dgettext("eyra-account", "oauth.onboarding.terms",
                terms: ~s(<a href="#{@terms_url}" target="_blank" class="text-primary underline">#{dgettext("eyra-ui", "terms.link")}</a>),
                privacy: ~s(<a href="#{@privacy_url}" target="_blank" class="text-primary underline">#{dgettext("eyra-ui", "privacy.link")}</a>)
              ),
              active: @terms_accepted
            }} />
          </div>
          <.spacing value="M" />
          <Button.dynamic_bar buttons={[
            %{
              action: %{type: :send, event: "continue"},
              face: %{type: :primary, label: dgettext("eyra-account", "oauth.onboarding.continue.button"), bg_color: "bg-grey1", text_color: "text-white"},
              full_width: true,
              testid: "oauth-onboarding-continue"
            }
          ]} />
        </div>
      </Area.form>
    </.stripped>
    """
  end
end
