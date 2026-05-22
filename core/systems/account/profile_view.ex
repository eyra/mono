defmodule Systems.Account.ProfileView do
  @moduledoc """
  Embedded LiveView for editing user profile (name, photo, etc.).
  Used in both UserProfilePage (as a tab) and OnboardingPage (as a step).
  """
  use CoreWeb, :embedded_live_view
  use CoreWeb.FileUploader, accept: ~w(.png .jpg .jpeg)

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Systems.Account

  def dependencies(), do: [:user_id, :show_signout_button, :show_email]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{user_id: user_id}}) do
    user = Account.Public.get_user!(user_id)
    profile = Account.Public.get_profile(user)
    Account.UserProfileEditModel.create(user, profile)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, %{assigns: %{user_id: user_id}} = socket) do
    user = Account.Public.get_user!(user_id)

    {:ok,
     socket
     |> assign(user: user, show_errors: false)
     |> init_file_uploader(:photo)}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  # FileUploader callback
  @impl true
  def process_file(%{assigns: %{model: entity}} = socket, %{public_url: public_url}) do
    save(socket, entity, :auto_save, %{photo_url: public_url})
  end

  @impl true
  def handle_event(
        "save",
        %{"user_profile_edit_model" => attrs},
        %{assigns: %{model: entity}} = socket
      ) do
    {:noreply, save(socket, entity, :auto_save, attrs)}
  end

  defp save(socket, %Account.UserProfileEditModel{} = entity, type, attrs) do
    changeset = Account.UserProfileEditModel.changeset(entity, type, attrs)

    case Core.Persister.save(entity, changeset) do
      {:ok, updated_entity} ->
        socket
        |> assign(model: updated_entity)
        |> update_view_model()
        |> Flash.push_info(dgettext("eyra-ui", "persister.saved.flash"))

      {:error, changeset} ->
        socket
        |> assign_vm_field(:changeset, changeset)
        |> Flash.push_error(dgettext("eyra-ui", "persister.error.flash"))
    end
  end

  defp assign_vm_field(%{assigns: %{vm: vm}} = socket, key, value) do
    assign(socket, :vm, Map.put(vm, key, value))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="profile-view">
      <Area.form>
        <Text.title2><%= @vm.title %></Text.title2>
        <div id="user_profile_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
          <.form id="main_form" :let={form} for={@vm.changeset} phx-submit="save" phx-change="save">
            <.photo_input
              static_path={&CoreWeb.Endpoint.static_path/1}
              photo_url={@vm.photo_url}
              uploads={@uploads}
              primary_button_text={@vm.choose_photo_text}
              secondary_button_text={@vm.choose_other_photo_text}
            />
            <.spacing value="M" />

            <.text_input form={form} field={:fullname} label_text={@vm.fullname_label} />
            <.text_input form={form} field={:displayname} label_text={@vm.displayname_label} />

            <%= if @vm.user.creator do %>
              <.text_input form={form} field={:title} label_text={@vm.title_label} />
            <% end %>

            <%= if @vm.show_email do %>
              <Text.form_field_label id={:user_email_label}>
                <%= @vm.email_label %>
              </Text.form_field_label>
              <div class="text-grey1 text-bodymedium font-body">
                <%= @vm.user.email %>
              </div>
            <% end %>
          </.form>
        </div>
        <%= if @vm.signout_button do %>
          <.spacing value="M" />
          <.wrap>
            <Button.dynamic {@vm.signout_button} />
          </.wrap>
        <% end %>
      </Area.form>
    </div>
    """
  end
end
