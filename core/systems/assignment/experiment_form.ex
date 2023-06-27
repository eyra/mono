defmodule Systems.Assignment.ExperimentForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.Form.CheckboxHelpers

  alias Core.Enums.Devices

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text

  alias Systems.{
    Assignment
  }

  # Handle selector update

  @impl true
  def update(
        %{active_item_id: active_item_id, selector_id: :language},
        %{assigns: %{entity: entity}} = socket
      ) do
    language =
      case active_item_id do
        nil -> nil
        item when is_atom(item) -> Atom.to_string(item)
        _ -> active_item_id
      end

    {
      :ok,
      socket
      |> save(entity, :auto_save, %{language: language})
    }
  end

  @impl true
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :ok,
      socket
      |> save(entity, :auto_save, %{selector_id => active_item_ids})
    }
  end

  # Handle initial update
  @impl true
  def update(
        %{id: id, entity: entity},
        socket
      ) do
    changeset = Assignment.ExperimentModel.changeset(entity, :create, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        changeset: changeset
      )
      |> update_device_labels()
      |> update_language_labels()
      |> validate_for_publish()
    }
  end

  defp update_device_labels(%{assigns: %{entity: %{devices: devices}}} = socket) do
    device_labels = Devices.labels(devices)
    socket |> assign(device_labels: device_labels)
  end

  defp update_language_labels(%{assigns: %{entity: %{language: language}}} = socket) do
    language_labels = Assignment.OnlineStudyLanguages.labels(language)
    socket |> assign(language_labels: language_labels)
  end

  # Handle Events
  @impl true
  def handle_event("save", %{"experiment_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
    }
  end

  # Saving

  def save(socket, entity, type, attrs) do
    changeset = Assignment.ExperimentModel.changeset(entity, type, attrs)

    socket
    |> save(changeset)
    |> update_device_labels()
    |> update_language_labels()
    |> validate_for_publish()
  end

  # Validate

  def validate_for_publish(%{assigns: %{id: id, entity: entity}} = socket) do
    changeset =
      Assignment.ExperimentModel.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    send(self(), %{id: id, ready?: changeset.valid?})

    socket
    |> assign(changeset: changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.number_input
          form={form}
          field={:duration}
          label_text={dgettext("link-survey", "duration.label")}
        />
        <.spacing value="M" />

        <.number_input
          form={form}
          field={:subject_count}
          label_text={dgettext("link-survey", "config.nrofsubjects.label")}
        />
        <.spacing value="M" />

        <Text.title3><%= dgettext("link-survey", "language.title") %></Text.title3>
        <Text.body><%= dgettext("link-survey", "languages.label") %></Text.body>
        <.spacing value="S" />
        <.live_component
          module={Selector}
          id={:language}
          items={@language_labels}
          type={:radio}
          parent={%{type: __MODULE__, id: @id}}
        />
        <.spacing value="XL" />

        <Text.title3><%= dgettext("link-survey", "devices.title") %></Text.title3>
        <Text.body><%= dgettext("link-survey", "devices.label") %></Text.body>
        <.spacing value="S" />
        <.live_component
            module={Selector}
            id={:devices}
            type={:label}
            items={@device_labels}
            parent={%{type: __MODULE__, id: @id}} />
      </.form>
    </div>
    """
  end
end
