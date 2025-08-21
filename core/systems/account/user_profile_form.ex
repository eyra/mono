defmodule Systems.Account.UserProfileForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.png .jpg .jpeg)

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Text
  alias Systems.Account

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        %{photo_url: photo_url}
      ) do
    save(socket, entity, :auto_save, %{photo_url: photo_url})
  end

  @impl true
  def update(
        %{active_item_ids: active_item_ids, source: %{name: field}},
        %{assigns: %{entity: entity}} = socket
      ) do
    {:ok, socket |> save(entity, :auto_save, %{field => active_item_ids})}
  end

  @impl true
  def update(%{id: id, user: user}, socket) do
    profile = Account.Public.get_profile(user)
    entity = Account.UserProfileEditModel.create(user, profile)

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
        signout_button: signout_button,
        show_errors: false
      )
      |> init_file_uploader(:photo)
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{entity: entity}} = socket) do
    update_ui(socket, entity)
  end

  defp update_ui(socket, entity) do
    changeset = Account.UserProfileEditModel.changeset(entity, :mount, %{})

    socket
    |> assign(changeset: changeset)
  end

  @impl true
  def handle_event(
        "save",
        %{"user_profile_edit_model" => attrs},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
      |> update_ui()
    }
  end

  def save(socket, %Account.UserProfileEditModel{} = entity, type, attrs) do
    changeset = Account.UserProfileEditModel.changeset(entity, type, attrs)

    socket
    |> auto_save(changeset)
  end

  attr(:user, :map, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.form>
        <Text.title2><%= dgettext("eyra-account", "profile.tab.profile.title")  %></Text.title2>
        <div id="user_profile_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
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

            <%= if @user.creator do %>
              <.text_input form={form} field={:title} label_text={dgettext("eyra-account", "professionaltitle.label")} />
            <% end %>

            <Text.form_field_label id={:user_email_label}>
              <%= dgettext("eyra-account", "email.label") %>
            </Text.form_field_label>
            <div class="text-grey1 text-bodymedium font-body">
              <%= @user.email %>
            </div>

          </.form>
        </div>
        <.spacing value="M" />
        <.wrap>
          <Button.dynamic {@signout_button} />
        </.wrap>
      </Area.form>
    </div>
    """
  end
end
