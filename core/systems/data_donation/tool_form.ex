defmodule Systems.DataDonation.ToolForm do
  use CoreWeb.LiveForm

  alias Core.Accounts

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Selector

  alias Systems.{
    DataDonation
  }

  require Systems.DataDonation.Platforms

  @impl true
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {:ok, socket |> save(entity, %{selector_id => active_item_ids})}
  end

  @impl true
  def update(
        %{id: id, entity_id: entity_id},
        socket
      ) do
    entity = DataDonation.Public.get_tool!(entity_id)
    donations = DataDonation.Public.list_donations(entity)
    changeset = DataDonation.ToolModel.changeset(entity, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
        entity: entity,
        changeset: changeset,
        donations: donations
      )
      |> update_platform_labels()
    }
  end

  defp update_platform_labels(%{assigns: %{entity: %{platforms: platforms}}} = socket) do
    platform_labels = DataDonation.Platforms.labels(platforms)
    socket |> assign(platform_labels: platform_labels)
  end

  # Handle Events

  @impl true
  def handle_event("save", %{"tool_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{entity_id: entity_id, current_user: user}} = socket
      ) do
    DataDonation.Public.get_tool!(entity_id)
    |> DataDonation.Public.delete()

    {:noreply, push_redirect(socket, to: Accounts.start_page_path(user))}
  end

  # Saving
  def save(socket, %DataDonation.ToolModel{} = entity, attrs) do
    changeset = DataDonation.ToolModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  attr(:entity_id, :any, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.number_input form={form} field={:subject_count} label_text={dgettext("eyra-data-donation", "config.nrofsubjects.label")} />
      </.form>
      <.spacing value="M" />

      <Text.title3><%= dgettext("eyra-data-donation", "platforms.title") %></Text.title3>
      <.live_component
        module={Selector}
        id={:platforms}
        items={@platform_labels}
        type={:label}
        parent={%{type: __MODULE__, id: @id}}
      />
    </div>
    """
  end
end
