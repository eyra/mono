defmodule Systems.Account.Identity.Mock.SigninPage do
  use CoreWeb, :live_view_fabric

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({Frameworks.Fabric.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Menus
  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.{Button, Text}

  @impl true
  def mount(_params, _session, socket) do
    if Systems.Account.Identity.Mock.configured?() do
      {:ok,
       socket
       |> assign(active_menu_item: nil, form: to_form(%{"email" => "example@mock.com"}))
       |> update_menus()}
    else
      {:ok, Phoenix.LiveView.redirect(socket, to: ~p"/not_found")}
    end
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    assign(socket, menus: build_menus(stripped_menus_config(), user, uri))
  end

  @impl true
  def handle_event("sign_in", %{"email" => email}, socket) do
    if Systems.Account.Identity.Mock.valid_email?(email) do
      {:noreply,
       Phoenix.LiveView.push_navigate(socket, to: ~p"/auth/mock/callback?email=#{email}")}
    else
      {:noreply, Phoenix.LiveView.put_flash(socket, :error, "Use an @mock.com email address")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div id="mock-auth-signin-content" phx-hook="LiveContent" data-testid="mock-auth-signin-page">
        <Area.content>
          <Area.form>
            <Margin.y id={:page_top} />
            <div class="flex flex-col items-center gap-4">
              <img class="h-16" src="/images/logos/platforms/mock.svg" alt="Mock">
              <.spacing value="S" />
              <Text.title2 align="text-center">Sign in</Text.title2>
              <.form id="mock-auth-form" for={@form} phx-submit="sign_in">
                <.email_input
                  form={@form}
                  field={:email}
                  label_text=""
                  testid="mock-auth-email-input"
                />
                <Button.submit_wide label="Sign in" />
              </.form>
            </div>
          </Area.form>
        </Area.content>
      </div>
    </.stripped>
    """
  end
end
