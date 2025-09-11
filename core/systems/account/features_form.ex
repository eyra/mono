defmodule Systems.Account.FeaturesForm do
  use CoreWeb.LiveForm

  alias Core.Enums.Genders
  alias Frameworks.Pixel.{Selector, Text}
  alias Systems.Account

  @impl true
  def update(%{user: user}, socket) do
    entity = Account.Public.get_features(user)

    gender_labels = Genders.labels(entity.gender)
    changeset = Account.FeaturesModel.changeset(entity, :auto_save, %{})

    {
      :ok,
      socket
      |> assign(user: user)
      |> assign(entity: entity)
      |> assign(changeset: changeset)
      |> assign(gender_labels: gender_labels)
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{entity: entity}} = socket) do
    update_ui(socket, entity)
  end

  defp update_ui(socket, entity) do
    gender_labels = Genders.labels(entity.gender)

    socket
    |> assign(gender_labels: gender_labels)
    |> compose_child(:gender)
  end

  @impl true
  def compose(:gender, %{gender_labels: gender_labels}) do
    %{
      module: Selector,
      params: %{
        items: gender_labels,
        type: :radio
      }
    }
  end

  def save_features(socket, %Account.FeaturesModel{} = entity, type, attrs) do
    changeset = Account.FeaturesModel.changeset(entity, type, attrs)

    socket
    |> assign(changeset: changeset)
    |> save(changeset)
    |> update_ui()
  end

  @impl true
  def handle_event(
        "active_item_id",
        %{active_item_id: active_item_id, source: %{name: field}},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save_features(entity, :auto_save, %{to_string(field) => active_item_id})
    }
  end

  @impl true
  def handle_event(event, %{"features_model" => attrs}, %{assigns: %{entity: entity}} = socket)
      when event in ["change", "submit"] do
    {:noreply, save_features(socket, entity, :auto_save, attrs)}
  end

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
        <Area.form>
          <Text.title2><%= dgettext("eyra-account", "profile.tab.features.title") %></Text.title2>
          <Text.body_medium><%= dgettext("eyra-account", "features.description") %></Text.body_medium>

          <.spacing value="XL" />

          <Text.title3><%= dgettext("eyra-account", "features.gender.title") %></Text.title3>
          <.child name={:gender} fabric={@fabric} />

          <.spacing value="XL" />

          <Text.title3><%= dgettext("eyra-account", "features.birthyear.title") %></Text.title3>
          <.spacing value="S" />
          <.form :let={form} for={@changeset} phx-change="change" phx-submit="submit" phx-target={@myself}>
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
