defmodule LinkWeb.UserProfile.Index do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox}
  alias Link.Users
  alias EyraUI.Form.TextInput
  alias Ecto.Changeset

  @save_delay 2

  data current_user, :any
  data current_user_profile, :any
  data changeset, :any
  data saved, :boolean

  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile = Users.get_profile(user)
    changeset = Users.change_profile(profile)

    socket =
      socket
      |> assign(
        changeset: changeset,
        user_profile: profile,
        save_timer: nil
      )

    {:ok, socket}
  end

  defp cancel_save_timer(nil), do: nil
  defp cancel_save_timer(timer), do: Process.cancel_timer(timer)

  defp schedule_save(socket) do
    update_in(socket.assigns.save_timer, fn timer ->
      cancel_save_timer(timer)
      Process.send_after(self(), :save, @save_delay * 1_000)
    end)
  end

  def handle_event(
        "save",
        %{"profile" => user_profile_params},
        %{assigns: %{user_profile: user_profile}} = socket
      ) do
    changeset = Users.change_profile(user_profile, user_profile_params)

    case Changeset.apply_action(changeset, :update) do
      {:ok, user_profile} ->
        {:noreply,
         socket
         |> schedule_save()
         |> assign(
           changeset: changeset,
           save_changeset: changeset,
           user_profile: user_profile
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> put_flash(:error, "Please correct the indicated errors.")}
    end
  end

  def handle_info(:save, %{assigns: %{save_changeset: changeset}} = socket) do
    {:ok, user_profile} = Users.update_profile(changeset)

    {:noreply,
     socket
     |> assign(user_profile: user_profile)}
  end

  def terminate(_reason, %{assigns: %{changeset: changeset}}) do
    {:ok, _} = Users.update_profile(changeset)
    :ok
  end

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
                  <Checkbox field={{:researcher}} opts={{text: dgettext("eyra-account", "researcher.label")}}/>
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
