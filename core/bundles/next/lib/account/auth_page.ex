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
          after_action: Map.get(params, "after")
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
    after_action = socket.assigns[:after_action]

    case Account.EmailRouter.route(email) do
      :google ->
        {:noreply, redirect(socket, to: append_after(google_url(email), after_action))}

      :surfconext ->
        {:noreply, redirect(socket, to: append_after("/auth/surfconext", after_action))}

      :otp ->
        case Account.Public.generate_otp(email) do
          :ok ->
            {:noreply, push_navigate(socket, to: verify_url(email, after_action))}

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

  defp verify_url(email, after_action),
    do: ~p"/user/auth/verify?email=#{email}&after=#{after_action}"

  defp append_after(url, nil), do: url

  defp append_after(url, after_action) do
    sep = if String.contains?(url, "?"), do: "&", else: "?"
    "#{url}#{sep}after=#{URI.encode_www_form(after_action)}"
  end

  defp valid_email?(email), do: String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.content>
        <Area.form>
          <Margin.y id={:page_top} />
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
    </.stripped>
    """
  end
end
