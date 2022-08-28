defmodule CoreWeb.User.Forms.Profile do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, ~w(.png .jpg .jpeg)

  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  alias Frameworks.Pixel.Text.{Title2}
  alias Frameworks.Pixel.Form.{Form, TextInput, PhotoInput}

  prop(props, :any, required: true)

  data(user, :any)
  data(entity, :any)
  data(uploads, :any)
  data(changeset, :any, default: nil)
  data(focus, :any, default: "")

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {local_relative_path, _local_full_path, _remote_file}
      ) do
    save(socket, entity, :auto_save, %{photo_url: local_relative_path})
  end

  # Handle Selector Update
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {:ok, socket |> save(entity, :auto_save, %{selector_id => active_item_ids})}
  end

  def update(%{id: id, props: %{user: user}}, socket) do
    profile = Accounts.get_profile(user)
    entity = UserProfileEdit.create(user, profile)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
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

  @impl true
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
    |> auto_save(changeset)
  end

  @impl true
  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <FormArea>
        <Title2>{dgettext("eyra-account", "profile.title")}</Title2>
        <Form id="main_form" changeset={@changeset} change_event="save" target={@myself} focus={@focus}>
          <PhotoInput
            static_path={&CoreWeb.Endpoint.static_path/1}
            photo_url={@entity.photo_url}
            uploads={@uploads}
            primary_button_text={dgettext("eyra-account", "choose.profile.photo.file")}
            secondary_button_text={dgettext("eyra-account", "choose.other.profile.photo.file")}
          />
          <Spacing value="M" />

          <TextInput field={:fullname} label_text={dgettext("eyra-account", "fullname.label")} />
          <TextInput field={:displayname} label_text={dgettext("eyra-account", "displayname.label")} />

          <div :if={@user.researcher}>
            <TextInput field={:title} label_text={dgettext("eyra-account", "professionaltitle.label")} />
          </div>
        </Form>
      </FormArea>
    </ContentArea>
    """
  end
end
