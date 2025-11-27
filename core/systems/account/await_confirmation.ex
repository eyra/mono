defmodule Systems.Account.AwaitConfirmation do
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({Frameworks.Fabric.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  alias Frameworks.Pixel.Text

  @impl true
  def mount(params, _session, socket) do
    require_feature(:password_sign_in)

    locale = params["locale"]
    if locale, do: Gettext.put_locale(CoreWeb.Gettext, locale)

    {
      :ok,
      socket
      |> assign(active_menu_item: :profile)
      |> update_menus()
    }
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  # data(changeset, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div>
        <Area.sheet>
        <Margin.y id={:page_top} />
          <div class="flex flex-col items-center">
            <Text.title2><%= dgettext("eyra-account", "await.confirmation.title") %></Text.title2>
            <Text.body align="text-center"><%= dgettext("eyra-account", "await.confirmation.description") %></Text.body>
          </div>
        </Area.sheet>
      </div>
    </.stripped>
    """
  end
end
