defmodule LinkWeb.UserProfile.Index do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  alias Surface.Components.Form
  alias Link.Users
  alias EyraUI.Form.{TextInput, Checkbox}
  use EyraUI.AutoSave, :profile
  alias EyraUI.Text.Title2
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Button.DeleteButton

  def load(_params, session, socket) do
    user = get_user(socket, session)
    Users.get_profile(user)
  end

  defdelegate get_changeset(profile, attrs \\ %{}), to: Users, as: :change_profile
  defdelegate save(changeset), to: Users, as: :update_profile

  def render(assigns) do
    ~H"""
    <ContentArea>
      <FormArea>
        <Title2>{{dgettext "eyra-account", "profile.title"}}</Title2>
        <Form for={{ @changeset }} change="save">
          <Checkbox field={{:researcher}} label_text={{dgettext("eyra-account", "researcher.label")}}/>
          <TextInput field={{:fullname}} label_text={{dgettext("eyra-account", "fullname.label")}} />
          <TextInput field={{:displayname}} label_text={{dgettext("eyra-account", "displayname.label")}} />
        </Form>
        <DeleteButton label={{ dgettext("eyra-account", "signout.button") }} path={{ Routes.pow_session_path(@socket, :delete) }} />
      </FormArea>
    </ContentArea>
    """
  end
end
