defmodule CoreWeb.User.Signup do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  alias CoreWeb.Router.Helpers, as: Routes

  alias Surface.Components.Form
  alias Frameworks.Pixel.Form.{EmailInput, PasswordInput}
  alias Frameworks.Pixel.Button.{SubmitWideButton, LinkButton}
  alias Frameworks.Pixel.Text.Title2

  alias Core.Accounts
  alias Core.Accounts.User

  data(changeset, :any)
  data(focus, :string, default: "")

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
  def handle_event("focus", %{"field" => field}, socket) do
    {
      :noreply,
      socket
      |> assign(focus: field)
    }
  end

  @impl true
  def handle_uri(socket), do: socket

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <FormArea>
          <Title2>{dgettext "eyra-account", "signup.title"}</Title2>
          <div x-data={"{ focus: '#{@focus}' }"}>
            <Form for={@changeset} submit="signup" change="form_change">
              <EmailInput field={:email} label_text={dgettext("eyra-account", "email.label")} />
              <PasswordInput field={:password} label_text={dgettext("eyra-account", "password.label")} />
              <SubmitWideButton label={dgettext("eyra-account", "signup.button")} bg_color="bg-grey1" />
            </Form>
          </div>
          <div class="mb-8" />
          {dgettext("eyra-account", "signin.label")}
          <LinkButton label={dgettext("eyra-account", "signin.link")} path={Routes.user_session_path(@socket, :new)} />
        </FormArea>
      </ContentArea>
    """
  end
end
