defmodule Systems.Support.HelpdeskForm do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Form

  alias Systems.Support
  alias Core.Enums
  alias Frameworks.Pixel.Selector

  @impl true
  def update(%{id: id, user: user}, socket) do
    {
      :ok,
      socket
      |> assign(:id, id)
      |> assign(:user, user)
      |> initialize()
      |> compose_child(:type_selector)
    }
  end

  defp initialize(socket) do
    if Map.has_key?(socket.assigns, :type) do
      socket
    else
      force_initialize(socket)
    end
  end

  defp force_initialize(socket) do
    type = :question
    # Create a changeset with empty values to ensure form fields are reset
    empty_attrs = %{title: "", description: "", type: type}

    socket
    |> assign(
      changeset: Support.Public.prepare_ticket(empty_attrs),
      type: type,
      type_labels: Enums.TicketTypes.labels(type)
    )
  end

  @impl true
  def compose(:type_selector, %{type_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :radio
      }
    }
  end

  @impl true
  def handle_event("change", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "submit",
        %{"ticket_model" => data},
        %{assigns: %{user: user, type: type}} = socket
      ) do
    data = data |> Map.put("type", type)

    socket =
      case Support.Public.create_ticket(user, data) do
        {:ok, _} ->
          socket |> send_event(:parent, "ticket_created")

        {:error, changeset} ->
          assign(socket, :changeset, changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("active_item_id", %{active_item_id: active_item_id}, socket) do
    type = active_item_id
    type_labels = Enums.TicketTypes.labels(type)

    {
      :noreply,
      socket
      |> assign(:type_labels, type_labels)
      |> assign(:type, type)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
        <Text.title3><%= dgettext("eyra-support", "ticket.type") %></Text.title3>
        <.child name={:type_selector} fabric={@fabric} />
        <.spacing value="L" />
        <.form
          id={@id}
          for={@changeset}
          :let={form}

          phx-submit="submit"
          phx-change="change"
          phx-target={@myself}
        >
          <.text_input form={form} field={:title} label_text={dgettext("eyra-support", "ticket.title.label")} />
          <.spacing value="S" />
          <.text_area form={form} field={:description} label_text={dgettext("eyra-support", "ticket.description.label")} />
          <.spacing value="S" />
          <Button.submit label={dgettext("eyra-support", "create_ticket.button")} />
        </.form>
    </div>
    """
  end
end
