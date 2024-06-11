defmodule Systems.Assignment.GeneralForm do
  use CoreWeb.LiveForm

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Text

  alias Systems.Assignment

  @impl true
  def update(
        %{id: id, entity: entity, viewport: viewport, breakpoint: breakpoint},
        socket
      ) do
    changeset = Assignment.InfoModel.changeset(entity, :create, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        changeset: changeset,
        viewport: viewport,
        breakpoint: breakpoint
      )
      |> update_language_items()
    }
  end

  def update_language_items(%{assigns: %{entity: %{language: language}}} = socket) do
    language =
      if language do
        language
      else
        Assignment.Languages.default()
      end

    items = Assignment.Languages.labels(language)

    assign(socket, language_items: items)
  end

  # Handle Events

  @impl true
  def handle_event(
        "update",
        %{source: %{name: :language_selector}, status: language},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, %{language: language})
    }
  end

  @impl true
  def handle_event("save", %{"info_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
    }
  end

  # Saving

  def save(socket, entity, type, attrs) do
    changeset = Assignment.InfoModel.changeset(entity, type, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
        <.form id={"#{@id}_general"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
          <Text.title3><%= dgettext("eyra-assignment", "settings.general.title") %></Text.title3>
          <.number_input form={form} field={:subject_count} label_text={dgettext("eyra-assignment", "settings.subject_count.label")} />
          <.radio_group form={form} field={:language} label_text={dgettext("eyra-assignment", "settings.language.label")} items={@language_items}/>
        </.form>
    </div>
    """
  end
end
