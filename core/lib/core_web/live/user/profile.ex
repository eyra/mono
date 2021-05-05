defmodule CoreWeb.User.Profile do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use EyraUI.AutoSave, :user_profile_edit

  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  alias EyraUI.Form.{Form, TextInput, Checkbox}
  alias EyraUI.Text.{Title2, Title6}
  alias EyraUI.{Spacing, ImagePreview}
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Button.{DeleteButton, PrimaryLabelButton, SecondaryLabelButton}
  alias EyraUI.Case.{Case, True, False}

  @impl true
  def init(_params, _session, socket) do
    socket
    |> allow_upload(:photo,
      accept: ~w(.png .jpg .jpeg),
      progress: &handle_progress/3,
      auto_upload: true
    )
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

  defp save_valid(changeset) do
    user_profile_edit = Ecto.Changeset.apply_changes(changeset)
    user_attrs = UserProfileEdit.to_user(user_profile_edit)
    profile_attrs = UserProfileEdit.to_profile(user_profile_edit)

    user = Accounts.get_user!(user_profile_edit.user_id)

    Accounts.update_user_profile(user, user_attrs, profile_attrs)

    user_profile_edit
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp handle_progress(:photo, entry, socket) do
    if entry.done? do
      uploaded_file =
        socket
        |> consume_photo(entry)

      socket |> save_photo(uploaded_file)
    else
      {:noreply, socket}
    end
  end

  defp consume_photo(socket, entry) do
    consume_uploaded_entry(socket, entry, fn %{path: path} ->
      file = "#{entry.uuid}.#{ext(entry)}"
      dest = Path.join("priv/static/images/uploads", file)
      File.cp!(path, dest)
      Routes.static_path(socket, "/images/uploads/#{file}")
    end)
  end

  defp save_photo(socket, uploaded_file) do
    attrs = %{photo_url: uploaded_file}
    user_profile_edit = socket.assigns[:user_profile_edit]
    changeset = get_changeset(user_profile_edit, :auto_save, attrs)
    update_changeset(socket, changeset)
  end

  defp update_changeset(socket, changeset) do
    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, _user_profile_edit} ->
        handle_success(socket, changeset)

      {:error, %Ecto.Changeset{} = changeset} ->
        handle_validation_error(socket, changeset)
    end
  end

  defp handle_validation_error(socket, changeset) do
    {
      :noreply,
      socket
      |> assign(changeset: changeset)
      |> put_flash(:error, dgettext("eyra-account", "photo.upload.error.flash"))
    }
  end

  defp handle_success(socket, changeset) do
    user_profile_edit = save_valid(changeset)

    socket =
      socket
      |> assign(
        user_profile_edit: user_profile_edit,
        changeset: changeset,
        save_changeset: changeset
      )

    {
      :noreply,
      socket
      |> assign(user_profile_edit: user_profile_edit)
      |> AutoSave.put_saved_flash()
      |> AutoSave.schedule_hide_message()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <ContentArea>
        <FormArea>
            <Title2>{{dgettext "eyra-account", "profile.title"}}</Title2>
          <Form changeset={{@changeset}} change_event="save" focus={{@focus}}>
            <TextInput field={{:fullname}} label_text={{dgettext("eyra-account", "fullname.label")}} />
            <TextInput field={{:displayname}} label_text={{dgettext("eyra-account", "displayname.label")}} />
            <Title6>{{dgettext("eyra-account", "photo.label")}}</Title6>
            <div class="flex flex-row items-center">
              <ImagePreview
                image_url={{ @user_profile_edit.photo_url }}
                placeholder={{ Routes.static_path(@socket, "/images/profile_photo_default.svg") }}
                shape="w-image-preview-circle h-image-preview-circle rounded-full" />
              <Spacing value="S" direction="l" />
              <div class="flex-wrap">
                <Case value={{@user_profile_edit.photo_url}} >
                  <True>
                    <SecondaryLabelButton label={{dgettext("eyra-account", "choose.other.profile.photo.file")}} field={{ @uploads.photo.ref }}/>
                  </True>
                  <False>
                    <PrimaryLabelButton label={{dgettext("eyra-account", "choose.profile.photo.file")}} field={{ @uploads.photo.ref }}/>
                  </False>
                </Case>
                {{ live_file_input @uploads.photo, class: "hidden" }}
              </div>
            </div>
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
