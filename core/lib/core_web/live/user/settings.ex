defmodule CoreWeb.User.Settings do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias CoreWeb.Layouts.Workspace

  alias EyraUI.Spacing
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Text.{Title2, Title6, BodyMedium}
  alias EyraUI.Button.{SecondaryLiveViewButton, PrimaryAlpineButton}

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Workspace
      user_agent={{ Browser.Ua.to_ua(@socket) }}
      active_item={{ :settings }}
    >
      <ContentArea>
        <FormArea>
          <Title2>{{dgettext "eyra-ui", "menu.item.settings"}}</Title2>
          <div :if={{ !is_native_web?(@socket) }}>
            <Spacing value="XL" />
            <div x-data>
              <Title6>{{dgettext "eyra-account", "push.registration.title"}}</Title6>
              <div x-show="$store.push.registration === 'not-registered'">
                <BodyMedium>{{dgettext("eyra-account", "push.registration.label")}}</BodyMedium>
                <Spacing value="XS" />
                <PrimaryAlpineButton click="registerForPush()" label={{dgettext("eyra-account", "push.registration.button")}} />
              </div>
              <BodyMedium>
                <span x-show="$store.push.registration === 'pending'">{{dgettext("eyra-account", "push.registration.pending")}}</span>
                <span x-show="$store.push.registration === 'denied'">{{dgettext("eyra-account", "push.registration.denied")}}</span>
              </BodyMedium>
              <div x-show="$store.push.registration === 'registered'">
                <span>{{dgettext("eyra-account", "push.registration.activated")}}</span>
                <Spacing value="XS" />
                <SecondaryLiveViewButton color="text-grey2" label={{dgettext("eyra-account", "push.registration.test.button")}} event="send-test-notification"/>
              </div>
            </div>
          </div>
        </FormArea>
      </ContentArea>
    </Workspace>
    """
  end
end
