defmodule Next.Account.OAuthSignupPage do
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  alias Frameworks.Pixel.Button

  defp providers do
    Application.get_env(:core, :account, []) |> Keyword.get(:oauth_providers, %{})
  end

  @impl true
  def mount(%{"provider" => provider}, _session, socket) do
    case Map.get(providers(), provider) do
      nil ->
        {:ok, redirect(socket, to: "/user/signin")}

      %{name: name, logo: logo, auth_path: auth_path} ->
        {
          :ok,
          socket
          |> assign(provider_name: name, provider_logo: logo, auth_path: auth_path)
          |> update_menus()
        }
    end
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.form>
        <Margin.y id={:page_top} />
        <Margin.y id={:page_top} />
        <div class="flex justify-center">
          <img class="h-16" src={@provider_logo} alt={@provider_name}>
        </div>
        <.spacing value="L" />
        <Text.title2 align="center"><%= dgettext("eyra-next", "oauth.signup.title") %></Text.title2>
        <.spacing value="M" />
        <Text.body_small align="center"><%= raw(dgettext("eyra-next", "oauth.signup.body", identity_provider: @provider_name)) %></Text.body_small>
        <.spacing value="M" />
        <Button.dynamic_bar buttons={[
          %{
            action: %{type: :http_get, to: @auth_path},
            face: %{type: :primary, label: dgettext("eyra-next", "oauth.signup.button", identity_provider: @provider_name), bg_color: "bg-grey1", text_color: "text-white"},
            full_width: true
          }
        ]} />
      </Area.form>
    </.stripped>
    """
  end
end
