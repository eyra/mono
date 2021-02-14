defmodule LinkWeb.User.Signup do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view

  alias Surface.Components.Form
  alias EyraUI.Form.{EmailInput, PasswordInput}
  alias EyraUI.Button.{SubmitWideButton, LinkButton}
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Text.Title2

  alias Link.Users.User

  data changeset, :any

  def mount(_params, _session, socket) do
    changeset = get_changeset(%{})
    {:ok, socket |> assign(changeset: changeset)}
  end

  def get_changeset(params) do
    %User{}
    |> User.changeset(params)
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <FormArea>
          <Title2>{{dgettext "eyra-account", "signup.title"}}</Title2>
          <Form for={{@changeset}} action="/registration">
            <EmailInput field={{:email}} label_text={{dgettext("eyra-account", "email.label")}} />
            <PasswordInput field={{:password}} label_text={{dgettext("eyra-account", "password.label")}} />
            <PasswordInput field={{:password_confirmation}} label_text={{dgettext("eyra-account", "password.confirmation.label")}} />
            <SubmitWideButton label={{ dgettext("eyra-account", "signup.button") }} bg_color="bg-grey1" />
          </Form>
          <div class="mb-8" />
          {{ dgettext("eyra-account", "signin.label") }}
          <LinkButton label={{ dgettext("eyra-account", "signin.link") }} path={{Routes.live_path(@socket, LinkWeb.User.Signin)}} />
        </FormArea>
      </ContentArea>
    """
  end
end
