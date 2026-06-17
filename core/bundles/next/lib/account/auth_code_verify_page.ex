defmodule Next.Account.AuthCodeVerifyPage do
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  alias CoreWeb.Endpoint
  alias Frameworks.Pixel.Button
  alias Systems.Account

  @token_salt "otp-redeem"
  @token_max_age 120

  @impl true
  def mount(%{"email" => email}, _session, socket) do
    if feature_enabled?(:otp) do
      {
        :ok,
        socket
        |> assign(email: email, form: to_form(%{"code" => ""}), error: nil)
        |> update_menus()
      }
    else
      {:ok, redirect(socket, to: ~p"/user/signin")}
    end
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  @impl true
  def handle_event("verify", %{"code" => code}, %{assigns: %{email: email}} = socket) do
    code = String.trim(code)

    case Account.Public.verify_otp(email, code) do
      {:ok, user} ->
        payload = %{user_id: user && user.id, email: email}
        token = Phoenix.Token.sign(Endpoint, @token_salt, payload)
        {:noreply, redirect(socket, to: ~p"/user/auth/redeem?token=#{token}")}

      {:error, :invalid} ->
        {:noreply,
         socket
         |> assign(error: dgettext("eyra-account", "auth.code.invalid"))
         |> push_event("auth_code:clear", %{})}

      {:error, reason} when reason in [:max_attempts, :not_found] ->
        message =
          case reason do
            :max_attempts -> dgettext("eyra-account", "auth.code.max_attempts")
            :not_found -> dgettext("eyra-account", "auth.code.expired")
          end

        {:noreply,
         socket
         |> put_flash(:error, message)
         |> push_navigate(to: ~p"/user/auth/identify")}
    end
  end

  def decode_redeem_token(token) do
    Phoenix.Token.verify(Endpoint, @token_salt, token, max_age: @token_max_age)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.content>
        <Area.form>
          <Margin.y id={:page_top} />
          <Text.title2 align="text-center"><%= dgettext("eyra-account", "auth.code.title") %></Text.title2>
          <.spacing value="L" />
          <.form id="auth_code_form" for={@form} phx-submit="verify">
            <div
              id="auth-code-input"
              phx-hook="AuthCodeInput"
              phx-update="ignore"
              class="flex flex-row justify-between gap-2"
              data-testid="auth-code-input"
            >
              <%= for i <- 0..5 do %>
                <input
                  type="text"
                  data-otp-cell={i}
                  maxlength="1"
                  inputmode="numeric"
                  pattern="[0-9]*"
                  autocomplete={if i == 0, do: "one-time-code", else: "off"}
                  data-testid={"auth-code-cell-#{i}"}
                  class="text-center text-title4 font-title4 text-grey1 w-12 h-14 rounded border-2 border-grey3 focus:border-primary focus:outline-none bg-white"
                />
              <% end %>
              <input type="hidden" name="code" data-otp-value />
            </div>
            <%= if @error do %>
              <.spacing value="XS" />
              <Text.caption color="text-warning" padding="" margin=""><%= @error %></Text.caption>
            <% end %>
            <.spacing value="M" />
            <Button.submit_wide
              label={dgettext("eyra-account", "auth.continue.button")}
              bg_color="bg-grey1"
              testid="auth-code-verify-button"
            />
          </.form>
        </Area.form>
      </Area.content>
    </.stripped>
    """
  end
end
