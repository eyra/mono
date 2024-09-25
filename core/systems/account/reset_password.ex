defmodule Systems.Account.ResetPassword do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus
  import Frameworks.Pixel.Form

  alias Systems.Account
  alias Systems.Account.User
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(changeset: User.valid_email_changeset(), active_menu_item: nil)
      |> update_menus()
    }
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  @impl true
  def handle_event("reset-password", %{"user" => %{"email" => email}}, socket) do
    case User.valid_email_changeset(email) do
      %{valid?: true} ->
        # FIXME: Add lockout logic
        if user = Account.Public.get_user_by_email(email) do
          # FIXME: Log suspicous behavior?
          Account.Public.deliver_user_reset_password_instructions(
            user,
            &url(socket, ~p"/user/reset-password/#{&1}")
          )
        end

        {
          :noreply,
          socket
          |> put_flash(:info, dgettext("eyra-user", "user.password_reset.flash"))
        }

      changeset ->
        {:noreply,
         socket |> assign(changeset: changeset) |> put_flash(:error, "Invalid email address")}
    end
  end

  # data(changeset, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.form>
        <Text.title2><%= dgettext("eyra-user", "user.password_reset.title") %></Text.title2>
        <.form id="reset_password" :let={form} for={@changeset} phx-submit="reset-password" data-show-errors={true} >
          <.email_input form={form} field={:email} label_text={dgettext("eyra-user", "password_reset.email.label")} />
          <Button.submit_wide label={dgettext("eyra-user", "password_reset.reset_button")} bg_color="bg-grey1" />
        </.form>
      </Area.form>
      </Area.content>
    </.stripped>
    """
  end
end
