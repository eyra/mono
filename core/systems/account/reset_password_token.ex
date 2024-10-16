defmodule Systems.Account.ResetPasswordToken do
  @moduledoc """
  The password reset token.
  """
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({Frameworks.Fabric.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus
  import Frameworks.Pixel.Form

  alias Systems.Account
  alias Frameworks.Pixel.Button

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if user = Account.Public.get_user_by_reset_password_token(token) do
      {
        :ok,
        socket
        |> assign(:user, user)
        |> assign(:active_menu_item, nil)
        |> assign(:changeset, Account.Public.change_user_password(user))
        |> update_menus()
      }
    else
      {
        :ok,
        socket
        |> put_flash(:error, "Reset password link is invalid or it has expired.")
        |> redirect(to: ~p"/user/reset-password")
      }
    end
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  @impl true
  def handle_event(
        "reset-password",
        %{"user" => password_params},
        %{assigns: %{user: user}} = socket
      ) do
    case Account.Public.reset_user_password(user, password_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("eyra-user", "password.reset.successfully"))
         |> redirect(to: ~p"/user/signin")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <Area.form>
          <Text.title2><%= dgettext("eyra-user", "user.password_reset.title") %></Text.title2>
          <div id="reset_password_token_content" phx-hook="LiveContent" data-show-errors={true}>
            <.form id="reset_password_token" :let={form} for={@changeset} phx-submit="reset-password" >
              <.password_input
                form={form}
                field={:password}
                label_text={dgettext("eyra-user", "password_reset.password.label")}
                reserve_error_space={false}
              />
              <.spacing value="S" />
              <.password_input
                form={form}
                field={:password_confirmation}
                label_text={dgettext("eyra-user", "password_reset.password_confirmation.label")}
                reserve_error_space={false}
              />
              <.spacing value="S" />
              <Button.submit_wide label={dgettext("eyra-user", "password_reset.reset_password_button")} bg_color="bg-grey1" />
            </.form>
          </div>
        </Area.form>
      </Area.content>
    </.stripped>
    """
  end
end
