defmodule Next.Account.AuthPage do
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus
  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Button
  alias Systems.Account

  @impl true
  def mount(params, _session, socket) do
    if feature_enabled?(:otp) do
      {
        :ok,
        socket
        |> assign(
          form: to_form(%{"email" => ""}),
          error: nil,
          loading: false,
          return_to: sanitize_return_to(Map.get(params, "return_to"))
        )
        |> update_menus()
      }
    else
      {:ok, redirect(socket, to: ~p"/user/signin")}
    end
  end

  # Only same-origin paths are accepted, so an attacker cannot craft a link
  # that ends up bouncing the user to an external site after login.
  defp sanitize_return_to("/" <> _rest = path), do: path
  defp sanitize_return_to(_), do: nil

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  @impl true
  def handle_event("submit", %{"email" => email}, socket) do
    email = String.trim(email)

    if valid_email?(email) do
      socket =
        socket
        |> assign(loading: true, error: nil, form: to_form(%{"email" => email}))

      send(self(), {:route_email, email})
      {:noreply, socket}
    else
      {:noreply,
       assign(socket,
         error: dgettext("eyra-account", "auth.email.invalid"),
         form: to_form(%{"email" => email})
       )}
    end
  end

  @impl true
  def handle_event("change", %{"email" => email}, socket) do
    {:noreply, assign(socket, form: to_form(%{"email" => email}), error: nil)}
  end

  @impl true
  def handle_info({:route_email, email}, socket) do
    return_to = socket.assigns[:return_to]

    case Account.EmailRouter.route(email) do
      :google ->
        {:noreply, redirect(socket, to: append_return_to(google_url(email), return_to))}

      :surfconext ->
        {:noreply, redirect(socket, to: append_return_to("/auth/surfconext", return_to))}

      :otp ->
        case Account.Public.generate_otp(email) do
          :ok ->
            {:noreply, push_navigate(socket, to: verify_url(email, return_to))}

          {:error, :rate_limited} ->
            {:noreply,
             assign(socket,
               loading: false,
               error: dgettext("eyra-account", "auth.email.rate_limited")
             )}
        end
    end
  end

  defp google_url(email), do: "/auth/google?login_hint=#{URI.encode_www_form(email)}"

  defp verify_url(email, nil), do: ~p"/user/auth/verify?email=#{email}"

  defp verify_url(email, return_to),
    do: ~p"/user/auth/verify?email=#{email}&return_to=#{return_to}"

  defp append_return_to(url, nil), do: url

  defp append_return_to(url, return_to) do
    sep = if String.contains?(url, "?"), do: "&", else: "?"
    "#{url}#{sep}return_to=#{URI.encode_www_form(return_to)}"
  end

  defp valid_email?(email), do: String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div class="h-full flex flex-col justify-center">
      <Area.content>
        <Area.form>
          <Text.title2 align="text-center"><%= dgettext("eyra-account", "auth.title") %></Text.title2>
          <.spacing value="L" />
          <.form id="auth_form" for={@form} phx-submit="submit" phx-change="change">
            <.email_input
              form={@form}
              field={:email}
              label_text=""
              reserve_error_space={false}
              testid="auth-email-input"
              placeholder={dgettext("eyra-account", "auth.email.placeholder")}
            />
            <%= if @error do %>
              <.spacing value="XS" />
              <Text.body_small color="text-delete"><%= @error %></Text.body_small>
            <% end %>
            <.spacing value="M" />
            <Button.submit_wide
              label={dgettext("eyra-account", "auth.continue.button")}
              bg_color="bg-grey1"
              testid="auth-continue-button"
            />
          </.form>
        </Area.form>
      </Area.content>
      </div>
    </.stripped>
    """
  end
end
