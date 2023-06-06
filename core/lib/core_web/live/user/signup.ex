defmodule CoreWeb.User.Signup do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  alias CoreWeb.Router.Helpers, as: Routes

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

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
         |> put_flash(:info, "User created successfully.")
         |> push_redirect(to: Routes.live_path(socket, CoreWeb.User.AwaitConfirmation))}
    end
  end

  @impl true
  def handle_event("form_change", %{"user" => attrs}, socket) do
    changeset = Accounts.change_user_registration(%User{}, attrs)
    {:noreply, socket |> assign(changeset: changeset)}
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
        <Text.title2><%= dgettext("eyra-account", "signup.title") %></Text.title2>
        <div>
          <.form id="signup" :let={form} for={@changeset} phx-submit="signup" phx-change="form_change" >
            <.email_input form={form} field={:email} label_text={dgettext("eyra-account", "email.label")} />
            <.password_input form={form} field={:password} label_text={dgettext("eyra-account", "password.label")} />
            <Button.submit_wide label={dgettext("eyra-account", "signup.button")} bg_color="bg-grey1" />
          </.form>
        </div>
        <div class="mb-8" />
        <%= dgettext("eyra-account", "signin.label") %>
        <Button.link
          label={dgettext("eyra-account", "signin.link")}
          path={~p"/user/signin"}
        />
      </Area.form>
      </Area.content>
    </div>
    """
  end
end
