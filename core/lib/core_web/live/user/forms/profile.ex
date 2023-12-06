defmodule CoreWeb.User.Forms.Profile do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.png .jpg .jpeg)

  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Text

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {_path, photo_url, _original_filename}
      ) do
    save(socket, entity, :auto_save, %{photo_url: photo_url})
  end

  # Handle Selector Update
  @impl true
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {:ok, socket |> save(entity, :auto_save, %{selector_id => active_item_ids})}
  end

  @impl true
  def update(%{id: id, user: user}, socket) do
    profile = Accounts.get_profile(user)
    entity = UserProfileEdit.create(user, profile)

    signout_button = %{
      action: %{type: :http_delete, to: ~p"/user/session"},
      face: %{
        type: :secondary,
        label: dgettext("eyra-ui", "menu.item.signout"),
        border_color: "border-delete",
        text_color: "text-delete"
      }
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        user: user,
        entity: entity,
        signout_button: signout_button
      )
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

  attr(:user, :map, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.form>
        <Text.title2><%= dgettext("eyra-account", "profile.title")  %></Text.title2>
        <.form id="main_form" :let={form} for={@changeset} phx-submit="signup" phx-change="save" phx-target={@myself} >
          <.photo_input
            static_path={&CoreWeb.Endpoint.static_path/1}
            photo_url={@entity.photo_url}
            uploads={@uploads}
            primary_button_text={dgettext("eyra-account", "choose.profile.photo.file")}
            secondary_button_text={dgettext("eyra-account", "choose.other.profile.photo.file")}
          />
          <.spacing value="M" />

          <.text_input form={form} field={:fullname} label_text={dgettext("eyra-account", "fullname.label")} />
          <.text_input form={form} field={:displayname} label_text={dgettext("eyra-account", "displayname.label")} />

          <%= if @user.researcher do %>
            <.text_input form={form} field={:title} label_text={dgettext("eyra-account", "professionaltitle.label")} />
          <% end %>
        </.form>

        <.spacing value="S" />
        <.wrap>
          <Button.dynamic {@signout_button} />
        </.wrap>

      </Area.form>
      </Area.content>
    </div>
    """
  end
end
