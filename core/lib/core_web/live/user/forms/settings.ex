defmodule CoreWeb.User.Forms.Settings do
  use CoreWeb, :live_component

  import CoreWeb.UI.OldSkool, only: [is_push_supported?: 1]

  alias Core.Accounts
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  @impl true
  def update(%{user: user}, socket) do
    Accounts.mark_as_visited(user, :settings)
    {:ok, assign(socket, user: user)}
  end

  @impl true
  def handle_event("send-test-notification", _params, %{assigns: %{user: user}} = socket) do
    Core.WebPush.send(user, "Test notification")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Area.form>
          <Text.title2><%= dgettext("eyra-ui", "menu.item.settings") %></Text.title2>
          <.spacing value="XL" />
          <div x-data>
            <Text.title4><%= dgettext("eyra-account", "push.registration.title") %></Text.title4>
            <.spacing value="XS" />
            <%= if is_push_supported?(@socket) do %>
              <div x-show="$store.push.registration === 'not-registered'">
                <div class="text-bodymedium sm:text-bodylarge font-body"><%= dgettext("eyra-account", "push.registration.label") %></div>
                <.spacing value="XS" />
                <Button.primary_alpine
                  click="registerForPush()"
                  label={dgettext("eyra-account", "push.registration.button")}
                />
              </div>
              <div class="text-bodymedium sm:text-bodylarge font-body">
                <span x-show="$store.push.registration === 'pending'"><%= dgettext("eyra-account", "push.registration.pending") %></span>
                <span x-show="$store.push.registration === 'denied'"><%= dgettext("eyra-account", "push.registration.denied") %></span>
              </div>
              <div x-show="$store.push.registration === 'registered'">
                <span><%= dgettext("eyra-account", "push.registration.activated") %></span>
              </div>
            <% else %>
              <div class="text-bodymedium sm:text-bodylarge font-body">
                <%= dgettext("eyra-account", "push.unavailable.label") %>
              </div>
            <% end %>
          </div>
        </Area.form>
      </Area.content>
      </div>
    """
  end
end
