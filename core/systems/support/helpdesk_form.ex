defmodule Systems.Support.HelpdeskForm do
  use CoreWeb.LiveForm

  import Frameworks.Pixel.Form
  alias Systems.Support
  alias Core.Enums
  alias Core.Accounts
  alias Frameworks.Pixel.Selector

  # Handle Selector Update
  @impl true
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

  # Initial update
  @impl true
  def update(%{id: id, user: user}, socket) do
    changeset = Support.Public.new_ticket_changeset()
    type = changeset.changes.type
    type_labels = Enums.TicketTypes.labels(type)

    {
      :ok,
      socket
      |> assign(:id, id)
      |> assign(:user, user)
      |> assign(:changeset, Support.Public.new_ticket_changeset())
      |> assign(:type_labels, type_labels)
      |> assign(:type, type)
    }
  end

  @impl true
  def handle_event(
        "create_ticket",
        %{"ticket_model" => data},
        %{assigns: %{user: user, type: type}} = socket
      ) do
    data = data |> Map.put("type", type)

    case Support.Public.create_ticket(user, data) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("eyra-support", "ticket_created.info.flash"))
         |> push_redirect(to: Accounts.start_page_path(user))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("store_state", %{"ticket_model" => ticket}, socket) do
    {:noreply, assign(socket, :changeset, Support.Public.new_ticket_changeset(ticket))}
  end

  # data(data, :any, default: {})
  # data(type_labels, :map)
  # data(type, :atom)
  # data(changeset, :any)

  attr(:user, :any, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Area.form>
        <.form
          :let={form}
          id={@id}
          for={@changeset}
          phx-submit="create_ticket"
          phx-change="store_state"
          phx-target={@myself}
        >
          <Text.title3><%= dgettext("eyra-support", "ticket.type") %></Text.title3>
          <.live_component module={Selector} id={:type} items={@type_labels} type={:radio} parent={%{type: __MODULE__, id: @id}} />
          <.spacing value="L" />

          <.text_input form={form} field={:title} label_text={dgettext("eyra-support", "ticket.title.label")} />
          <.spacing value="S" />
          <.text_area form={form} field={:description} label_text={dgettext("eyra-support", "ticket.description.label")} />

          <Button.submit label={dgettext("eyra-support", "create_ticket.button")} />
        </.form>
      </Area.form>
      </Area.content>
    </div>
    """
  end
end
