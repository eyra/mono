defmodule Systems.Lab.ToolForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Text.{Title3, BodyLarge}

  alias Systems.{
    Lab
  }

  prop(entity_id, :number, required: true)
  prop(validate?, :boolean, required: true)
  prop(callback_url, :string)

  data(entity, :map)
  data(add_day_button, :map)
  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle initial update
  def update(
        %{id: id, entity_id: entity_id, validate?: validate?},
        %{assigns: %{myself: myself}} = socket
      ) do
    entity = Lab.Context.get(entity_id)
    changeset = Lab.ToolModel.changeset(entity, :create, %{})

    add_day_button = %{
      action: %{type: :send, event: "add_day", target: myself},
      face: %{type: :primary, label: dgettext("link-lab", "add.day.button")}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
        entity: entity,
        changeset: changeset,
        validate?: validate?,
        add_day_button: add_day_button
      )
    }
  end

  def update(%{day_view: :submit, day_model: day_model}, %{assigns: %{entity: entity}} = socket) do
    Lab.Context.process_day_model(entity, day_model)
    {:ok, socket}
  end

  def update(%{day_view: :hide}, socket) do
    send(self(), {:hide_popup})
    {:ok, socket}
  end

  def handle_event("add_day", _params, %{assigns: %{id: id, entity: entity}} = socket) do
    props = %{
      id: :day_popup,
      target: %{type: __MODULE__, id: id},
      day_model: Lab.Context.new_day_model(entity)
    }

    send(self(), {:show_popup, %{view: Systems.Lab.DayView, props: props}})
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
      <div>
        <Title3>{dgettext("link-lab", "form.title")}</Title3>
        <BodyLarge>{dgettext("link-lab", "form.description", timeslots: 14, participants: 112)}</BodyLarge>
        <Spacing value="M" />
        <Wrap>
          <DynamicButton vm={@add_day_button} />
        </Wrap>
      </div>
    """
  end
end

defmodule Systems.Lab.ToolForm.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Lab.ToolForm,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Lab tool form",
    height: "812px",
    direction: "vertical",
    container: {:div, class: ""}

  def render(assigns) do
    ~F"""
    <ToolForm
      id={:reject_view_example}
      entity_id={1}
      validate?={false}
    />
    """
  end

  # def handle_info({:share_view, :close}, socket) do
  #   IO.puts("Close")
  #   {:noreply, socket}
  # end

  # def handle_info({:share_view, %{add: user}}, socket) do
  #   IO.puts("Add: #{user.fullname}")
  #   {:noreply, socket}
  # end

  # def handle_info({:share_view, %{remove: user}}, socket) do
  #   IO.puts("Remove: #{user.fullname}")
  #   {:noreply, socket}
  # end
end
