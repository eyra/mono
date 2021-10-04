defmodule CoreWeb.Helpdesk.Form do
  use CoreWeb.LiveForm

  alias EyraUI.Spacing
  alias EyraUI.Form.{Form, TextArea, TextInput}
  alias EyraUI.Text.{Title3}
  alias EyraUI.Button.SubmitButton
  alias Core.Helpdesk
  alias Core.Enums
  alias EyraUI.Selector.Selector

  prop(user, :any, required: true)

  data(focus, :any, default: nil)
  data(data, :any, default: {})
  data(type_labels, :map)
  data(type, :atom)
  data(changeset, :any)

  # Handle Selector Update
  def update(%{active_item_id: active_item_id}, socket) do
    type = active_item_id
    type_labels = Enums.TicketTypes.labels(type)

    {
      :ok,
      socket
      |> assign(:type_labels, type_labels)
      |> assign(:type, type)
    }
  end

  # Handle update from parent, prevents overwrite of current state
  def update(_params, %{assigns: %{changeset: _changeset}} = socket) do
    {:ok, socket}
  end

  # Initial update
  def update(%{id: id, user: user}, socket) do
    changeset = Helpdesk.new_ticket_changeset()
    type = changeset.changes.type
    type_labels = Enums.TicketTypes.labels(type)

    {
      :ok,
      socket
      |> assign(:id, id)
      |> assign(:user, user)
      |> assign(:changeset, Helpdesk.new_ticket_changeset())
      |> assign(:type_labels, type_labels)
      |> assign(:type, type)
    }
  end

  @impl true
  def handle_event(
        "create_ticket",
        %{"ticket" => data},
        %{assigns: %{user: user, type: type}} = socket
      ) do
    data = data |> Map.put("type", type)

    case Helpdesk.create_ticket(user, data) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("eyra-support", "ticket_created.info.flash"))
         |> push_redirect(to: Routes.live_path(socket, CoreWeb.Marketplace))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("store_state", %{"ticket" => ticket}, socket) do
    {:noreply, assign(socket, :changeset, Helpdesk.new_ticket_changeset(ticket))}
  end

  def render(assigns) do
    ~H"""
    <ContentArea>
      <FormArea>
        <Form id={{@id}} changeset={{@changeset}} submit="create_ticket" change_event="store_state" target={{@myself}} focus={{@focus}}>
          <Title3>{{dgettext("eyra-support", "ticket.type")}}</Title3>
          <Selector id={{:type}} items={{ @type_labels }} type={{:radio}} parent={{ %{type: __MODULE__, id: @id} }} />
          <Spacing value="L" />

          <TextInput field={{:title}} label_text={{dgettext("eyra-support", "ticket.title.label")}} />
          <Spacing value="S" />
          <TextArea field={{:description}} label_text={{dgettext("eyra-support", "ticket.description.label")}} />

          <SubmitButton label={{ dgettext("eyra-support", "create_ticket.button") }} />
        </Form>
      </FormArea>
    </ContentArea>
    """
  end
end
