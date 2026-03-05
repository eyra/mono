defmodule Systems.Project.ItemConfigForm do
  @moduledoc false
  use CoreWeb.LiveForm

  alias Systems.Project

  # Handle initial update
  @impl true
  def update(%{id: id, entity: item, sub_form: sub_form}, socket) do
    changeset = Project.ItemModel.changeset(item, %{})

    {
      :ok,
      assign(socket, id: id, entity: item, sub_form: sub_form, changeset: changeset)
    }
  end

  # Handle Events
  @impl true
  def handle_event("save", %{"item_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      save(socket, entity, attrs)
    }
  end

  # Saving

  def save(socket, entity, attrs) do
    changeset = Project.Model.changeset(entity, attrs)

    save(socket, changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-project", "config.title")  %></Text.title2>
        <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
          <.text_input form={form} field={:name} label_text={dgettext("eyra-project", "form.name.label")} />
        </.form>

        <.live_component {@sub_form} />

      </Area.content>
    </div>
    """
  end
end
