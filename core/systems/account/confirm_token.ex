defmodule Systems.Account.ConfirmToken do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Button

  alias Systems.Account
  alias Systems.Account.User

  require Logger

  def mount(%{"token" => token}, _session, socket) do
    require_feature(:password_sign_in)

    {
      :ok,
      socket
      |> assign(
        failed: false,
        token: token,
        active_menu_item: nil
      )
      |> update_confirm_button()
      |> update_menus()
    }
  end

  defp update_confirm_button(socket) do
    confirm_button = %{
      action: %{type: :send, event: "confirm"},
      face: %{type: :primary, label: dgettext("eyra-account", "confirm.button")}
    }

    assign(socket, confirm_button: confirm_button)
  end

  defp confirm_user(%{assigns: %{token: token}} = socket) do
    case Account.Public.confirm_user(token) do
      {:ok, user} ->
        handle_succeeded(socket, user)

      _ ->
        handle_failed(socket)
    end
  end

  defp handle_succeeded(socket, %{email: email}) do
    Logger.notice("Confirm user: handle_succeeded #{email}")

    socket
    |> put_flash(:info, dgettext("eyra-user", "account.activated.successfully"))
    |> redirect(to: ~p"/user/signin?email=#{email}")
  end

  defp handle_failed(socket) do
    Logger.notice("Confirm user: handle_failed")

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
  def handle_event("confirm", _, socket) do
    {:noreply, confirm_user(socket)}
  end

  @impl true
  def handle_event("resend-token", %{"user" => %{"email" => email}}, socket) do
    case User.valid_email_changeset(email) do
      %{valid?: true} ->
        # FIXME: Add lockout logic
        case Account.Public.get_user_by_email(email) do
          nil ->
            # Pretend that a user exists to avoid leaking info.
            nil

          user when is_nil(user.confirmed_at) ->
            # FIXME: Add lockout logic
            Account.Public.deliver_user_confirmation_instructions(
              user,
              &~p"/user/confirm/#{&1}"
            )

          user ->
            # FIXME: Log suspicous behavior?
            Account.Public.deliver_already_activated_notification(
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
        <% else %>
          <Text.title1><%= dgettext("eyra-account", "activation.confirm.title") %></Text.title1>
          <Text.body><%= dgettext("eyra-account", "activation.confirm.body") %></Text.body>
          <.spacing value="M" />
          <.wrap>
            <Button.dynamic {@confirm_button} />
          </.wrap>
        <% end %>
        </Area.sheet>
      </.stripped>
    """
  end
end
