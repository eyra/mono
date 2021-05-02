defmodule CoreWeb.User.ResetPasswordToken do
  @moduledoc """
  The password reset token.
  """
  use CoreWeb, :live_view

  alias Surface.Components.Form
  alias Core.Accounts
  alias EyraUI.Form.PasswordInput
  alias EyraUI.Text.Title2
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Button.SubmitButton

  data(changeset, :any)

  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      {:ok,
       socket
       |> assign(:user, user)
       |> assign(:changeset, Accounts.change_user_password(user))}
    else
      {:ok,
       socket
       |> put_flash(:error, "Reset password link is invalid or it has expired.")
       |> redirect(to: Routes.live_path(socket, CoreWeb.User.ResetPassword))}
    end
  end

  def handle_event(
        "reset-password",
        %{"user" => password_params},
        %{assigns: %{user: user}} = socket
      ) do
    case Accounts.reset_user_password(user, password_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: Routes.user_session_path(socket, :new))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <ContentArea>
      <FormArea>
        <Title2>{{dgettext "eyra-user", "user.password_reset.title"}}</Title2>
        <Form for={{ @changeset }} submit="reset-password">
          <PasswordInput field={{:password}} label_text={{dgettext("eyra-user", "password_reset.password.label")}} />
          <PasswordInput field={{:password_confirmation}} label_text={{dgettext("eyra-user", "password_reset.password_confirmation.label")}} />
          <SubmitButton label={{ dgettext("eyra-user", "password_reset.reset_password_button") }} />
        </Form>
      </FormArea>
    </ContentArea>
    """
  end
end
