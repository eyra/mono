defmodule CoreWeb.User.Profile do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use EyraUI.AutoSave, :user_profile_edit
  use CoreWeb.FileUploader

  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  alias EyraUI.Form.{Form, TextInput, Checkbox, UrlInput, PhotoInput}
  alias EyraUI.Text.{Title2}
  alias EyraUI.Spacing
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Button.{DeleteButton}

  @impl true
  def init(_params, _session, socket) do
    socket
    |> init_file_uploader(:photo)
  end

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
      user_profile_edit = save_valid(changeset)
      {:ok, user_profile_edit}
    else
      changeset = %{changeset | action: :save}
      {:error, changeset}
    end
  end

  @impl true
  def save_file(socket, uploaded_file) do
    attrs = %{photo_url: uploaded_file}
    user_profile_edit = socket.assigns[:user_profile_edit]
    changeset = get_changeset(user_profile_edit, :auto_save, attrs)
    update_changeset(socket, changeset)
  end

  defp save_valid(changeset) do
    user_profile_edit = Ecto.Changeset.apply_changes(changeset)
    user_attrs = UserProfileEdit.to_user(user_profile_edit)
    profile_attrs = UserProfileEdit.to_profile(user_profile_edit)

    user = Accounts.get_user!(user_profile_edit.user_id)

    Accounts.update_user_profile(user, user_attrs, profile_attrs)

    user_profile_edit
  end

  defp update_changeset(socket, changeset) do
    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, _user_profile_edit} ->
        socket |> handle_success(changeset)

      {:error, %Ecto.Changeset{} = changeset} ->
        socket |> handle_validation_error(changeset)
    end
  end

  defp handle_validation_error(socket, changeset) do
    socket
    |> assign(changeset: changeset)
    |> put_flash(:error, dgettext("eyra-account", "photo.upload.error.flash"))
  end

  defp handle_success(socket, changeset) do
    user_profile_edit = save_valid(changeset)

    socket
    |> assign(
      user_profile_edit: user_profile_edit,
      changeset: changeset,
      save_changeset: changeset
    )
    |> AutoSave.put_saved_flash()
    |> AutoSave.schedule_hide_message()
  end

  def handle_event("focus", %{"field" => field}, socket) do
    {
      :noreply,
      socket
      |> assign(:focus, field)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <ContentArea>
        <div x-data hidden>
          <h1 x-text="$store.push.registration"/>
          <p x-show="$store.push.registration === 'pending'">...</p>
          <button x-show="$store.push.registration === 'not-registered'" onclick="registerForPush()">Register for push</button>
          <p x-show="$store.push.registration === 'registered'">Registered for push</p>
          <p x-show="$store.push.registration === 'denied'">Apparently you don't want push</p>
        </div>
        <FormArea>
          <Title2>{{dgettext "eyra-account", "profile.title"}}</Title2>
          <Form id="main_form" changeset={{@changeset}} change_event="save" focus={{@focus}}>
            <PhotoInput
              conn={{@socket}}
              static_path={{&Routes.static_path/2}}
              photo_url={{@user_profile_edit.photo_url}}
              uploads={{@uploads}}
              primary_button_text={{dgettext("eyra-account", "choose.profile.photo.file")}}
              secondary_button_text={{dgettext("eyra-account", "choose.other.profile.photo.file")}}
            />
            <Spacing value="M" />

            <TextInput field={{:fullname}} label_text={{dgettext("eyra-account", "fullname.label")}} />
            <TextInput field={{:displayname}} label_text={{dgettext("eyra-account", "displayname.label")}} />
            <TextInput field={{:title}} label_text={{dgettext("eyra-account", "professionaltitle.label")}} />
            <UrlInput field={{:url}} label_text={{dgettext("eyra-account", "website.label")}} />

            <Spacing value="S" />
            <Checkbox field={{:researcher}} label_text={{dgettext("eyra-account", "researcher.label")}}/>
          </Form>
          <Spacing value="L" />
          <DeleteButton label={{ dgettext("eyra-account", "signout.button") }} path={{ Routes.user_session_path(@socket, :delete) }} />
        </FormArea>
      </ContentArea>
    """
  end
end
