defmodule CoreWeb.User.ConfirmToken do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Button

  alias Core.Accounts
  alias Core.Accounts.User

  def mount(%{"token" => token}, _session, socket) do
    require_feature(:password_sign_in)

    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:ok,
         socket
         |> put_flash(:info, dgettext("eyra-user", "account.activated.successfully"))
         |> redirect(to: ~p"/user/signin")}

      _ ->
        {:ok,
         assign(socket,
           status: :invalid,
           changeset: User.valid_email_changeset()
         )}
    end
  end

  def handle_info({:delivered_email, _email}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_uri(socket), do: socket

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

  # data(status, :any)
  # data(changeset, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <p>Your account activation link is invalid or it has expired.</p>
      <p>Enter your email address and click resend to receive a new account activation link.</p>
      <.form id="confirm_token" :let={form} for={%{}} phx-submit="resend-token" >
        <.email_input form={form} field={:email} label_text={dgettext("eyra-user", "confirm.token.email.label")} />
        <Button.submit label={dgettext("eyra-account", "confirm.token.resend_button")} />
      </.form>
      </Area.content>
    </div>
    """
  end
end
