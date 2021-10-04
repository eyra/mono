defmodule CoreWeb.User.AwaitConfirmation do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias EyraUI.Text.Title2

  alias Core.Accounts
  alias Core.Accounts.User

  data(changeset, :any)

  def mount(_params, _session, socket) do
    require_feature(:password_sign_in)
    changeset = Accounts.change_user_registration(%User{})

    {:ok,
     socket
     |> assign(changeset: changeset)}
  end

  @impl true
  def handle_uri(socket), do: socket

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
         |> put_flash(:info, "User created successfully.")
         |> push_redirect(to: Routes.live_path(socket, CoreWeb.User.ConfirmToken))}
    end
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Title2>{{dgettext "eyra-account", "await.confirmation.title"}}</Title2>
        <p>Please check your e-mail for a confirmation link.</p>
      </ContentArea>
    """
  end
end
