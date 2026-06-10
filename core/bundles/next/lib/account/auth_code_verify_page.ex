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

  @token_salt "otp-finalize"
  @token_max_age 120

  @impl true
  def mount(%{"email" => email}, _session, socket) do
    if feature_enabled?(:otp) do
      {
        :ok,
        socket
        |> assign(email: email, form: to_form(%{"code" => ""}), error: nil, sending: false)
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
        {:noreply, redirect(socket, to: ~p"/user/auth/finalize?token=#{token}")}

      {:error, :invalid} ->
        {:noreply,
         assign(socket,
           error: dgettext("eyra-account", "auth.code.invalid"),
           form: to_form(%{"code" => ""})
         )}

      {:error, :max_attempts} ->
        {:noreply,
         assign(socket,
           error: dgettext("eyra-account", "auth.code.max_attempts"),
           form: to_form(%{"code" => ""})
         )}

      {:error, :not_found} ->
        {:noreply,
         assign(socket,
           error: dgettext("eyra-account", "auth.code.expired"),
           form: to_form(%{"code" => ""})
         )}
    end
  end

  @impl true
  def handle_event("resend", _params, %{assigns: %{email: email}} = socket) do
    Account.Public.generate_otp(email)

    {:noreply,
     socket
     |> assign(error: nil, sending: false, form: to_form(%{"code" => ""}))
     |> put_flash(:info, dgettext("eyra-account", "auth.code.resent"))}
  end

  @impl true
  def handle_event("change", _params, socket) do
    {:noreply, assign(socket, error: nil)}
  end

  def verify_finalize_token(token) do
    Phoenix.Token.verify(Endpoint, @token_salt, token, max_age: @token_max_age)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.content>
        <Area.form>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-account", "auth.code.title") %></Text.title2>
          <.spacing value="XS" />
          <Text.body_medium color="text-grey2">
            <%= dgettext("eyra-account", "auth.code.subtitle") %> <strong><%= @email %></strong>
          </Text.body_medium>
          <.spacing value="L" />
          <.form id="auth_code_form" for={@form} phx-submit="verify" phx-change="change">
            <div class="flex flex-col gap-1">
              <label class="text-label font-label text-grey1">
                <%= dgettext("eyra-account", "auth.code.label") %>
              </label>
              <input
                type="text"
                name="code"
                value=""
                maxlength="6"
                inputmode="numeric"
                pattern="[0-9]*"
                autocomplete="one-time-code"
                data-testid="auth-code-input"
                class="text-center text-title3 font-title3 tracking-widest w-full h-14 rounded border border-grey3 focus:border-primary focus:outline-none bg-white"
                phx-debounce="false"
              />
            </div>
            <%= if @error do %>
              <.spacing value="XS" />
              <Text.body_small color="text-delete"><%= @error %></Text.body_small>
            <% end %>
            <.spacing value="M" />
            <Button.submit_wide
              label={dgettext("eyra-account", "auth.code.verify.button")}
              bg_color="bg-grey1"
              testid="auth-code-verify-button"
            />
          </.form>
          <.spacing value="M" />
          <div class="flex justify-center">
            <Button.dynamic
              action={%{type: :send, event: "resend"}}
              face={%{type: :link, text: dgettext("eyra-account", "auth.code.resend.link")}}
            />
          </div>
          <.spacing value="M" />
          <div class="flex justify-center">
            <Button.dynamic
              action={%{type: :redirect, to: ~p"/user/auth"}}
              face={%{type: :link, text: dgettext("eyra-account", "auth.code.change_email.link")}}
            />
          </div>
        </Area.form>
      </Area.content>
    </.stripped>
    """
  end
end
