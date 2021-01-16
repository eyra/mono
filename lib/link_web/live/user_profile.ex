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

  def load(_params, session, socket) do
    user = get_user(socket, session)
    Users.get_profile(user)
  end

  defdelegate get_changeset(profile, attrs \\ %{}), to: Users, as: :change_profile
  defdelegate save(changeset), to: Users, as: :update_profile

  def render(assigns) do
    ~H"""
    <div class="flex w-full">
      <div class="flex-grow">
        <div class="w-full">
          <div class="flex justify-center">
            <div class="flex-grow max-w-form ml-6 mr-6 lg:m-0 mt-6 sm:mt-16 lg:mt-24">
              <div class="mb-6 text-title5 font-title5 lg:text-title2 lg:font-title2">
                {{ dgettext "eyra-account", "profile.title" }}
              </div>
              <div>
                <Form for={{ @changeset }} change="save">
                  <Checkbox field={{:researcher}} label_text={{dgettext("eyra-account", "researcher.label")}}/>
                  <TextInput field={{:fullname}} label_text={{dgettext("eyra-account", "fullname.label")}} />
                  <TextInput field={{:displayname}} label_text={{dgettext("eyra-account", "displayname.label")}} />
                </Form>
              <div>
              </div>
              </div>
            </div>
          </div>
        </div>
        <div class="flex-wrap w-0 sm:w-sidebar"></div>
      </div>
    </div>
    """
  end
end
