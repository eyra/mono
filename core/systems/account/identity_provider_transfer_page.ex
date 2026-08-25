defmodule Systems.Account.IdentityProviderTransferPage do
  use CoreWeb, :live_view_fabric

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({Frameworks.Fabric.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Menus

  alias Frameworks.Pixel.{Button, Text}

  @impl true
  def mount(%{"idp" => idp}, %{"idp_transfer" => %{"email" => email, "idp" => idp}}, socket) do
    {:ok,
     socket
     |> assign(email: email, idp: idp_label(idp), idp_key: idp, active_menu_item: nil)
     |> update_menus()}
  end

  def mount(_params, _session, socket) do
    {:ok, Phoenix.LiveView.redirect(socket, to: ~p"/user/auth/identify")}
  end

  defp idp_label("apple"), do: "Apple"
  defp idp_label("google"), do: "Google"
  defp idp_label("mock"), do: "Mock"
  defp idp_label("surfconext"), do: "SURFconext"

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    assign(socket, menus: build_menus(stripped_menus_config(), user, uri))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus} centered?>
      <div
        id="idp-transfer-content"
        phx-hook="LiveContent"
        data-testid="idp-transfer-page"
        class="h-full flex flex-col justify-center pb-16"
      >
        <Area.content>
          <Area.sheet>
            <div class="flex flex-col items-center gap-4">
              <Text.title2 align="text-center">
                <%= dgettext("eyra-account", "idp.transfer.title") %>
              </Text.title2>
              <Text.body align="text-center">
                <%= raw(
                  dgettext(
                    "eyra-account",
                    "idp.transfer.body",
                    idp: @idp,
                    email: @email |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
                  )
                ) %>
              </Text.body>
              <.spacing value="S" />
              <Button.dynamic_bar buttons={[
                %{
                  action: %{type: :http_post, to: ~p"/auth/#{@idp_key}/transfer/confirm"},
                  face: %{type: :primary, label: "Confirm transfer"},
                  testid: "idp-transfer-confirm"
                },
                %{
                  action: %{type: :http_post, to: ~p"/auth/#{@idp_key}/transfer/decline"},
                  face: %{type: :secondary, label: "Decline"},
                  testid: "idp-transfer-decline"
                }
              ]} />
            </div>
          </Area.sheet>
        </Area.content>
      </div>
    </.stripped>
    """
  end
end
