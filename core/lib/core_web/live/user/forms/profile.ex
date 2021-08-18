defmodule CoreWeb.User.Forms.Profile do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader

  import CoreWeb.Gettext

  alias Core.Enums.StudyProgramCodes
  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  alias EyraUI.Spacing
  alias EyraUI.Text.{Title2}
  alias EyraUI.Form.{Form, TextInput, UrlInput, PhotoInput}
  alias EyraUI.Container.{ContentArea, FormArea}

  prop(user, :any, required: true)

  data(entity, :any)
  data(study_labels, :any)
  data(uploads, :any)
  data(changeset, :any)
  data(focus, :any, default: "")

  @impl true
  def save_file(%{assigns: %{entity: entity}} = socket, uploaded_file) do
    save(socket, entity, :auto_save, %{photo_url: uploaded_file})
  end

  # Handle Selector Update
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {:ok, socket |> save(entity, :auto_save, %{selector_id => active_item_ids})}
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {:ok, socket}
  end

  def update(%{id: id, user: user}, socket) do
    profile = Accounts.get_profile(user)
    entity = UserProfileEdit.create(user, profile)

    study_labels = StudyProgramCodes.labels([])

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
      |> assign(study_labels: study_labels)
      |> init_file_uploader(:photo)
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{entity: entity}} = socket) do
    update_ui(socket, entity)
  end

  defp update_ui(socket, entity) do
    changeset = UserProfileEdit.changeset(entity, :mount, %{})

    socket
    |> assign(changeset: changeset)
  end

  # Saving

  def handle_event(
        "save",
        %{"user_profile_edit" => attrs},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
      |> update_ui()
    }
  end

  def save(socket, %Core.Accounts.UserProfileEdit{} = entity, type, attrs) do
    changeset = UserProfileEdit.changeset(entity, type, attrs)

    socket
    |> schedule_save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
        <ContentArea top_padding="pt-6 sm:pt-14">
        <FormArea>
          <Title2>{{dgettext "eyra-account", "profile.title"}}</Title2>
          <Form id="main_form" changeset={{@changeset}} change_event="save" target={{@myself}} focus={{@focus}}>
            <PhotoInput
              conn={{@socket}}
              static_path={{&Routes.static_path/2}}
              photo_url={{@entity.photo_url}}
              uploads={{@uploads}}
              primary_button_text={{dgettext("eyra-account", "choose.profile.photo.file")}}
              secondary_button_text={{dgettext("eyra-account", "choose.other.profile.photo.file")}}
            />
            <Spacing value="M" />

            <TextInput field={{:fullname}} label_text={{dgettext("eyra-account", "fullname.label")}} target={{@myself}} />
            <TextInput field={{:displayname}} label_text={{dgettext("eyra-account", "displayname.label")}} target={{@myself}} />

            <div :if={{@user.researcher}} >
              <TextInput field={{:title}} label_text={{dgettext("eyra-account", "professionaltitle.label")}} target={{@myself}} />
              <UrlInput field={{:url}} label_text={{dgettext("eyra-account", "website.label")}} target={{@myself}} />
            </div>
          </Form>
        </FormArea>
      </ContentArea>
    """
  end
end
