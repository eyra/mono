defmodule CoreWeb.User.Profile do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave

  alias Core
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.User.Forms.Profile, as: ProfileForm
  alias CoreWeb.User.Forms.Study, as: StudyForm
  alias CoreWeb.User.Forms.Features, as: FeaturesForm

  data(user_agent, :string, default: "")
  data(current_user, :any)

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil
      )
    }
  end

  @impl true
  def handle_event("reset_focus", _, socket) do
    send_update(ProfileForm, id: :profile_form, focus: "")
    {:noreply, socket}
  end

  def handle_info({:claim_focus, :profile_form}, socket) do
    # Profile is currently only form that can claim focus
    {:noreply, socket}
  end

  # defp save_valid(changeset) do
  #   user_profile_edit = Ecto.Changeset.apply_changes(changeset)
  #   user_attrs = UserProfileEdit.to_user(user_profile_edit)
  #   profile_attrs = UserProfileEdit.to_profile(user_profile_edit)

  #   user = Accounts.get_user!(user_profile_edit.user_id)

  #   Accounts.update_user_profile(user, user_attrs, profile_attrs)

  #   user_profile_edit
  # end

  # defp update_changeset(socket, changeset) do
  #   case Ecto.Changeset.apply_action(changeset, :update) do
  #     {:ok, _user_profile_edit} ->
  #       socket |> handle_success(changeset)

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       socket |> handle_validation_error(changeset)
  #   end
  # end

  # defp handle_validation_error(socket, changeset) do
  #   socket
  #   |> assign(changeset: changeset)
  #   |> put_flash(:error, dgettext("eyra-account", "photo.upload.error.flash"))
  # end

  # defp handle_success(socket, changeset) do
  #   user_profile_edit = save_valid(changeset)

  #   socket
  #   |> assign(
  #     user_profile_edit: user_profile_edit,
  #     changeset: changeset,
  #     save_changeset: changeset
  #   )
  #   |> AutoSave.put_saved_flash()
  #   |> AutoSave.schedule_hide_message()
  # end

  @impl true
  def render(assigns) do
    ~H"""
    <Workspace
      user={{@current_user}}
      user_agent={{ Browser.Ua.to_ua(@socket) }}
      active_item={{ :profile }}
    >
      <ProfileForm id={{ :profile_form }} user={{ @current_user }} />
      <StudyForm :if={{ @current_user.student }} id={{ :study_form }} user={{ @current_user }} />
      <FeaturesForm id={{ :features_form }} user={{ @current_user }} />
    </Workspace>
    """
  end
end
