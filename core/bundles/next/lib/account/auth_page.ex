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
  def mount(_params, _session, socket) do
    if feature_enabled?(:otp) do
      {
        :ok,
        socket
        |> assign(form: to_form(%{"email" => ""}), error: nil, loading: false)
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
    case Account.EmailRouter.route(email) do
      :google ->
        {:noreply, redirect(socket, to: "/auth/google?login_hint=#{URI.encode_www_form(email)}")}

      :surfconext ->
        {:noreply, redirect(socket, to: "/auth/surfconext")}

      :otp ->
        Account.Public.generate_otp(email)
        {:noreply, push_navigate(socket, to: ~p"/user/auth/verify?email=#{email}")}
    end
  end

  defp valid_email?(email), do: String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.content class="items-center h-full">
        <Area.form>
          <Text.title2><%= dgettext("eyra-account", "auth.title") %></Text.title2>
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
