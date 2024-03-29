defmodule CoreWeb.User.Forms.Features do
  use CoreWeb.LiveForm

  alias Core.Enums.{Genders, DominantHands, NativeLanguages}
  alias Core.Accounts
  alias Core.Accounts.Features

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text

  # Handle Selector Update
  @impl true
  def update(
        %{active_item_id: active_item_id, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :ok,
      socket
      |> save(entity, :auto_save, %{selector_id => active_item_id})
    }
  end

  @impl true
  def update(%{id: id, user: user}, socket) do
    entity = Accounts.get_features(user)

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
  end

  # Saving
  def save(socket, %Core.Accounts.Features{} = entity, type, attrs) do
    changeset = Features.changeset(entity, type, attrs)

    socket
    |> save(changeset)
    |> update_ui()
  end

  # data(user, :any)
  # data(entity, :any, default: nil)
  # data(gender_labels, :any, default: [])
  # data(dominanthand_labels, :any, default: [])
  # data(nativelanguage_labels, :any, default: [])
  # data(changeset, :any, default: nil)

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
        <.live_component
          module={Selector}
          id={:gender}
          items={@gender_labels}
          type={:radio}
          parent={%{type: __MODULE__, id: @id}}
        />
        <.spacing value="XL" />

        <Text.title3><%= dgettext("eyra-account", "features.nativelanguage.title") %></Text.title3>
        <.live_component
          module={Selector}
          id={:native_language}
          items={@nativelanguage_labels}
          type={:radio}
          parent={%{type: __MODULE__, id: @id}}
        />
        <.spacing value="XL" />

        <Text.title3><%= dgettext("eyra-account", "features.dominanthand.title") %></Text.title3>
        <.live_component
          module={Selector}
          id={:dominant_hand}
          items={@dominanthand_labels}
          type={:radio}
          parent={%{type: __MODULE__, id: @id}}
        />
      </Area.form>
      </Area.content>
    </div>
    """
  end
end
