defmodule Systems.Account.FeaturesForm do
  use CoreWeb.LiveForm

  alias Core.Enums.{Genders, DominantHands, NativeLanguages}
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text

  alias Systems.Account

  @impl true
  def update(%{id: id, user: user}, socket) do
    entity = Account.Public.get_features(user)

    gender_labels = Genders.labels(entity.gender)
    dominanthand_labels = DominantHands.labels(entity.dominant_hand)
    nativelanguage_labels = NativeLanguages.labels(entity.native_language)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
      |> assign(gender_labels: gender_labels)
      |> assign(dominanthand_labels: dominanthand_labels)
      |> assign(nativelanguage_labels: nativelanguage_labels)
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{entity: entity}} = socket) do
    update_ui(socket, entity)
  end

  defp update_ui(socket, entity) do
    gender_labels = Genders.labels(entity.gender)
    dominanthand_labels = DominantHands.labels(entity.dominant_hand)
    nativelanguage_labels = NativeLanguages.labels(entity.native_language)

    socket
    |> assign(gender_labels: gender_labels)
    |> assign(dominanthand_labels: dominanthand_labels)
    |> assign(nativelanguage_labels: nativelanguage_labels)
    |> compose_child(:gender)
    |> compose_child(:dominant_hand)
    |> compose_child(:native_language)
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

  @impl true
  def compose(:dominant_hand, %{dominanthand_labels: dominanthand_labels}) do
    %{
      module: Selector,
      params: %{
        items: dominanthand_labels,
        type: :radio
      }
    }
  end

  @impl true
  def compose(:native_language, %{nativelanguage_labels: nativelanguage_labels}) do
    %{
      module: Selector,
      params: %{
        items: nativelanguage_labels,
        type: :radio
      }
    }
  end

  # Saving
  def save(socket, %Account.FeaturesModel{} = entity, type, attrs) do
    changeset = Account.FeaturesModel.changeset(entity, type, attrs)

    socket
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
      |> save(entity, :auto_save, %{field => active_item_id})
    }
  end

  attr(:user, :map, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.form>
        <Text.title2><%= dgettext("eyra-ui", "tabbar.item.features") %></Text.title2>
        <Text.body_medium><%= dgettext("eyra-account", "features.description") %></Text.body_medium>
        <.spacing value="XL" />

        <Text.title3><%= dgettext("eyra-account", "features.gender.title") %></Text.title3>
        <.child name={:gender} fabric={@fabric} />
        <.spacing value="XL" />

        <Text.title3><%= dgettext("eyra-account", "features.nativelanguage.title") %></Text.title3>
        <.child name={:native_language} fabric={@fabric} />
        <.spacing value="XL" />

        <Text.title3><%= dgettext("eyra-account", "features.dominanthand.title") %></Text.title3>
        <.child name={:dominant_hand} fabric={@fabric} />
      </Area.form>
      </Area.content>
    </div>
    """
  end
end
