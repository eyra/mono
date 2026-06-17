defmodule Systems.Account.FeaturesView do
  @moduledoc """
  Embedded LiveView for editing user features (gender, birth_year).
  Used in both UserProfilePage (as a tab) and OnboardingPage (as a step).
  """
  use CoreWeb, :embedded_live_view

  import Frameworks.Pixel.Form
  import LiveNest.HTML

  alias Frameworks.Pixel.Text
  alias Systems.Account

  def dependencies(), do: [:user_id]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{user_id: user_id}}) do
    user = Account.Public.get_user!(user_id)
    Account.Public.get_features(user)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  # Handle gender selector events (sent via send() from Selector component)
  @impl true
  def handle_info(
        {"active_item_id", %{active_item_id: active_item_id}},
        %{assigns: %{model: features}} = socket
      ) do
    {:noreply, save_features(socket, features, %{"gender" => active_item_id})}
  end

  @impl true
  def handle_event(
        event,
        %{"features_model" => attrs},
        %{assigns: %{model: features}} = socket
      )
      when event in ["change", "submit"] do
    {:noreply, save_features(socket, features, attrs)}
  end

  defp save_features(socket, features, attrs) do
    changeset = Account.FeaturesModel.changeset(features, :auto_save, attrs)

    case Core.Persister.save(features, changeset) do
      {:ok, updated_features} ->
        socket
        |> assign(model: updated_features)
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
    <div data-testid="features-view">
      <Area.form>
        <Text.title2><%= @vm.title %></Text.title2>
        <Text.body_medium><%= @vm.description %></Text.body_medium>

        <.spacing value="XL" />

        <Text.title3><%= @vm.gender_title %></Text.title3>
        <.element {Map.from_struct(@vm.gender_selector)} socket={@socket} />

        <.spacing value="XL" />

        <Text.title3><%= @vm.birth_year_title %></Text.title3>
        <.spacing value="S" />
        <.form :let={form} for={@vm.changeset} phx-change="change" phx-submit="submit">
          <.number_input
            form={form}
            field={:birth_year}
            label_text=""
          />
        </.form>
      </Area.form>
    </div>
    """
  end
end
