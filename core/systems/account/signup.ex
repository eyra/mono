defmodule Systems.Account.Signup do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer

  alias Systems.Account
  alias Systems.Account.UserForm
  alias Systems.Account.User

  def mount(_params, _session, socket) do
    require_feature(:password_sign_in)
    changeset = Account.Public.change_user_registration(%User{})

    {:ok,
     socket
     |> assign(changeset: changeset, active_menu_item: nil)
     |> update_menus()}
  end

  @impl true
  def handle_event("signup", %{"user" => user_params}, socket) do
    # See:
    # Apply temp: https://github.com/eyra/mono/issues/558
    # Revert: https://github.com/eyra/mono/issues/563

    user_params = Map.put(user_params, "researcher", true)

    case Account.Public.register_user(user_params) do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:ok, user} ->
        {:ok, _} =
          Account.Public.deliver_user_confirmation_instructions(
            user,
            &url(socket, ~p"/user/confirm/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(:info, dgettext("eyra-user", "account.created.successfully"))
         |> push_redirect(to: ~p"/user/await-confirmation")}
    end
  end

  @impl true
  def handle_event("form_change", %{"user" => attrs}, socket) do
    changeset = Account.Public.change_user_registration(%User{}, attrs)
    {:noreply, socket |> assign(changeset: changeset)}
  end

  # data(changeset, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div id="signup_content" phx-hook="LiveContent" data-show-errors={true}>
        <Area.content>
        <Margin.y id={:page_top} />
        <Area.form>
          <Text.title2><%= dgettext("eyra-account", "signup.title") %></Text.title2>
          <UserForm.password_signup changeset={@changeset} />
        </Area.form>
        </Area.content>
      </div>
    </.stripped>
    """
  end
end
