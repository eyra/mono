defmodule CoreWeb.User.Signup do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias Surface.Components.Form
  alias EyraUI.Form.{EmailInput, PasswordInput}
  alias EyraUI.Button.{SubmitWideButton, LinkButton}
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Text.Title2

  alias Core.Accounts
  alias Core.Accounts.User

  data(changeset, :any)
  data(focus, :any, default: "")

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    {:ok,
     socket
     |> assign(changeset: changeset)}
  end

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

  def handle_event("focus", %{"field" => field}, socket) do
    {
      :noreply,
      socket
      |> assign(:focus, field)
    }
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <FormArea>
          <Title2>{{dgettext "eyra-account", "signup.title"}}</Title2>
          <Form for={{@changeset}} submit="signup" focus={{@focus}}>
            <EmailInput field={{:email}} label_text={{dgettext("eyra-account", "email.label")}} />
            <PasswordInput field={{:password}} label_text={{dgettext("eyra-account", "password.label")}} />
            <SubmitWideButton label={{ dgettext("eyra-account", "signup.button") }} bg_color="bg-grey1" />
          </Form>
          <div class="mb-8" />
          {{ dgettext("eyra-account", "signin.label") }}
          <LinkButton label={{ dgettext("eyra-account", "signin.link") }} path={{Routes.user_session_path(@socket, :new)}} />
        </FormArea>
      </ContentArea>
    """
  end
end
