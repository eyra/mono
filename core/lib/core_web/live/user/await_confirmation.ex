defmodule CoreWeb.User.AwaitConfirmation do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :signup

  alias Core.Accounts
  alias Core.Accounts.User

  alias Frameworks.Pixel.Text

  def mount(_params, _session, socket) do
    require_feature(:password_sign_in)
    changeset = Accounts.change_user_registration(%User{})

    {:ok,
     socket
     |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event("signup", params, socket) do
    case Accounts.register_user(params) do
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
         |> put_flash(:info, dgettext("eyra-account", "account.created.info.flash"))
         |> push_redirect(to: Routes.live_path(socket, CoreWeb.User.ConfirmToken))}
    end
  end

  # data(changeset, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.stripped user={@current_user} menus={@menus}>
      <div>
        <Area.sheet>
        <Margin.y id={:page_top} />
          <div class="flex flex-col items-center">
            <Text.title2><%= dgettext("eyra-account", "await.confirmation.title") %></Text.title2>
            <Text.body><%= dgettext("eyra-account", "await.confirmation.description") %></Text.body>
          </div>
        </Area.sheet>
      </div>
    </.stripped>
    """
  end
end
