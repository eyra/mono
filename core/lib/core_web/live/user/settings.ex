defmodule CoreWeb.User.Settings do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :settings

  alias Core.Accounts
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Frameworks.Pixel.Text.{Title2, Title4}
  alias Frameworks.Pixel.Button.PrimaryAlpineButton

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    Accounts.mark_as_visited(user, :settings)
    {:ok, socket |> update_menus()}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("send-test-notification", _params, %{assigns: %{current_user: user}} = socket) do
    Core.WebPush.send(user, "Test notification")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Workspace menus={@menus}>
      <ContentArea>
        <MarginY id={:page_top} />
        <FormArea>
          <Title2>{dgettext("eyra-ui", "menu.item.settings")}</Title2>
          <Spacing value="XL" />
          <div x-data>
            <Title4>{dgettext("eyra-account", "push.registration.title")}</Title4>
            <Spacing value="XS" />
            <div class="text-bodymedium sm:text-bodylarge font-body" :if={not is_push_supported?(@socket)}>{dgettext("eyra-account", "push.unavailable.label")}</div>
            <div :if={is_push_supported?(@socket)}>
              <div x-show="$store.push.registration === 'not-registered'">
                <div class="text-bodymedium sm:text-bodylarge font-body">{dgettext("eyra-account", "push.registration.label")}</div>
                <Spacing value="XS" />
                <PrimaryAlpineButton
                  click="registerForPush()"
                  label={dgettext("eyra-account", "push.registration.button")}
                />
              </div>
              <div class="text-bodymedium sm:text-bodylarge font-body">
                <span x-show="$store.push.registration === 'pending'">{dgettext("eyra-account", "push.registration.pending")}</span>
                <span x-show="$store.push.registration === 'denied'">{dgettext("eyra-account", "push.registration.denied")}</span>
              </div>
              <div x-show="$store.push.registration === 'registered'">
                <span>{dgettext("eyra-account", "push.registration.activated")}</span>
              </div>
            </div>
          </div>
        </FormArea>
      </ContentArea>
    </Workspace>
    """
  end
end
