defmodule LinkWeb.User.AwaitConfirmation do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view

  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.Title2

  alias Link.Accounts
  alias Link.Accounts.User

  data changeset, :any

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    {:ok, socket |> assign(changeset: changeset)}
  end

  def handle_event("signup", params, socket) do
    case Accounts.register_user(params) do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.live_url(socket, LinkWeb.User.ConfirmToken, &1)
          )

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully.")
         |> push_redirect(to: Routes.live_path(socket, LinkWeb.User.ConfirmToken))}
    end
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <Title2>{{dgettext "eyra-account", "await.confirmation.title"}}</Title2>
        <p>Please check your e-mail for a confirmation link.</p>
      </ContentArea>
    """
  end
end
