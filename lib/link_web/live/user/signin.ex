defmodule LinkWeb.User.Signin do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view

  alias Surface.Components.Form
  alias EyraUI.Form.{EmailInput, PasswordInput}
  alias EyraUI.Button.{SubmitWideButton, LinkButton, PrimaryIconButton}
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Text.{Title2, Caption}
  alias EyraUI.Line

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
          <Title2>{{dgettext "eyra-account", "eyra.signin.title"}}</Title2>
          <div class="mb-6"/>
          <PrimaryIconButton label={{ dgettext("eyra-account", "google.button") }} path="/auth/google/new" icon={{Routes.static_path(@socket, "/images/google.svg")}} bg_color="bg-google" />
          <div class="mb-6"/>
          <PrimaryIconButton label={{ dgettext("eyra-account", "apple.button") }} path="/auth/google/new" icon={{Routes.static_path(@socket, "/images/apple.svg")}} bg_color="bg-apple" />
          <div class="mb-6"/>
          <Caption>{{dgettext("eyra-account", "eyra.signin.message.external")}}</Caption>
          <Line />
          <Form for={{@changeset}} action="/session">
            <EmailInput field={{:email}} label_text={{dgettext("eyra-account", "email.label")}} />
            <PasswordInput field={{:password}} label_text={{dgettext("eyra-account", "password.label")}} />
            <SubmitWideButton label={{ dgettext("eyra-account", "signin.button") }} bg_color="bg-grey1" />
          </Form>
          <div class="mb-8" />
          {{ dgettext("eyra-account", "signup.label") }}
          <LinkButton label={{ dgettext("eyra-account", "signup.link") }} path={{Routes.live_path(@socket, LinkWeb.User.Signup)}} />
        </FormArea>
      </ContentArea>
    """
  end
end
