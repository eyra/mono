defmodule CoreWeb.User.ConfirmToken do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :confirm_token

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Button

  alias Core.Accounts
  alias Core.Accounts.User

  def mount(%{"token" => token}, _session, socket) do
    require_feature(:password_sign_in)
    connected? = Phoenix.LiveView.connected?(socket)

    {:ok,
     socket
     |> assign(
       failed: false,
       token: token
     )
     |> confirm_user(connected?)}
  end

  defp confirm_user(socket, false) do
    # Only confirm user when socket is connected to prevent early invalidation of token.
    # https://github.com/eyra/mono/issues/615
    socket
  end

  defp confirm_user(%{assigns: %{token: token}} = socket, true) do
    case Accounts.confirm_user(token) do
      {:ok, user} ->
        handle_succeeded(socket, user)

      _ ->
        handle_failed(socket)
    end
  end

  defp handle_succeeded(socket, %{email: email}) do
    socket
    |> put_flash(:info, dgettext("eyra-user", "account.activated.successfully"))
    |> redirect(to: ~p"/user/signin?email=#{email}")
  end

  defp handle_failed(socket) do
    assign(socket,
      failed: true,
      status: :invalid,
      changeset: User.valid_email_changeset()
    )
  end

  def handle_info({:delivered_email, _email}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("resend-token", %{"user" => %{"email" => email}}, socket) do
    case User.valid_email_changeset(email) do
      %{valid?: true} ->
        # FIXME: Add lockout logic
        case Accounts.get_user_by_email(email) do
          nil ->
            # Pretend that a user exists to avoid leaking info.
            nil

          user when is_nil(user.confirmed_at) ->
            # FIXME: Add lockout logic
            Accounts.deliver_user_confirmation_instructions(
              user,
              &Routes.live_url(socket, CoreWeb.User.ConfirmToken, &1)
            )

          user ->
            # FIXME: Log suspicous behavior?
            Accounts.deliver_already_activated_notification(
              user,
              ~p"/user/signin"
            )
        end

        {:noreply,
         put_flash(
           socket,
           :info,
           dgettext("eyra-user", "confirm.token.flash")
         )}

      changeset ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> put_flash(:error, dgettext("eyra-user", "Invalid email"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.stripped menus={@menus}>
        <Area.sheet>
        <Margin.y id={:page_top} />
        <%= if @failed do %>
          <Text.title1><%= dgettext("eyra-account", "activation.failed.title") %></Text.title1>
          <Text.body><%= dgettext("eyra-account", "activation.failed.body") %></Text.body>
          <.spacing value="M" />
          <.form id="confirm_token" :let={form} for={%{}} phx-submit="resend-token" >
            <.email_input form={form} field={:email} label_text={dgettext("eyra-user", "confirm.token.email.label")} />
            <Button.submit label={dgettext("eyra-account", "confirm.token.resend_button")} />
          </.form>
        <% end %>
        </Area.sheet>
      </.stripped>
    """
  end
end
