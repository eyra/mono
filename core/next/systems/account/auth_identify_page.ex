defmodule Next.Account.AuthIdentifyPage do
  use CoreWeb, :live_view_fabric

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({CoreWeb.Live.Hook.RemoteIp, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus
  import Frameworks.Pixel.Form

  alias CoreWeb.ReturnTo
  alias Frameworks.Pixel.Button
  alias Next.Account.OtpSignin
  alias Systems.Account

  @impl true
  def mount(params, _session, socket) do
    creator? = socket.assigns.live_action != :participant
    return_to = ReturnTo.sanitize(Map.get(params, "return_to"))

    if feature_enabled?(:otp) do
      {
        :ok,
        socket
        |> assign(
          form: to_form(%{"email" => ""}),
          loading: false,
          creator?: creator?,
          return_to: return_to,
          password_signin_url: password_signin_url(creator?, return_to)
        )
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
  def handle_event("submit", %{"email" => email}, socket) do
    email = String.trim(email)

    if OtpSignin.valid_email?(email) do
      socket =
        socket
        |> assign(loading: true, form: to_form(%{"email" => email}))

      send(self(), {:route_email, email})
      {:noreply, socket}
    else
      error = dgettext("eyra-account", "auth.email.invalid")

      {:noreply,
       assign(socket,
         loading: false,
         form: to_form(%{"email" => email}, errors: [email: {error, []}])
       )}
    end
  end

  @impl true
  def handle_event("change", %{"email" => email}, socket) do
    {:noreply, assign(socket, form: to_form(%{"email" => email}))}
  end

  @impl true
  def handle_info(
        {:route_email, email},
        %{assigns: %{return_to: return_to, creator?: creator?, remote_ip: remote_ip}} = socket
      ) do
    case Account.EmailRouter.route(email) do
      provider when provider in [:google, :surfconext, :mock] ->
        {:noreply, redirect(socket, to: OtpSignin.provider_url(provider, email, return_to))}

      :otp ->
        case Account.Public.generate_otp(email, remote_ip) do
          :ok ->
            {:noreply, push_navigate(socket, to: verify_url(email, return_to, creator?))}

          {:error, :rate_limited} ->
            error = dgettext("eyra-account", "auth.email.rate_limited")

            {:noreply,
             assign(socket,
               loading: false,
               form: to_form(%{"email" => email}, errors: [email: {error, []}])
             )}
        end
    end
  end

  # The participant entry stays code-only; elsewhere the password form is the fallback.
  defp password_signin_url(true, return_to) do
    if feature_enabled?(:password_sign_in), do: password_form_url(return_to)
  end

  defp password_signin_url(false, _return_to), do: nil

  # `GET /user/session` keeps the return path in the session for the password form.
  defp password_form_url(nil), do: ~p"/user/signin"
  defp password_form_url(return_to), do: ReturnTo.append(~p"/user/session", return_to)

  defp verify_url(email, nil, creator?),
    do: ~p"/user/auth/verify?email=#{email}&creator=#{creator?}"

  defp verify_url(email, return_to, creator?),
    do: ~p"/user/auth/verify?email=#{email}&return_to=#{return_to}&creator=#{creator?}"

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus} centered?>
      <div
        id="auth-identify-content"
        class="h-full flex flex-col justify-center pb-16"
        phx-hook="LiveContent"
        data-show-errors={true}
      >
      <Area.content>
        <Area.form>
          <Text.title2 align="text-center"><%= dgettext("eyra-account", "auth.title") %></Text.title2>
          <.spacing value="L" />
          <.form id="auth_form" for={@form} phx-submit="submit" phx-change="change" novalidate>
            <.email_input
              form={@form}
              field={:email}
              label_text=""
              reserve_error_space={false}
              testid="auth-email-input"
              placeholder={dgettext("eyra-account", "auth.email.placeholder")}
            />
            <div class="mt-[6px]" />
            <Button.dynamic
              action={%{type: :submit}}
              face={
                %{
                  type: :primary,
                  label: dgettext("eyra-account", "auth.continue.button"),
                  bg_color: "bg-grey1"
                }
                |> then(fn face -> if @loading, do: Map.put(face, :loading, true), else: face end)
              }
              full_width={true}
              testid="auth-continue-button"
            />
          </.form>
          <div :if={@password_signin_url} class="mt-6 flex justify-center">
            <Button.dynamic
              action={%{type: :redirect, to: @password_signin_url}}
              face={%{type: :link, text: dgettext("eyra-account", "auth.password.link")}}
              testid="auth-password-link"
            />
          </div>
        </Area.form>
      </Area.content>
      </div>
    </.stripped>
    """
  end
end
