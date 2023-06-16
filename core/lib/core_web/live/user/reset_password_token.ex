defmodule CoreWeb.User.ResetPasswordToken do
  @moduledoc """
  The password reset token.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :signup

  import Frameworks.Pixel.Form

  alias Core.Accounts
  alias Frameworks.Pixel.Button

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

  @impl true
  def handle_event(
        "reset-password",
        %{"user" => password_params},
        %{assigns: %{user: user}} = socket
      ) do
    case Accounts.reset_user_password(user, password_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("eyra-user", "password.reset.successfully"))
         |> redirect(to: ~p"/user/signin")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # data(changeset, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.stripped user={@current_user} menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <Area.form>
          <Text.title2><%= dgettext("eyra-user", "user.password_reset.title") %></Text.title2>
          <.form id="reset_password_token" :let={form} for={@changeset} phx-submit="reset-password" data-show-errors={true} >
            <.password_input
              form={form}
              field={:password}
              label_text={dgettext("eyra-user", "password_reset.password.label")}
            />
            <.password_input
              form={form}
              field={:password_confirmation}
              label_text={dgettext("eyra-user", "password_reset.password_confirmation.label")}
            />
            <Button.submit_wide label={dgettext("eyra-user", "password_reset.reset_password_button")} bg_color="bg-grey1" />
          </.form>
        </Area.form>
      </Area.content>
    </.stripped>
    """
  end
end
