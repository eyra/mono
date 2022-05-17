defmodule Systems.Assignment.EthicalForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.Form.Checkbox

  alias Frameworks.Pixel.Panel.Panel
  alias Frameworks.Pixel.Text.{Title3, Title5, BodyMedium}
  alias Frameworks.Pixel.Form.{Form, TextInput, Checkbox}

  alias Systems.{
    Assignment
  }

  prop(entity, :map, required: true)
  prop(validate?, :boolean, required: true)

  data(ethical_label, :any)
  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle selector update

  def update(
        %{active_item_ids: active_item_ids, selector_id: :ethical_approval},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :ok,
      socket
      |> save(entity, :auto_save, %{ethical_approval: not Enum.empty?(active_item_ids)})
    }
  end

  # Handle initial update
  def update(
        %{id: id, entity: entity, validate?: validate?},
        socket
      ) do
    changeset = Assignment.ExperimentModel.changeset(entity, :create, %{})

    ethical_label = %{
      id: :statement,
      value: dgettext("link-survey", "ethical.label"),
      accent: :tertiary,
      active: entity.ethical_approval
    }

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(entity: entity)
      |> assign(changeset: changeset)
      |> assign(ethical_label: ethical_label)
      |> assign(validate?: validate?)
      |> validate_for_publish()
    }
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

  defp ethical_review_link() do
    link_as_string(
      dgettext("link-survey", "ethical.review.link"),
      "https://vueconomics.eu.qualtrics.com/jfe/form/SV_1SKjMzceWRZIk9D"
    )
  end

  defp link_as_string(label, url) do
    label
    |> Phoenix.HTML.Link.link(
      class: "text-primary underline",
      target: "_blank",
      to: url
    )
    |> Phoenix.HTML.safe_to_string()
  end

  def render(assigns) do
    ~F"""
      <Form id={@id} changeset={@changeset} change_event="save" target={@myself} focus={@focus}>
        <Title3>{dgettext("link-survey", "ethical.title")}</Title3>
        <BodyMedium>{raw(dgettext("link-survey", "ethical.description", link: ethical_review_link()))}</BodyMedium>
        <Spacing value="M" />

        <Panel bg_color="bg-grey1">
          <Title5 color="text-white" >ERB code</Title5>
          <Spacing value="S" />
          <TextInput field={:ethical_code} placeholder={dgettext("eyra-account", "ehtical.code.label")} background={:dark} />
          <Checkbox
            field={:ethical_approval}
            label_text={dgettext("link-survey", "ethical.label")}
            label_color="text-white"
            accent={:tertiary}
            background={:dark}
          />
        </Panel>
      </Form>
    """
  end
end
