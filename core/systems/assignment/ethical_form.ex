defmodule Systems.Assignment.EthicalForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.Form.CheckboxHelpers

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Text

  alias Systems.{
    Assignment
  }

  # Handle selector update

  @impl true
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
  @impl true
  def update(
        %{id: id, entity: entity},
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
      |> assign(
        id: id,
        entity: entity,
        changeset: changeset,
        ethical_label: ethical_label
      )
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

  def validate_for_publish(%{assigns: %{id: id, entity: entity}} = socket) do
    changeset =
      Assignment.ExperimentModel.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    send(self(), %{id: id, ready?: changeset.valid?})

    socket
    |> assign(changeset: changeset)
  end

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

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <Text.title3><%= dgettext("link-survey", "ethical.title") %></Text.title3>
        <Text.body_medium><%= raw(dgettext("link-survey", "ethical.description", link: ethical_review_link())) %></Text.body_medium>
        <.spacing value="M" />

        <Panel.flat bg_color="bg-grey1">
          <Text.title5 align="text-left" color="text-white">ERB code</Text.title5>
          <.spacing value="S" />
          <.text_input
            form={form}
            field={:ethical_code}
            placeholder={dgettext("eyra-account", "ehtical.code.label")}
            background={:dark}
          />
          <.checkbox
            form={form}
            field={:ethical_approval}
            label_text={dgettext("link-survey", "ethical.label")}
            label_color="text-white"
            accent={:tertiary}
            background={:dark}
          />
        </Panel.flat>
      </.form>
    </div>
    """
  end
end
