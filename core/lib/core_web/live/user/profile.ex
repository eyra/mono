defmodule CoreWeb.User.Profile do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use EyraUI.AutoSave, :user_profile_edit

  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  alias EyraUI.Form.{Form, TextInput, Checkbox}
  alias EyraUI.Text.Title2
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Button.DeleteButton

  @impl true
  def load(_params, _session, %{assigns: %{current_user: user}}) do
    profile = Accounts.get_profile(user)
    UserProfileEdit.create(user, profile)
  end

  @impl true
  defdelegate get_changeset(survey_tool, type, attrs \\ %{}), to: UserProfileEdit, as: :changeset

  @impl true
  def save(changeset) do
    if changeset.valid? do
      save_valid(changeset)
    else
      changeset = %{changeset | action: :save}
      {:error, changeset}
    end
  end

  def save_valid(changeset) do
    user_profile_edit = Ecto.Changeset.apply_changes(changeset)
    user_attrs = UserProfileEdit.to_user(user_profile_edit)
    profile_attrs = UserProfileEdit.to_profile(user_profile_edit)

    user = Accounts.get_user!(user_profile_edit.user_id)

    Accounts.update_user_profile(user, user_attrs, profile_attrs)

    {:ok, user_profile_edit}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <ContentArea>
      <FormArea>
        <Title2>{{dgettext "eyra-account", "profile.title"}}</Title2>
        <Form changeset={{@changeset}} change_event="save" focus={{@focus}}>
          <Checkbox field={{:researcher}} label_text={{dgettext("eyra-account", "researcher.label")}}/>
          <TextInput field={{:fullname}} label_text={{dgettext("eyra-account", "fullname.label")}} />
          <TextInput field={{:displayname}} label_text={{dgettext("eyra-account", "displayname.label")}} />
        </Form>
        <DeleteButton label={{ dgettext("eyra-account", "signout.button") }} path={{ Routes.user_session_path(@socket, :delete) }} />
      </FormArea>
    </ContentArea>
    """
  end
end
