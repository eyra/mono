defmodule CoreWeb.User.ResetPassword do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias Surface.Components.Form
  alias Core.Accounts
  alias Core.Accounts.User
  alias EyraUI.Text.Title2
  alias EyraUI.Form.EmailInput
  alias EyraUI.Button.SubmitButton

  data(changeset, :any)

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(changeset: User.valid_email_changeset())}
  end

  @impl true
  def handle_event("reset-password", %{"user" => %{"email" => email}}, socket) do
    case User.valid_email_changeset(email) do
      %{valid?: true} ->
        # FIXME: Add lockout logic
        if user = Accounts.get_user_by_email(email) do
          # FIXME: Log suspicous behavior?
          Accounts.deliver_user_reset_password_instructions(
            user,
            &Routes.live_url(socket, CoreWeb.User.ResetPasswordToken, &1)
          )
        end

        {:noreply,
         put_flash(
           socket,
           :info,
           "If your email is in our system, you will receive instructions to reset your password shortly."
         )}

      changeset ->
        {:noreply,
         socket |> assign(changeset: changeset) |> put_flash(:error, "Invalid email address")}
    end
  end

  @impl true
  def handle_uri(socket), do: socket

  def render(assigns) do
    ~H"""
    <ContentArea>
      <MarginY id={{:page_top}} />
      <FormArea>
        <Title2>{{dgettext "eyra-user", "user.password_reset.title"}}</Title2>
        <Form for={{ @changeset }} submit="reset-password">
          <EmailInput field={{:email}} label_text={{dgettext("eyra-user", "password_reset.email.label")}} />
          <SubmitButton label={{ dgettext("eyra-user", "password_reset.reset_button") }} />
        </Form>
      </FormArea>
    </ContentArea>
    """
  end
end
