defmodule Link.Index.Page do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Website.Component, :index

  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Card
  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Hero

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> update_menus()
    }
  end

  def cta_title(nil) do
    dgettext("eyra-link", "member.card.title")
  end

  def cta_title(current_user) do
    dgettext("eyra-link", "member.profile.card.title", user: current_user.displayname)
  end

  @impl true
  def handle_event("menu-item-clicked", %{"action" => action}, socket) do
    # toggle menu
    {:noreply, push_redirect(socket, to: action)}
  end

  def primary_cta_button_label(current_user) do
    if current_user.researcher do
      dgettext("eyra-link", "console-button")
    else
      dgettext("eyra-link", "marketplace.button")
    end
  end

  def primary_cta_path(socket, current_user) do
    if current_user.researcher do
      Routes.live_path(socket, Link.Console.Page)
    else
      Routes.live_path(socket, Link.Marketplace.Page)
    end
  end

  # data(current_user, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.website user={@current_user} user_agent={Browser.Ua.to_ua(@socket)} menus={@menus}>
      <:hero>
        <Hero.large
          title={dgettext("eyra-link", "welcome.title")}
          subtitle={dgettext("eyra-link", "welcome.subtitle")}
        />
      </:hero>
      <Area.content>
        <Margin.y id={:page_top} />
        <Grid.absolute>
          <div class="md:col-span-2">
            <Text.title1>
              <%= dgettext("eyra-link", "link.title") %>
            </Text.title1>
            <Text.intro>
              <%= dgettext("eyra-link", "link.message") %>
            </Text.intro>
            <Text.intro>
              <%= dgettext("eyra-link", "link.message.interested") %>
              <a href="mailto:info@researchpanl.eu" class="text-primary">info@researchpanl.eu</a>.
            </Text.intro>
          </div>
          <div>
            <%= if @current_user do %>
              <Card.primary_cta
                title={cta_title(@current_user)}
                button_label={primary_cta_button_label(@current_user)}
                to={primary_cta_path(@socket, @current_user)}
              />
            <% else %>
              <Card.primary_cta
                title={dgettext("eyra-link", "signup.card.title")}
                button_label={dgettext("eyra-link", "signup.card.button")}
                to={~p"/user/signin"}
              />
            <% end %>
          </div>
          <Panel.usp
            title={dgettext("eyra-link", "usp1.title")}
            description={dgettext("eyra-link", "usp1.description")}
          />
          <Panel.usp
            title={dgettext("eyra-link", "usp2.title")}
            description={dgettext("eyra-link", "usp2.description")}
          />
          <Panel.usp
            title={dgettext("eyra-link", "usp3.title")}
            description={dgettext("eyra-link", "usp3.description")}
          />
        </Grid.absolute>
      </Area.content>
    </.website>
    """
  end
end
