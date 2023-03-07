defmodule Systems.Assignment.ExperimentForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.Form.CheckboxHelpers

  alias Core.Enums.Devices
  alias Link.Enums.OnlineStudyLanguages

  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Text.{Title3, Body}
  alias Frameworks.Pixel.Form.{Form, NumberInput}

  alias Systems.{
    Assignment
  }

  prop(entity, :map)
  prop(validate?, :boolean)

  data(device_labels, :list)
  data(language_labels, :list)
  data(ethical_label, :any)
  data(changeset, :any)

  # Handle selector update

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

  # Handle update from parent after attempt to publish
  def update(%{props: %{validate?: new}}, %{assigns: %{validate?: current}} = socket)
      when new != current do
    {
      :ok,
      socket
      |> assign(validate?: new)
      |> validate_for_publish()
    }
  end

  # Handle initial update
  def update(
        %{id: id, entity: entity, validate?: validate?},
        socket
      ) do
    changeset = Assignment.ExperimentModel.changeset(entity, :create, %{})

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(entity: entity)
      |> assign(changeset: changeset)
      |> assign(validate?: validate?)
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
    language_labels = OnlineStudyLanguages.labels(language)
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

  def validate_for_publish(%{assigns: %{id: id, entity: entity, validate?: true}} = socket) do
    changeset =
      Assignment.ExperimentModel.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    send(self(), %{id: id, ready?: changeset.valid?})

    socket
    |> assign(changeset: changeset)
  end

  def validate_for_publish(socket), do: socket

  def render(assigns) do
    ~F"""
    <Form id={@id} changeset={@changeset} change_event="save" target={@myself}>
      <NumberInput field={:duration} label_text={dgettext("link-survey", "duration.label")} />
      <Spacing value="M" />

      <NumberInput
        field={:subject_count}
        label_text={dgettext("link-survey", "config.nrofsubjects.label")}
      />
      <Spacing value="M" />

      <Title3>{dgettext("link-survey", "language.title")}</Title3>
      <Body>{dgettext("link-survey", "languages.label")}</Body>
      <Spacing value="S" />
      <Selector
        id={:language}
        items={@language_labels}
        type={:radio}
        parent={%{type: __MODULE__, id: @id}}
      />
      <Spacing value="XL" />

      <Title3>{dgettext("link-survey", "devices.title")}</Title3>
      <Body>{dgettext("link-survey", "devices.label")}</Body>
      <Spacing value="S" />
      <Selector id={:devices} items={@device_labels} parent={%{type: __MODULE__, id: @id}} />
    </Form>
    """
  end
end
