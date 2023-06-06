defmodule CoreWeb.User.ResetPassword do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  alias CoreWeb.Router.Helpers, as: Routes

  import Frameworks.Pixel.Form

  alias Core.Accounts
  alias Core.Accounts.User
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

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

  # data(changeset, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.form>
        <Text.title2><%= dgettext("eyra-user", "user.password_reset.title") %></Text.title2>
        <.form id="reset_password" :let={form} for={@changeset} phx-submit="reset-password" >
          <.email_input form={form} field={:email} label_text={dgettext("eyra-user", "password_reset.email.label")} />
          <Button.submit label={dgettext("eyra-user", "password_reset.reset_button")} />
        </.form>
      </Area.form>
      </Area.content>
    </div>
    """
  end
end
