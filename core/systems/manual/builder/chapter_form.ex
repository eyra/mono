defmodule Systems.Manual.Builder.ChapterForm do
  use CoreWeb.LiveForm

  alias Systems.Manual

  @impl true
  def update(%{chapter: chapter}, socket) do
    {
      :ok,
      socket
      |> assign(entity: chapter)
      |> update_changeset()
      |> compose_child(:userflow_step_form)
    }
  end

  @impl true
  def compose(:userflow_step_form, %{entity: %{userflow_step: userflow_step}}) do
    %{
      module: Systems.Userflow.StepForm,
      params: %{
        step: userflow_step,
        group_label: dgettext("eyra-manual", "chapter.group.label")
      }
    }
  end

  @impl true
  def compose(:userflow_step_form, _) do
    nil
  end

  def update_changeset(%{assigns: %{entity: entity}} = socket) do
    changeset =
      if entity do
        Manual.ChapterModel.changeset(entity, %{})
      else
        nil
      end

    socket |> assign(changeset: changeset)
  end

  @impl true
  def handle_event("save", %{"chapter_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    changeset = Manual.ChapterModel.changeset(entity, attrs)

    {
      :noreply,
      socket
      |> save(changeset)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @entity do %>
        <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
          <.text_input form={form} field={:title} label_text={dgettext("eyra-manual", "chapter.title.label")} />
        </.form>
        <.child name={:userflow_step_form} fabric={@fabric} />
      <% end %>
    </div>
    """
  end
end
