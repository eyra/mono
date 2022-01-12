defmodule CoreWeb.User.ConfirmToken do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias Surface.Components.Form
  alias Frameworks.Pixel.Button.SubmitButton
  alias Frameworks.Pixel.Form.EmailInput

  alias Core.Accounts
  alias Core.Accounts.User

  data(status, :any)
  data(changeset, :any)

  def mount(%{"token" => token}, _session, socket) do
    require_feature(:password_sign_in)

    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:ok,
         socket
         |> put_flash(:info, "Account confirmed successfully.")
         |> redirect(to: Routes.user_session_path(socket, :new))}

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
              Routes.user_session_url(socket, :new)
            )
        end

        {:noreply,
         put_flash(
           socket,
           :info,
           "If your email is in our system and it has not been confirmed yet, " <>
             "you will receive an email with instructions shortly."
         )}

      changeset ->
        {:noreply,
         socket |> assign(changeset: changeset) |> put_flash(:error, "Invalid email address")}
    end
  end

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <p>Account confirmation link is invalid or it has expired.</p>
        <p>Enter your e-mail to resend the token</p>
        <Form for={@changeset} submit="resend-token">
          <EmailInput field={:email} label_text={dgettext("eyra-user", "confirm.token.email.label")} />
          <SubmitButton label={dgettext("eyra-account", "confirm.token.resend_button")} />
        </Form>
      </ContentArea>
    """
  end
end
