defmodule CoreWeb.DataDonation.Form do
  use CoreWeb.LiveForm

  import CoreWeb.Gettext

  alias Core.DataDonation.{Tools, Tool}
  alias Core.Content.Nodes

  alias CoreWeb.Router.Helpers, as: Routes

  alias EyraUI.Spacing
  alias EyraUI.Text.{ Title3 }
  alias EyraUI.Form.{Form, TextArea, NumberInput}
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Button.SecondaryLiveViewButton

  prop(entity_id, :any, required: true)

  data(entity, :any)
  data(changeset, :any)
  data(focus, :any, default: "")
  data(myself, :any)

  def update(%{id: id, entity_id: entity_id}, socket) do
    entity = Tools.get!(entity_id)
    changeset = Tool.changeset(entity, :mount, %{})

    socket =
      socket
      |> assign(entity_id: entity_id)
      |> assign(entity: entity)
      |> assign(changeset: changeset)
      |> assign(id: id)

    {:ok, socket}
  end

  # Handle Events
  def handle_event("save", %{ "tool" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> schedule_save(entity, :auto_save, attrs)
    }
  end

  def handle_event("delete", _params, %{assigns: %{entity_id: entity_id}} = socket) do
    Tools.get!(entity_id)
    |> Tools.delete()

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Dashboard))}
  end

  # Saving
  def schedule_save(socket, %Tool{} = entity, type, attrs) do
    node = Nodes.get!(entity.content_node_id)
    changeset = Tool.changeset(entity, type, attrs)
    node_changeset = Tool.node_changeset(node, entity, attrs)

    socket
    |> schedule_save(changeset, node_changeset)
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <Form id={{@id}} changeset={{@changeset}} change_event="save" target={{@myself}} focus={{@focus}}>

          <Title3>{{dgettext("eyra-data-donation", "script.title")}}</Title3>
          <TextArea field={{:script}} label_text={{dgettext("eyra-data-donation", "script.label")}} target={{@myself}} />
          <Spacing value="L" />

          <Title3>{{dgettext("eyra-data-donation", "reward.title")}}</Title3>
          <NumberInput field={{:reward_value}} label_text={{dgettext("eyra-data-donation", "reward.label")}} target={{@myself}} />
          <Spacing value="L" />

          <Title3>{{dgettext("eyra-data-donation", "nrofsubjects.title")}}</Title3>
          <NumberInput field={{:subject_count}} label_text={{dgettext("eyra-data-donation", "config.nrofsubjects.label")}} target={{@myself}} />
        </Form>
        <Spacing value="M" />
        <SecondaryLiveViewButton label={{ dgettext("eyra-data-donation", "delete.button") }} event="delete" target={{@myself}} />
      </ContentArea>
    """
  end
end
