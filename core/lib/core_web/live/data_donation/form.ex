defmodule CoreWeb.DataDonation.Form do
  use CoreWeb.LiveForm

  import CoreWeb.Gettext

  alias Core.DataDonation.{Tools, Tool}
  alias Core.Content.Nodes

  alias CoreWeb.Router.Helpers, as: Routes

  alias EyraUI.Spacing
  alias EyraUI.Text.{Title2, Title3}
  alias EyraUI.Form.{Form, TextArea, NumberInput}
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Button.{SecondaryLiveViewButton, PrimaryButton}
  alias EyraUI.Panel.Panel
  alias EyraUI.Timestamp

  prop(entity_id, :any, required: true)

  data(entity, :any)
  data(donations, :any)
  data(changeset, :any)
  data(focus, :any, default: "")

  def update(%{id: id, entity_id: entity_id}, socket) do
    entity = Tools.get!(entity_id)
    donations = Tools.list_donations(entity)

    {
      :ok,
      socket
      |> assign(entity_id: entity_id)
      |> assign(entity: entity)
      |> assign(donations: donations)
      |> assign(id: id)
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{entity: entity}} = socket) do
    update_ui(socket, entity)
  end

  defp update_ui(socket, entity) do
    changeset = Tool.changeset(entity, :mount, %{})

    socket
    |> assign(changeset: changeset)
  end

  # Handle Events
  def handle_event("save", %{"tool" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> schedule_save(entity, :auto_save, attrs)
      |> update_ui()
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
        <div :if={{ Enum.count(@donations) > 0 }}>
          <Title2>{{dgettext("eyra-data-donation", "donations.title")}}</Title2>
          <Panel bg_color="bg-grey6">
            <div :for={{ donation <- @donations  }} class="mb-2 w-full">
              <div class="flex flex-row w-full">
                <div class="flex-wrap text-grey1 text-bodymedium font-body mr-6">
                  Participant {{donation.user_id}}
                </div>
                <div class="flex-grow text-grey2 text-bodymedium font-body">
                  {{dgettext("eyra-data-donation", "received.label")}} {{Timestamp.humanize(donation.inserted_at)}}
                </div>
                <div class="flex-wrap">
          <a href={{Routes.data_donation_path(@socket, :download_single, @entity_id, donation.id)}} class="text-primary text-bodymedium font-body hover:text-grey1 underline focus:outline-none" >
                  {{dgettext("eyra-data-donation", "download.button.label")}}
                  </a>
                </div>
              </div>
            </div>
          </Panel>
          <Spacing value="S" />
          <PrimaryButton to={{Routes.data_donation_path(@socket, :download_all, @entity_id )}} label={{dgettext("eyra-data-donation", "download.all.button.label")}} />
          <Spacing value="XL" />
        </div>
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
