defmodule LinkWeb.UserProfile.Index do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  alias Surface.Components.Form
  alias Link.Users
  alias EyraUI.Form.{TextInput, Checkbox}
  use EyraUI.AutoSave, :profile
  alias EyraUI.Form.Title
  alias EyraUI.Container.SidebarAware
  alias EyraUI.Container.FormAware

  def load(_params, session, socket) do
    user = get_user(socket, session)
    Users.get_profile(user)
  end

  defdelegate get_changeset(profile, attrs \\ %{}), to: Users, as: :change_profile
  defdelegate save(changeset), to: Users, as: :update_profile

  def render(assigns) do
    ~H"""
    <SidebarAware>
      <FormAware>
        <Title text={{dgettext "eyra-account", "profile.title"}} />
        <Form for={{ @changeset }} change="save">
          <Checkbox field={{:researcher}} label_text={{dgettext("eyra-account", "researcher.label")}}/>
          <TextInput field={{:fullname}} label_text={{dgettext("eyra-account", "fullname.label")}} />
          <TextInput field={{:displayname}} label_text={{dgettext("eyra-account", "displayname.label")}} />
        </Form>
      </FormAware>
    </SidebarAware>
    """
  end
end
