defmodule CoreWeb.User.Signup do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :onboarding

  alias CoreWeb.User.Form
  alias CoreWeb.Router.Helpers, as: Routes

  alias Core.Accounts
  alias Core.Accounts.User

  def mount(_params, _session, socket) do
    require_feature(:password_sign_in)
    changeset = Accounts.change_user_registration(%User{})

    {:ok,
     socket
     |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event("signup", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.live_url(socket, CoreWeb.User.ConfirmToken, &1)
          )

        {:noreply,
         socket
         |> put_flash(:info, dgettext("eyra-user", "account.created.successfully"))
         |> push_redirect(to: Routes.live_path(socket, CoreWeb.User.AwaitConfirmation))}
    end
  end

  @impl true
  def handle_event("form_change", %{"user" => attrs}, socket) do
    changeset = Accounts.change_user_registration(%User{}, attrs)
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
          <Form.password_signup changeset={@changeset} />
        </Area.form>
        </Area.content>
      </div>
    </.stripped>
    """
  end
end
