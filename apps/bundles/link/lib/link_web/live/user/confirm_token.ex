defmodule LinkWeb.User.ConfirmToken do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view

  alias Surface.Components.Form
  alias EyraUI.Button.SubmitButton
  alias EyraUI.Container.ContentArea
  alias EyraUI.Form.EmailInput

  alias Link.Accounts
  alias Link.Accounts.User

  data(status, :any)
  data(changeset, :any)

  def mount(%{"token" => token}, _session, socket) do
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
              &Routes.live_url(socket, LinkWeb.User.ConfirmToken, &1)
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
    ~H"""
      <ContentArea>
        <p>Account confirmation link is invalid or it has expired.</p>
        <p>Enter your e-mail to resend the token</p>
        <Form for={{ @changeset }} submit="resend-token">
          <EmailInput field={{:email}} label_text={{dgettext("eyra-user", "confirm.token.email.label")}} />
          <SubmitButton label={{ dgettext("eyra-account", "confirm.token.resend_button") }} />
        </Form>
      </ContentArea>
    """
  end
end
