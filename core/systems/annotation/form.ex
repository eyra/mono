defmodule Systems.Annotation.Form do
  @moduledoc false
  use CoreWeb.LiveForm

  alias Systems.Annotation

  def update(%{id: id, annotation: annotation, user: user}, socket) do
    changeset = Annotation.Model.changeset(annotation, %{})

    {
      :ok,
      assign(socket, id: id, entity: annotation, changeset: changeset, user: user)
    }
  end

  def handle_event("save", %{"model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    changeset = Annotation.Model.changeset(entity, attrs)

    {
      :noreply,
      save(socket, changeset)
    }
  end

  def render(assigns) do
    ~H"""
    <div>
        <.form id={"annotation_form_#{@id}"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
            <.text_area form={form} field={:statement} height="h-32" reserve_error_space={false} />
        </.form>
    </div>
    """
  end
end
