defmodule Systems.Lab.ToolForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Text.{Title3, BodyLarge}

  alias Systems.{
    Lab
  }

  prop(entity_id, :number, required: true)
  prop(validate?, :boolean, required: true)

  data(entity, :map)
  data(add_day_button, :map)
  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle initial update
  def update(
        %{id: id, entity_id: entity_id, validate?: validate?},
        socket
      ) do
    entity = Lab.Context.get(entity_id)
    changeset = Lab.ToolModel.changeset(entity, :create, %{})

    add_day_button = %{
      action: %{type: :send, event: "add_day"},
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

  def handle_event("add_day", _params, socket) do
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
